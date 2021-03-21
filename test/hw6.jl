@testset "HW6" begin
    using DMUStudent
    using DMUStudent.HW6
    using POMDPs
    using POMDPTesting
    using QMDP
    using POMDPSimulators
    using POMDPPolicies
    import POMDPModelTools: render, Uniform
    using Compose
    using SARSOP

    small = LaserTagPOMDP(size=(4,3), n_obstacles=3)

    @test has_consistent_distributions(small)

    @test simulate(RolloutSimulator(max_steps=100), small, RandomPolicy(small)) isa Float64

    solve(QMDPSolver(), small)

    sp = LTState([3, 2], [2, 3])
    r = render(small, (o=[1,1,1,1], bp=Uniform(states(small)), sp=sp))
    filename = "/tmp/lasertag.svg"
    draw(SVG(filename), r)

    r = render(small, (done=true,))

    @test HW6.evaluate(RandomPolicy(LaserTagPOMDP())).score < 0.0
    @test HW6.evaluate(RandomPolicy(LaserTagPOMDP()), "zachary.sunberg@colorado.edu").score < 0.0

    tiny = LaserTagPOMDP(size=(2,2), n_obstacles=0)

    solve(SARSOPSolver(), tiny)
end
