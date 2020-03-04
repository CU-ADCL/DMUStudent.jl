module HW4

using QuickPOMDPs
using RLInterface
using ProgressMeter
using StaticArrays
using Random
import POMDPModelTools
using Compose
using POMDPModels
using Obfuscatee
using POMDPs
using Nettle
using JSON

export mc, gw

const discount=0.99

struct RealInterval{T}
    l::T
    u::T
end

Base.minimum(i::RealInterval) = i.l
Base.maximum(i::RealInterval) = i.u
Base.in(x, i::RealInterval) = i.l <= x <= i.u
Base.eltype(::Type{RealInterval{T}}) where T = T

function Random.rand(rng::AbstractRNG, d::Random.SamplerTrivial{R}) where R <: RealInterval
    u = maximum(d[])
    l = minimum(d[])
    return (u-l)*rand(rng) + l
end

@binclude(".bin/hw4_eval")

# to fix errors with using environments from python
function POMDPs.gen(v::DDNOut{symbols}, m::QuickMDP, s, a, rng) where symbols
    ddn = DDNStructure(m)
    POMDPs.genout(v, ddn, m, s, a, rng)
end

RLInterface.render(gw::typeof(gw); kwargs...) = POMDPModelTools.render(gw.problem, (s=gw.state,); kwargs...)

RLInterface.render(mc::typeof(mc); kwargs...) = POMDPModelTools.render(mc.problem, (s=mc.state,); kwargs...)

end
