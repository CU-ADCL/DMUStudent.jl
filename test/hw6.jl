@testset "HW6" begin
    using DMUStudent
    using DMUStudent.HW6
    using POMDPs
    using POMDPTesting
    using QMDP
    using POMDPSimulators
    using POMDPPolicies
    using POMDPModelTools
    using Compose

    @show small = LaserTagPOMDP(size=(4,3), n_obstacles=3)

    @test has_consistent_distributions(small)

    @test simulate(RolloutSimulator(max_steps=100), small, RandomPolicy(small)) isa Float64

    sp = LTState([3, 2], [2, 3])
    r = render(small, (o=[1,1,1,1], bp=Uniform(states(small)), sp=sp))
    filename = "/tmp/lasertag.svg"
    draw(SVG(filename), r)
end
