module HW5

using DMUStudent
using Compose
using StaticArrays
using CommonRLInterface
using Random: GLOBAL_RNG, MersenneTwister
using Obfuscatee
using ProgressMeter: @showprogress
using JSON

export mc

@binclude(".bin/hw5_eval")

mc = MountainCar()

end
