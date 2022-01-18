@testset "HW1" begin
    using DMUStudent.HW1

    f(x) = max(zero(x),x)
    results = HW1.evaluate(f, "zachary.sunberg@colorado.edu", fname="good_results.json")
    @test results.score == 1

    results = HW1.evaluate(f)
    @test results.score == 1

    function g(x)
        if x > 0
            return 0
        else
            x
        end
    end
    results = HW1.evaluate(g, "test1234@colorado.edu")
    @test results.score == 0

    function g(x)
        if x > 0
            return x
        else
            return 0
        end
    end
    results = HW1.evaluate(g, "test1234@colorado.edu")
    @test results.score == 0

    h(x) = max(0, x)
    results = HW1.evaluate(h, "test1234@colorado.edu")
    @test results.score == 0
end
