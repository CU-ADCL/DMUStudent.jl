module HW6

using POMDPs
using StaticArrays
using POMDPModelTools
using Random
using Compose
using Obfuscatee
using Nettle
using ProgressMeter
using POMDPSimulators

export
    LaserTagPOMDP,
    LTState,
    lasertag

Pos = SVector{2, Int}

struct LTState
    robot::Pos
    target::Pos
end


struct LaserTagPOMDP <: POMDP{LTState, Symbol, SVector{4,Int}}
    size::SVector{2, Int}
    obstacles::Set{Pos}
    blocked::BitArray{2}
    robot_init::Pos
end

function LaserTagPOMDP(;size=(11,7), n_obstacles=8, rng::AbstractRNG=Random.GLOBAL_RNG)
    obstacles = Set{Pos}()
    blocked = falses(size...)
    while length(obstacles) < n_obstacles
        obs = SVector(rand(rng, 1:size[1]), rand(rng, 1:size[2]))
        push!(obstacles, obs)
        blocked[obs...] = true
    end
    robot_init = SVector(rand(rng, 1:size[1]), rand(rng, 1:size[2]))
    LaserTagPOMDP(size, obstacles, blocked, robot_init)
end

Random.rand(rng::AbstractRNG, ::Random.SamplerType{LaserTagPOMDP}) = LaserTagPOMDP(rng=rng)

lasertag = LaserTagPOMDP(size=(11,7), n_obstacles=14, rng=MersenneTwister(20))

POMDPs.actions(m::LaserTagPOMDP) = (:left, :right, :up, :down, :measure)
POMDPs.states(m::LaserTagPOMDP) = vec(collect(LTState(SVector(rx, ry), SVector(tx, ty)) for rx in 1:m.size[1], ry in 1:m.size[2], tx in 1:m.size[1], ty in 1:m.size[2]))
function POMDPs.observations(m::LaserTagPOMDP)
    os = SVector{4,Int}[]
    for left in 0:m.size[1]-1
        for right in 0:m.size[1]-left-1
            for up in 0:m.size[2]-1
                for down in 0:m.size[1]-up-1
                    push!(os, SVector(left, right, up, down))
                end
            end
        end
    end
    return os
end
POMDPs.discount(m::LaserTagPOMDP) = 0.99

POMDPs.stateindex(m::LaserTagPOMDP, s) = (LinearIndices((m.size[1],m.size[2]))[s.robot[1], s.robot[2]]-1)*prod(m.size)+LinearIndices((m.size[1],m.size[2]))[s.target[1], s.target[2]]
POMDPs.actionindex(m::LaserTagPOMDP, a) = actionind[a]

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

function POMDPs.transition(m::LaserTagPOMDP, s, a)
    states = LTState[]    
    newrobot = bounce(m, s.robot, actiondir[a])
    newstates = [LTState(newrobot, s.target)]
    probs = [0.0]
    if sum(abs, newrobot - s.target) > 2 # move randomly
        for change in (SVector(-1,0), SVector(1,0), SVector(0,1), SVector(0,-1))
            newtarget = bounce(m, s.target, change)
            if newtarget == s.target
                probs[1] += 0.25
            else
                push!(newstates, LTState(newrobot, newtarget))
                push!(probs, 0.25)
            end
        end
    else # move away 
        away = sign.(s.target - s.robot)
        if sum(abs, away) == 2 # diagonal
            away = away - SVector(0, away[2]) # preference to move in x direction
        end
        newtarget = bounce(m, s.target, away)
        newstates[1] = LTState(newrobot, newtarget)
        probs[1] = 1.0
    end
    return SparseCat(newstates, probs)
end

POMDPs.isterminal(m::LaserTagPOMDP, s) = s.target == s.robot

struct LaserDistribution
    ranges::SVector{4, Int}
    measured::Bool
end

function POMDPs.pdf(d::LaserDistribution, o)
    if d.measured
        return convert(Float64, o == d.ranges)
    else
        if all(0 .<= o .<= d.ranges)
            return 1/prod(d.ranges.+1)
        else
            return 0.0
        end
    end
end

function POMDPs.rand(rng::AbstractRNG, d::LaserDistribution)
    if d.measured
        return d.ranges
    else
        return SVector(rand(rng, 0:d.ranges[1]), rand(rng, 0:d.ranges[2]), rand(rng, 0:d.ranges[3]), rand(rng, 0:d.ranges[4]))
    end
end

function POMDPs.support(d::LaserDistribution)
    if d.measured
        return [d.ranges]
    else
        os = SVector{4,Int}[]
        for left in 0:d.ranges[1]
            for right in 0:d.ranges[2]
                for up in 0:d.ranges[3]
                    for down in 0:d.ranges[4]
                        push!(os, SVector(left, right, up, down))
                    end
                end
            end
        end
        return os
    end
end

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
    return LaserDistribution(ranges, a==:measure)
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

function POMDPs.initialstate_distribution(m::LaserTagPOMDP)
    return Uniform(LTState(m.robot_init, SVector(x, y)) for x in 1:m.size[1], y in 1:m.size[2])
end

function POMDPModelTools.render(m::LaserTagPOMDP, step)
    nx, ny = m.size
    cells = []
    if haskey(step, :bp)
        robotpos = first(support(step[:bp])).robot
    end
    for x in 1:nx, y in 1:ny
        cell = cell_ctx((x,y), m.size)
        if SVector(x, y) in m.obstacles
            compose!(cell, rectangle(), fill("darkgray"))
        else
            if haskey(step, :bp)
                op = sqrt(pdf(step[:bp], LTState(robotpos, SVector(x, y))))
            else
                op = 0.0
            end
            compose!(cell, rectangle(), fillopacity(op), fill("yellow"), stroke("gray"))
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
    else
        robot = nothing
        target = nothing
    end

    if haskey(step, :o) && haskey(step, :sp)
        o = step[:o]
        robot_ctx = cell_ctx(step[:sp].robot, m.size)
        left = compose(context(), line([(0.0, 0.5),(-o[1],0.5)]))
        right = compose(context(), line([(1.0, 0.5),(1.0+o[2],0.5)]))
        up = compose(context(), line([(0.5, 0.0),(0.5, -o[3])]))
        down = compose(context(), line([(0.5, 1.0),(0.5, 1.0+o[4])]))
        lasers = compose(robot_ctx, strokedash([1mm]), stroke("red"), left, right, up, down)
    end

    sz = min(w,h)
    return compose(context((w-sz)/2, (h-sz)/2, sz, sz), robot, target, lasers, grid, outline)
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
