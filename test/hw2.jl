@testset "HW2" begin
    using DMUStudent.HW2
    using POMDPs
    using DiscreteValueIteration
    using POMDPTesting

    for n in 1
        m = UnresponsiveACASMDP(n)

        @test all(convert_s(ACASState, convert_s(Int, s, m), m) == s for s in states(m))
        @test has_consistent_transition_distributions(m)

        solver = ValueIterationSolver()
        policy = solve(solver, m)
        v = [value(policy, s) for s in states(m)]

        @test HW2.evaluate(v).score == n
        @test HW2.evaluate(v, "test1234@colorado.edu").score == n

        v[3] += 1.0
        @test HW2.evaluate(v).score == 0

        short = v[1:end-1]
        @test_throws ErrorException HW2.evaluate(short)
    end

    medium = ones(1250*19^3)
    @test HW2.evaluate(medium).score == 0

    large = ones(1250*21^3)
    @test HW2.evaluate(large).score == 0
end
