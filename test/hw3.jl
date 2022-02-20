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
    @test has_consistent_distributions(m)

    @time m = rand(DenseGridWorld)
    @test has_consistent_distributions(m)
    
    # @warn("Skipping HW3 evaluate testing for speed")
    @test HW3.evaluate(RandomSolver()).score <= 100.0

    right_size::Bool = true
    function select_action(m, s)
        right_size &= length(states(m)) == 10_001
        return rand(actions(m))
    end
    @test HW3.evaluate(select_action, "email@colorado.edu").score <= 100.0
    @test right_size

    @test DenseGridWorld(seed=1).costs == DenseGridWorld(seed=1).costs

    r = render(DenseGridWorld(size=(60,60)), (s=GWPos(30,30),))
    draw(SVG(tempname()*".svg"), r)

    q = Dict((1,1)=>0.0, (2,1)=>0.0)
    n = Dict((1,1)=>1, (2,1)=>0)
    t = Dict((1,1,2)=>1)
    tv = visualize_tree(q, n, t, 1)
    sprint((io, x)->show(io, MIME("text/html"), x), tv)

    q = Dict((1,1)=>0.0)
    n = Dict((1,1)=>1)
    t = Dict((1,1,2)=>1)
    tv = visualize_tree(q, n, t, 1)
    sprint((io, x)->show(io, MIME("text/html"), x), tv)
end
