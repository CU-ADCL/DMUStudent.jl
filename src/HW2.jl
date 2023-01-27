module HW2

using ..Obfuscatee
using Nettle
using JSON
using ProgressMeter
using Random

using POMDPs
using StaticArrays
using Distributions
using Discretizers
using POMDPTools
using POMDPModels: SimpleGridWorld

import UnicodePlots
using Compose: compose, context, text, polygon, hcenter, hleft, hright, vtop

import DMUStudent

export
    UnresponsiveACASMDP,
    ACASState,
    transition_matrices,
    reward_vectors,
    grid_world,
    render

# Problem 4: Grid World

const grid_world = SimpleGridWorld()

# Problem 5: ACAS

const v = 44000 # 500 mph in ft per minute
const hlim = (27500, 32500) # ft
const hdotlim = (-3750, 3750)
const h_i_stdev = 500 # ft per sqrt(minute)
const base_dbins = 10
const base_hbins = 5
const nhdotbins = 5
const delta_hdot = 1500 # ft/min
const timespan = 150/60 # minutes
const maxd = timespan*2*v

struct ACASState <: FieldVector{4, Float64}
    h_o::Float64
    hdot_o::Float64
    h_i::Float64
    d::Float64
end

struct UnresponsiveACASMDP <: MDP{ACASState, Int}
    dt::Float64 # minutes
    hbins::LinearDiscretizer{Float64, Int}
    hdotbins::LinearDiscretizer{Float64, Int}
    dbins::LinearDiscretizer{Float64, Int}
    _cached_cdf::Vector{Float64}
end

function UnresponsiveACASMDP(n)
    nhbins = base_hbins*n
    hbins = LinearDiscretizer(range(hlim[1], hlim[2], length=nhbins+1))
    @assert nlabels(hbins) == nhbins

    ndbins = base_dbins*n
    dbins = LinearDiscretizer(range(0.0, maxd, length=ndbins+1))
    @assert nlabels(dbins) == ndbins

    hdotbins = LinearDiscretizer(range(hdotlim[1], hdotlim[2], length=nhdotbins+1))

    dt = timespan/ndbins
    ccdf = cached_cdf(hbins, sqrt(dt*h_i_stdev^2)) 
    return UnresponsiveACASMDP(dt, hbins, hdotbins, dbins, ccdf)
end

POMDPs.actions(m::UnresponsiveACASMDP) = (-delta_hdot, 0, delta_hdot)
POMDPs.states(m::UnresponsiveACASMDP) = [convert_s(ACASState, si, m) for si in 1:prod(map(nlabels, (m.hbins, m.hdotbins, m.hbins, m.dbins)))]

POMDPs.discount(::UnresponsiveACASMDP) = 0.99

function POMDPs.reward(m::UnresponsiveACASMDP, s::ACASState, a, sp::ACASState)
    r = 0.0
    if is_nmac(m, sp)
        r -= 100.0
    end
    r -= abs(sign(a))
    return r
end
POMDPs.reward(m::UnresponsiveACASMDP, v::AbstractVector, a, vp::AbstractVector) = reward(m, convert(ACASState, v), a, convert(ACASState, vp))

function POMDPs.transition(m::UnresponsiveACASMDP, s::ACASState, a)
    d = s.d - 2*v*m.dt
    hdot_o = clamp(s.hdot_o + a, -3000, 3000)
    h_o = bincenter(m.hbins, encode(m.hbins, s.h_o + hdot_o*m.dt))
    
    nhbins = nlabels(m.hbins)
    h_i_bin = encode(m.hbins, s.h_i)

    states = Vector{ACASState}(undef, nhbins)
    for (i, h) in enumerate(bincenters(m.hbins))
        states[i] = ACASState(h_o, hdot_o, h, d)
    end

    start = nhbins-h_i_bin + 1
    @assert 1 <= start <= length(m._cached_cdf)
    finish = start + nhbins - 2
    @assert finish <= length(m._cached_cdf)
    probs = Vector{Float64}(undef, nhbins)
    probs[1] = m._cached_cdf[start]
    probs[2:nhbins-1] = view(m._cached_cdf, start+1:finish) - view(m._cached_cdf, start:finish-1)
    probs[end] = 1.0 - m._cached_cdf[finish]
    @assert length(probs) == nhbins
    @assert length(states) == nhbins
    @assert sum(probs) ≈ 1

    return SparseCat(states, probs)
end
POMDPs.transition(m::UnresponsiveACASMDP, s::AbstractVector, a) = transition(m::UnresponsiveACASMDP, convert(ACASState, s), a)

function POMDPs.isterminal(m::UnresponsiveACASMDP, s::ACASState)
    if is_nmac(m, s) || s.d <= binedges(m.dbins)[2]
        return true
    else
        return false
    end
end
POMDPs.isterminal(m::UnresponsiveACASMDP, s::AbstractVector) = isterminal(m, convert(ACASState, s))

POMDPs.initialstate(::UnresponsiveACASMDP) = Deterministic(ACASState(sum(hlim)/2, 0.0, sum(hlim)/2, maxd))

function POMDPs.convert_s(::Type{ACASState}, s::Integer, m::UnresponsiveACASMDP)
    shape = map(nlabels, (m.hbins, m.hdotbins, m.hbins, m.dbins))
    bins = CartesianIndices(shape)[s]
    h_o = bincenter(m.hbins, bins[1])
    hdot_o = bincenter(m.hdotbins, bins[2])
    h_i = bincenter(m.hbins, bins[3])
    d = maxd-bincenter(m.dbins, bins[4])
    return ACASState(h_o, hdot_o, h_i, d)
end

function POMDPs.convert_s(::Type{Int}, s::ACASState, m::UnresponsiveACASMDP)
    return stateindex(m, s)
end
POMDPs.convert_s(::Type{Int}, s::AbstractVector, m::UnresponsiveACASMDP) = convert_s(Int, convert(ACASState, s), m)

function POMDPs.stateindex(m::UnresponsiveACASMDP, v)
    s = convert(ACASState, v)
    h_o_bin = encode(m.hbins, s.h_o)
    hdot_o_bin = encode(m.hdotbins, s.hdot_o)
    h_i_bin = encode(m.hbins, s.h_i)
    dbin = encode(m.dbins, maxd-s.d)
    shape = map(nlabels, (m.hbins, m.hdotbins, m.hbins, m.dbins))
    return LinearIndices(shape)[h_o_bin, hdot_o_bin, h_i_bin, dbin]
end

POMDPs.actionindex(m::UnresponsiveACASMDP, a) = sign(a)+2

# less than 100 ft vertically and 500 ft horizontally
function is_nmac(m::UnresponsiveACASMDP, s::ACASState)
    return (s.d < binedges(m.dbins)[2] || s.d <= 500) && abs(s.h_o - s.h_i) <= 100
end

function cached_cdf(hbins, stdev)
    nbins = nlabels(hbins)
    binsize = (hlim[2]-hlim[1])/nbins
    @assert binsize ≈ mean(binwidths(hbins))
    d = Normal(0.0, stdev)
    npoints = 2*nbins-1
    lower = -(nbins - 0.5)*binsize
    
    cdfvals = Vector{Float64}(undef, npoints)
    for p in 1:npoints
        pt = lower + p*binsize
        cdfvals[p] = cdf(d, pt)
    end

    # some sanity checks
    @assert lower ≈ hlim[1] - (hlim[2] - 0.5*binsize)
    @assert lower + binsize*npoints ≈ hlim[2] - (hlim[1] + 0.5*binsize)
    @assert all(0 .<= cdfvals .<= 1)

    return cdfvals
end

function bincenter(d::LinearDiscretizer, binindex)
    be = binedges(d)
    return (be[binindex+1] + be[binindex])/2
end

"""
    transition_matrices(m; [sparse=true])

Create a dictionary mapping actions to transition matrices for MDP m.

# Example
```julia
T = transition_matrices(m)
T[1][2,3] # probability of transitioning from state 2 to 3 when action 1 is taken
```

# Arguments
- `m`: `MDP` model

# Keyword Arguments
- `sparse::Bool`: if true, returns a sparse matrix representation (with significant memory savings!), if false, the matrices will be dense
"""
function transition_matrices(m::MDP; sparse::Bool=false)
    transmats = POMDPTools.ModelTools.transition_matrix_a_s_sp(m)
    if !sparse
        transmats = [convert(Matrix, t) for t in transmats]
    end
    mtype = typeof(first(transmats))
    oa = ordered_actions(m)
    return Dict{actiontype(m), mtype}(oa[ai]=>transmats[ai] for ai in 1:length(actions(m)))
end

function reward_vectors(m::MDP)
    d = Dict{actiontype(m), Vector{Float64}}()
    for a in actions(m)
        rv = POMDPTools.Policies.policy_reward_vector(m, FunctionPolicy(s->a))
        d[a] = rv
    end
    return d
end

include("hw2_vis.jl")

@binclude(".bin/hw2_eval")

end
