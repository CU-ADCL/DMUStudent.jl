@testset "HW2" begin
    using DMUStudent.HW2
    using POMDPs
    using DiscreteValueIteration
    using POMDPTesting

    for n in 1:2
        m = UnresponsiveACASMDP(n)

        @test all(convert_s(Int, convert_s(ACASState, s, m), m) == s for s in states(m))
        @test has_consistent_transition_distributions(m)

        solver = ValueIterationSolver()
        policy = solve(solver, m)
        v = [value(policy, s) for s in states(m)]

        @test HW2.evaluate(v) == n
        @test first(HW2.evaluate(v, "test1234@colorado.edu")) == n

        @test evaluate(v, "hw2") == n

        v[3] += 1.0
        @test HW2.evaluate(v) == 0

        short = v[1:end-1]
        @test_throws ErrorException HW2.evaluate(short)
    end

    medium = ones(1250*19^3)
    @test HW2.evaluate(medium) == 0

    large = ones(1250*21^3)
    @test HW2.evaluate(large) == 0
end
