module HW5

using DMUStudent
using Compose
using StaticArrays
using CommonRLInterface
using Random: GLOBAL_RNG, MersenneTwister, SamplerTrivial, AbstractRNG
using Obfuscatee
using ProgressMeter: @showprogress
using JSON
using IntervalSets
using GameZero

export mc

Base.rand(rng::AbstractRNG, s::SamplerTrivial{<:AbstractInterval}) = minimum(s[]) + rand(rng)*(maximum(s[]) - minimum(s[]))

@binclude(".bin/hw5_eval")

mc = MountainCar()

end
