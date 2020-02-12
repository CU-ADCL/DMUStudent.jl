@testset "HW3" begin
    using DMUStudent
    using DMUStudent.HW3
    using POMDPs
    using DiscreteValueIteration
    using POMDPTesting
    using POMDPPolicies

    @time m = DenseGridWorld()
    # @test has_consistent_distributions(m)

    @time m = rand(DenseGridWorld)
    # @test has_consistent_distributions(m)
    
    @test evaluate(RandomSolver(), "hw3") <= 100.0
end
