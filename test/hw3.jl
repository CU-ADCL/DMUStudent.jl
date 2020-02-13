@testset "HW3" begin
    using DMUStudent
    using DMUStudent.HW3
    using POMDPs
    using DiscreteValueIteration
    using POMDPTesting
    using POMDPPolicies
    using POMDPModelTools
    using Compose

    @time m = DenseGridWorld()
    # @test has_consistent_distributions(m)

    @time m = rand(DenseGridWorld)
    # @test has_consistent_distributions(m)
    
    @test DMUStudent.evaluate(RandomSolver(), "hw3") <= 100.0

    r = render(DenseGridWorld(size=(60,60)), NamedTuple())
    draw(SVG(tempname()*".svg"), r)
end
