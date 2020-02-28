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
    
    @warn("Skipping HW3 evaluate testing for speed")
    # @test DMUStudent.evaluate(RandomSolver(), "hw3") <= 100.0
    # HW3.evaluate_for_submission(RandomSolver(), "test1234@colorado.edu")

    r = render(DenseGridWorld(size=(60,60)), (s=GWPos(30,30),))
    draw(SVG(tempname()*".svg"), r)
end
