module HW2

using Obfuscatee
using Nettle
using JSON
using ProgressMeter
using Random

using POMDPs
using StaticArrays
using Distributions
using Discretizers
using POMDPModelTools
using POMDPPolicies

export
    UnresponsiveACASMDP,
    ACASState,
    transition_matrices,
    reward_vectors

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

struct UnresponsiveACASMDP <: MDP{Int, Int}
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

POMDPs.actions(m::UnresponsiveACASMDP) = 1:3
POMDPs.states(m::UnresponsiveACASMDP) = 1:prod(map(nlabels, (m.hbins, m.hdotbins, m.hbins, m.dbins)))

POMDPs.discount(::UnresponsiveACASMDP) = 0.99

struct ACASState <: FieldVector{4, Float64}
    h_o::Float64
    hdot_o::Float64
    h_i::Float64
    d::Float64
end

function POMDPs.reward(m::UnresponsiveACASMDP, s, a, sp)
    r = 0.0
    acasp = convert_s(ACASState, sp, m)
    if is_nmac(m, acasp)
        r -= 100.0
    end
    r -= abs(a-2)
    return r
end

function POMDPs.transition(m::UnresponsiveACASMDP, s, a)
    acas = convert_s(ACASState, s, m)
    d = acas.d - 2*v*m.dt
    hdot_o = clamp(acas.hdot_o + (a-2)*delta_hdot, -3000, 3000)
    h_o = acas.h_o + hdot_o*m.dt
    
    nhbins = nlabels(m.hbins)
    h_i_bin = encode(m.hbins, acas.h_i)

    states = Vector{Int}(undef, nhbins)
    for (i, h) in enumerate(bincenters(m.hbins))
        states[i] = convert_s(Int, ACASState(h_o, hdot_o, h, d), m)
    end

    start = nhbins-h_i_bin + 1
    @assert 1 <= start <= length(m._cached_cdf)
    finish = start + nhbins - 2
    @assert finish <= length(m._cached_cdf)
    probs = Vector{Float64}(undef, nhbins)
    probs[1] = m._cached_cdf[start]
    probs[2:nhbins-1] = m._cached_cdf[start+1:finish] - m._cached_cdf[start:finish-1]
    probs[end] = 1.0 - m._cached_cdf[finish]
    @assert length(probs) == nhbins
    @assert length(states) == nhbins
    @assert sum(probs) ≈ 1

    return SparseCat(states, probs)
end

function POMDPs.isterminal(m::UnresponsiveACASMDP, s)
    acas = convert_s(ACASState, s, m)
    if is_nmac(m, acas) || acas.d <= binedges(m.dbins)[2]
        return true
    else
        return false
    end
end

function POMDPs.convert_s(::Type{ACASState}, s::Integer, m::UnresponsiveACASMDP)
    shape = map(nlabels, (m.hbins, m.hdotbins, m.hbins, m.dbins))
    bins = CartesianIndices(shape)[s]
    h_o = bincenter(m.hbins, bins[1])
    hdot_o = bincenter(m.hdotbins, bins[2])
    h_i = bincenter(m.hbins, bins[3])
    d = maxd-bincenter(m.dbins, bins[4])
    return ACASState(h_o, hdot_o, h_i, d)
end

function POMDPs.convert_s(::Type{Int}, acas::ACASState, m::UnresponsiveACASMDP)
    h_o_bin = encode(m.hbins, acas.h_o)
    hdot_o_bin = encode(m.hdotbins, acas.hdot_o)
    h_i_bin = encode(m.hbins, acas.h_i)
    dbin = encode(m.dbins, maxd-acas.d)
    shape = map(nlabels, (m.hbins, m.hdotbins, m.hbins, m.dbins))
    return LinearIndices(shape)[h_o_bin, hdot_o_bin, h_i_bin, dbin]
end

POMDPs.stateindex(m, s) = s
POMDPs.actionindex(m, a) = a

# less than 100 ft vertically and 500 ft horizontally
function is_nmac(m::UnresponsiveACASMDP, acas::ACASState)
    return (acas.d < binedges(m.dbins)[2] || acas.d <= 500) && abs(acas.h_o - acas.h_i) <= 100
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
    transition_matrices(m, [sparse=true])

Create a dictionary mapping actions to transition matrices for UnresponsiveACASMDP m.

# Example
```julia
T = transition_matrices(m)
T[1][2,3] # probability of transitioning from state 2 to 3 when action 1 is taken
```

# Arguments
- `m`: `UnresponsiveACASMDP` model

# Keyword Arguments
- `sparse::Bool`: if true, returns a sparse matrix representation (with significant memory savings!), if false, the matrices will be dense
"""
function transition_matrices(m::UnresponsiveACASMDP; sparse::Bool=false)
    transmats = POMDPModelTools.transition_matrix_a_s_sp(m)
    if !sparse
        transmats = [convert(Matrix, t) for t in transmats]
    end
    mtype = typeof(first(transmats))
    oa = ordered_actions(m)
    return Dict{Int,mtype}(oa[ai]=>transmats[ai] for ai in 1:length(actions(m)))
end

function reward_vectors(m::UnresponsiveACASMDP)
    d = Dict{actiontype(m), Vector{Float64}}()
    for a in actions(m)
        rv = POMDPModelTools.policy_reward_vector(m, FunctionPolicy(s->a))
        d[a] = rv
    end
    return d
end

@binclude(".bin/hw2_eval")

end
