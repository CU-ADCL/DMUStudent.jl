@testset "HW3" begin
    using DMUStudent.HW3
    using POMDPs
    using DiscreteValueIteration
    using POMDPTesting

    @time m = DenseGridWorld()
    @test has_consistent_distributions(m)

    @time m = rand(DenseGridWorld)
    @test has_consistent_distributions(m)
end
