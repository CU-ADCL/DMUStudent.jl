module HW3

using ..Obfuscatee
using Nettle
using JSON

using POMDPs
using POMDPTools
using StaticArrays
using Parameters
using Random
using Distributions
using ProgressMeter
using Compose
using ColorSchemes
using Colors: weighted_color_mean, hex, @colorant_str
using D3Trees: D3Tree, inchrome
using Printf: @sprintf
using SparseArrays

import DMUStudent

export
    DenseGridWorld,
    GWPos,
    visualize_tree

const GWPos = SVector{2,Int}
const DEFAULT_SIZE = (60,60)
const RD = 20

struct DenseGridWorld <: MDP{GWPos, Symbol}
    size::Tuple{Int, Int}
    rewards::Dict{GWPos, Float64}
    costs::Matrix{Float64}
    data::Matrix{Float64}
    terminate_from::Set{GWPos}
    discount::Float64
end

function DenseGridWorld(;size = DEFAULT_SIZE,
                         rewards = Dict(GWPos(x,y) => 100.0 for x in RD:RD:size[1]-RD, y in RD:RD:size[2]-RD),
                         seed = rand(UInt32),
                         costs = gencosts(size, MersenneTwister(seed)),
                         data = rand(size...),
                         terminate_from = Set(keys(rewards)),
                         discount = 0.95
    )
    return DenseGridWorld(size, rewards, costs, data, terminate_from, discount)
end

function gencosts(size=DEFAULT_SIZE, rng::AbstractRNG=Random.GLOBAL_RNG)
    rand(rng, Exponential(1.0), size) + rand(rng, Bernoulli(0.1), size).*50.0
end

isedge(m::DenseGridWorld, s) = any(s .== 1) || any(s .== m.size[1])

function Random.rand(rng::AbstractRNG, ::Random.SamplerType{DenseGridWorld})
    return DenseGridWorld(size=DEFAULT_SIZE, costs=gencosts(DEFAULT_SIZE, rng))
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
        return prod(m.size) + 1
    end
end

POMDPs.initialstate(m::DenseGridWorld) = POMDPTools.Uniform(states(m)[1:end-1])

# Actions

POMDPs.actions(m::DenseGridWorld) = (:up, :down, :left, :right)

const dir = Dict(:up=>GWPos(0,1), :down=>GWPos(0,-1), :left=>GWPos(-1,0), :right=>GWPos(1,0))
const aind = Dict(:up=>1, :down=>2, :left=>3, :right=>4)

POMDPs.actionindex(m::DenseGridWorld, a::Symbol) = aind[a]

# Transitions

POMDPs.isterminal(m::DenseGridWorld, s::AbstractVector{Int}) = any(s.<0)

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

include("hw3_vis.jl")
include("hw3_tree_vis.jl")

@binclude(".bin/hw3_eval")

end
