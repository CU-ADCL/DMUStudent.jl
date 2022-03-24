module HW6

using DMUStudent
using ..Obfuscatee
using POMDPs
using StaticArrays
using POMDPModelTools
using Random
using Compose
using Nettle
using ProgressMeter
using POMDPSimulators
using JSON

export
    LaserTagPOMDP,
    LTState,
    lasertag

struct LTState
    robot::SVector{2, Int}
    target::SVector{2, Int}
    wanderer::SVector{2, Int}
end

Base.convert(::Type{SVector{4, Int}}, s::LTState) = SA[s.robot..., s.target...]
Base.convert(::Type{AbstractVector{Int}}, s::LTState) = convert(SVector{4, Int}, s)
Base.convert(::Type{AbstractVector}, s::LTState) = convert(SVector{4, Int}, s)
Base.convert(::Type{AbstractArray}, s::LTState) = convert(SVector{4, Int}, s)


struct LaserTagPOMDP <: POMDP{LTState, Symbol, SVector{4,Int}}
    size::SVector{2, Int}
    obstacles::Set{SVector{2, Int}}
    blocked::BitArray{2}
    robot_init::SVector{2, Int}
    obsindices::Array{Union{Nothing,Int}, 4}
end

function lasertag_observations(size)
    os = SVector{4,Int}[]
    for left in 0:size[1]-1
        for right in 0:size[1]-left-1
            for up in 0:size[2]-1
                for down in 0:size[2]-up-1
                    push!(os, SVector(left, right, up, down))
                end
            end
        end
    end
    return os
end

function LaserTagPOMDP(;size=(10, 7), n_obstacles=9, rng::AbstractRNG=Random.MersenneTwister(20))
    obstacles = Set{SVector{2, Int}}()
    blocked = falses(size...)
    while length(obstacles) < n_obstacles
        obs = SVector(rand(rng, 1:size[1]), rand(rng, 1:size[2]))
        push!(obstacles, obs)
        blocked[obs...] = true
    end
    robot_init = SVector(rand(rng, 1:size[1]), rand(rng, 1:size[2]))

    obsindices = Array{Union{Nothing,Int}}(nothing, size[1], size[1], size[2], size[2])
    for (ind, o) in enumerate(lasertag_observations(size))
        obsindices[(o.+1)...] = ind
    end

    LaserTagPOMDP(size, obstacles, blocked, robot_init, obsindices)
end

Random.rand(rng::AbstractRNG, ::Random.SamplerType{LaserTagPOMDP}) = LaserTagPOMDP(rng=rng)

POMDPs.actions(m::LaserTagPOMDP) = (:left, :right, :up, :down, :measure)
POMDPs.states(m::LaserTagPOMDP) = vec(collect(LTState(SVector(c[1],c[2]), SVector(c[3], c[4]), SVector(c[5], c[6])) for c in Iterators.product(1:m.size[1], 1:m.size[2], 1:m.size[1], 1:m.size[2], 1:m.size[1], 1:m.size[2])))
POMDPs.observations(m::LaserTagPOMDP) = lasertag_observations(m.size)
POMDPs.discount(m::LaserTagPOMDP) = 0.95

POMDPs.stateindex(m::LaserTagPOMDP, s) = LinearIndices((1:m.size[1], 1:m.size[2], 1:m.size[1], 1:m.size[2], 1:m.size[1], 1:m.size[2]))[s.robot..., s.target..., s.wanderer...]

POMDPs.actionindex(m::LaserTagPOMDP, a) = actionind[a]
POMDPs.obsindex(m::LaserTagPOMDP, o) = m.obsindices[(o.+1)...]::Int

const actiondir = Dict(:left=>SVector(-1,0), :right=>SVector(1,0), :up=>SVector(0, 1), :down=>SVector(0,-1), :measure=>SVector(0,0))
const actionind = Dict(:left=>1, :right=>2, :up=>3, :down=>4, :measure=>5)

function bounce(m::LaserTagPOMDP, pos, change)
    new = clamp.(pos + change, SVector(1,1), m.size)
    if m.blocked[new[1], new[2]]
        return pos
    else
        return new
    end
end

# robot moves deterministically
# target usually moves randomly, but moves away if near
# wanderer moves randomly
function POMDPs.transition(m::LaserTagPOMDP, s, a)
    newrobot = bounce(m, s.robot, actiondir[a])

    targets = [s.target]
    targetprobs = Float64[0.0]
    if sum(abs, newrobot - s.target) > 2 # move randomly
        for change in (SVector(-1,0), SVector(1,0), SVector(0,1), SVector(0,-1))
            newtarget = bounce(m, s.target, change)
            if newtarget == s.target
                targetprobs[1] += 0.25
            else
                push!(targets, newtarget)
                push!(targetprobs, 0.25)
            end
        end
    else # move away 
        away = sign.(s.target - s.robot)
        if sum(abs, away) == 2 # diagonal
            away = away - SVector(0, away[2]) # preference to move in x direction
        end
        newtarget = bounce(m, s.target, away)
        targets[1] = newtarget
        targetprobs[1] = 1.0
    end

    wanderers = [s.wanderer]
    wandererprobs = Float64[0.0]
    for change in (SVector(-1,0), SVector(1,0), SVector(0,1), SVector(0,-1))
        newwanderer = bounce(m, s.wanderer, change)
        if newwanderer == s.wanderer
            wandererprobs[1] += 0.25
        else
            push!(wanderers, newwanderer)
            push!(wandererprobs, 0.25)
        end
    end

    states = LTState[]    
    probs = Float64[]
    for (t, tp) in zip(targets, targetprobs)
        for (w, wp) in zip(wanderers, wandererprobs)
            push!(states, LTState(newrobot, t, w))
            push!(probs, tp*wp)
        end
    end

    return SparseCat(states, probs)
end

POMDPs.isterminal(m::LaserTagPOMDP, s) = s.target == s.robot

function POMDPs.observation(m::LaserTagPOMDP, a, sp)
    left = sp.robot[1]-1
    right = m.size[1]-sp.robot[1]
    up = m.size[2]-sp.robot[2]
    down = sp.robot[2]-1
    ranges = SVector(left, right, up, down)
    for obstacle in m.obstacles
        ranges = laserbounce(ranges, sp.robot, obstacle)
    end
    ranges = laserbounce(ranges, sp.robot, sp.target)
    ranges = laserbounce(ranges, sp.robot, sp.wanderer)
    os = SVector(ranges, SVector(0.0, 0.0, 0.0, 0.0))
    if all(ranges.==0.0) || a == :measure
        probs = SVector(1.0, 0.0)
    else
        probs = SVector(0.1, 0.9)
    end
    return SparseCat(os, probs)
end

function laserbounce(ranges, robot, obstacle)
    left, right, up, down = ranges
    diff = obstacle - robot
    if diff[1] == 0
        if diff[2] > 0
            up = min(up, diff[2]-1)
        elseif diff[2] < 0
            down = min(down, -diff[2]-1)
        end
    elseif diff[2] == 0
        if diff[1] > 0
            right = min(right, diff[1]-1)
        elseif diff[1] < 0
            left = min(left, -diff[1]-1)
        end
    end
    return SVector(left, right, up, down)
end

function POMDPs.initialstate(m::LaserTagPOMDP)
    return Uniform(LTState(m.robot_init, SVector(x, y), SVector(x,y)) for x in 1:m.size[1], y in 1:m.size[2])
end

function POMDPModelTools.render(m::LaserTagPOMDP, step)
    nx, ny = m.size
    cells = []
    target_marginal = zeros(nx, ny)
    wanderer_marginal = zeros(nx, ny)
    if haskey(step, :bp) && !ismissing(step[:bp])
        for sp in support(step[:bp])
            p = pdf(step[:bp], sp)
            target_marginal[sp.target...] += p
            wanderer_marginal[sp.wanderer...] += p
        end
    end

    for x in 1:nx, y in 1:ny
        cell = cell_ctx((x,y), m.size)
        if SVector(x, y) in m.obstacles
            compose!(cell, rectangle(), fill("darkgray"))
        else
            w_op = sqrt(wanderer_marginal[x, y])
            w_rect = compose(context(), rectangle(), fillopacity(w_op), fill("lightblue"), stroke("gray"))
            t_op = sqrt(target_marginal[x, y])
            t_rect = compose(context(), rectangle(), fillopacity(t_op), fill("yellow"), stroke("gray"))
            compose!(cell, w_rect, t_rect)
        end
        push!(cells, cell)
    end
    grid = compose(context(), linewidth(0.5mm), cells...)
    outline = compose(context(), linewidth(1mm), rectangle(), fill("white"), stroke("gray"))

    if haskey(step, :sp)
        robot_ctx = cell_ctx(step[:sp].robot, m.size)
        robot = compose(robot_ctx, circle(0.5, 0.5, 0.5), fill("green"))
        target_ctx = cell_ctx(step[:sp].target, m.size)
        target = compose(target_ctx, circle(0.5, 0.5, 0.5), fill("orange"))
        wanderer_ctx = cell_ctx(step[:sp].wanderer, m.size)
        wanderer = compose(wanderer_ctx, circle(0.5, 0.5, 0.5), fill("purple"))
    else
        robot = nothing
        target = nothing
        wanderer = nothing
    end

    if haskey(step, :o) && haskey(step, :sp)
        o = step[:o]
        robot_ctx = cell_ctx(step[:sp].robot, m.size)
        left = compose(context(), line([(0.0, 0.5),(-o[1],0.5)]))
        right = compose(context(), line([(1.0, 0.5),(1.0+o[2],0.5)]))
        up = compose(context(), line([(0.5, 0.0),(0.5, -o[3])]))
        down = compose(context(), line([(0.5, 1.0),(0.5, 1.0+o[4])]))
        lasers = compose(robot_ctx, strokedash([1mm]), stroke("red"), left, right, up, down)
    else
        lasers = nothing
    end

    sz = min(w,h)
    return compose(context((w-sz)/2, (h-sz)/2, sz, sz), robot, target, wanderer, lasers, grid, outline)
end

function POMDPs.reward(m::LaserTagPOMDP, s, a, sp)
    if sp.robot == sp.target
        return 100.0
    elseif a == :measure
        return -2.0
    else
        return -1.0
    end
end

function POMDPs.reward(m, s, a)
    r = 0.0
    td = transition(m, s, a)
    for (sp, w) in weighted_iterator(td)
        r += w*reward(m, s, a, sp)
    end
    return r
end

function cell_ctx(xy, size)
    nx, ny = size
    x, y = xy
    return context((x-1)/nx, (ny-y)/ny, 1/nx, 1/ny)
end

@binclude(".bin/hw6_eval")

end
