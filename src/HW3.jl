module HW3

using POMDPs
using StaticArrays
using Parameters
using Random
using Distributions
using POMDPModelTools

export DenseGridWorld

const GWPos = SVector{2,Int}

@with_kw struct DenseGridWorld <: MDP{GWPos, Symbol}
    size::Tuple{Int, Int}           = (100,100)
    rewards::Dict{GWPos, Float64}   = Dict(GWPos(33,33)=>100.0, GWPos(33,67)=>100.0, GWPos(67,33)=>100.0, GWPos(67,67)=>100.0)
    costs::Matrix{Float64}          = zeros(size)
    terminate_from::Set{GWPos}      = Set(keys(rewards))
    tprob::Float64                  = 0.9
    discount::Float64               = 0.95
end

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{DenseGridWorld})
    size = (100,100)
    costs = rand(rng, Exponential(0.5), size) + rand(rng, Bernoulli(0.1), size).*10.0
    return DenseGridWorld(size=size, costs=costs)
end

# States

function POMDPs.states(m::DenseGridWorld)
    ss = vec(GWPos[GWPos(x, y) for x in 1:m.size[1], y in 1:m.size[2]])
    push!(ss, GWPos(-1,-1))
    return ss
end

function POMDPs.stateindex(m::DenseGridWorld, s::AbstractVector{Int})
    if all(s.>0)
        return LinearIndices(m.size)[s...]
    else
        return prod(m.size) + 1 # TODO: Change
    end
end

POMDPs.initialstate_distribution(m::DenseGridWorld) = POMDPModelTools.Uniform(states(m)[1:end-1])

# Actions

POMDPs.actions(m::DenseGridWorld) = (:up, :down, :left, :right)
Base.rand(rng::AbstractRNG, t::NTuple{L,Symbol}) where L = t[rand(rng, 1:length(t))] # don't know why this doesn't work out of the box


const dir = Dict(:up=>GWPos(0,1), :down=>GWPos(0,-1), :left=>GWPos(-1,0), :right=>GWPos(1,0))
const aind = Dict(:up=>1, :down=>2, :left=>3, :right=>4)

POMDPs.actionindex(m::DenseGridWorld, a::Symbol) = aind[a]

# Transitions

POMDPs.isterminal(m::DenseGridWorld, s::AbstractVector{Int}) = any(s.<0)

function POMDPs.transition(m::DenseGridWorld, s::AbstractVector{Int}, a::Symbol)
    if s in m.terminate_from || isterminal(m, s)
        return Deterministic(GWPos(-1,-1))
    end

    destinations = MVector{length(actions(m))+1, GWPos}(undef)
    destinations[1] = s

    probs = @MVector(zeros(length(actions(m))+1))
    for (i, act) in enumerate(actions(m))
        if act == a
            prob = m.tprob # probability of transitioning to the desired cell
        else
            prob = (1.0 - m.tprob)/(length(actions(m)) - 1) # probability of transitioning to another cell
        end

        dest = s + dir[act]
        destinations[i+1] = dest

        if !inbounds(m, dest) # hit an edge and come back
            probs[1] += prob
            destinations[i+1] = GWPos(-1, -1) # dest was out of bounds - this will have probability zero, but it should be a valid state
        else
            probs[i+1] += prob
        end
    end

    return SparseCat(destinations, probs)
end

function inbounds(m::DenseGridWorld, s::AbstractVector{Int})
    return 1 <= s[1] <= m.size[1] && 1 <= s[2] <= m.size[2]
end

# Rewards

POMDPs.reward(m::DenseGridWorld, s::AbstractVector{Int}) = get(m.rewards, s, 0.0) - m.costs[s...]
POMDPs.reward(m::DenseGridWorld, s::AbstractVector{Int}, a::Symbol) = reward(m, s)


# discount

POMDPs.discount(m::DenseGridWorld) = m.discount

# Conversion
function POMDPs.convert_a(::Type{V}, a::Symbol, m::DenseGridWorld) where {V<:AbstractArray}
    convert(V, [aind[a]])
end
function POMDPs.convert_a(::Type{Symbol}, vec::V, m::DenseGridWorld) where {V<:AbstractArray}
    actions(m)[convert(Int, first(vec))]
end


end
