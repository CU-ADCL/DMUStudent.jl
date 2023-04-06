using DMUStudent
using DMUStudent.HW6
using POMDPs
using QMDP
using POMDPTools
import POMDPTools: render, Uniform
using Compose
using SARSOP
using Random

@testset "HW6" begin
    small = LaserTagPOMDP(size=(4,3), n_obstacles=3)

    @test has_consistent_distributions(small)

    @test simulate(RolloutSimulator(max_steps=100), small, RandomPolicy(small)) isa Float64

    @time solve(QMDPSolver(), small)

    sp = LTState([3, 2], [2, 3], [4,1])
    r = render(small, (o=[1,1,1,1], bp=Uniform(states(small)), sp=sp))
    filename = joinpath(tempdir(), "lasertag.svg")
    draw(SVG(filename), r)

    r = render(small, (done=true,))

    @test HW6.evaluate(RandomPolicy(LaserTagPOMDP())).score < 0.0
    @test HW6.evaluate(RandomPolicy(LaserTagPOMDP()), "zachary.sunberg@colorado.edu").score < 0.0

    @time solve(SARSOPSolver(precision=10.0), small)

    rng = MersenneTwister(21)
    m = LaserTagPOMDP()
    up = DiscreteUpdater(m)
    b = initialize_belief(up, initialstate(m))
    s = rand(rng, b)
    a = first(actions(m))
    sp = @gen(:sp)(m, s, a)
    o = rand(rng, observation(m, s, a, sp))
    update(up, b, a, o)
    @time update(up, b, a, o)

    @testset "pr-64" begin
        a = rand(actions(m))
        sp = rand(states(m))
        o = rand(observation(m,a,sp))
        @test o isa obstype(m)

        @test obsindex(m, o) isa Int
    end
end
