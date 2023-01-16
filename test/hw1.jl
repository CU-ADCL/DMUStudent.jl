@testset "HW1" begin
    using DMUStudent.HW1

    f(a, bs) = nothing
    @test HW1.evaluate(f).score==0
    @test HW1.evaluate(f, "zachary.sunberg@colorado.edu", fname="bad_results.json").score==0
    @test HW1.evaluate(f, "zachary.sunberg@colorado.edu").score==0

    f(a, bs) = a*first(bs)
    @test HW1.evaluate(f).score==0
    @test HW1.evaluate(f, "jodo1234@colorado.edu").score==0

    function solution(a, bs)
        v = a*first(bs)
        for b in bs
            v = max.(v, a*b)
        end
        return v
    end
    @test HW1.evaluate(solution).score==1
    @test HW1.evaluate(solution, "jodo1234@colorado.edu").score==1

    f(a, bs) = convert(Vector{Float64}, solution(a, bs))
    @test HW1.evaluate(f).score==0.5
    @test HW1.evaluate(f, "jodo1234@colorado.edu").score==0.5

    function unstable(a, bs)
        v = floor.(Int, a*first(bs))
        for b in bs
            v = max.(v, a*b)
        end
        return v
    end
    @test HW1.evaluate(unstable).score==0.9
    @test HW1.evaluate(unstable, "jodo1234@colorado.edu").score==0.9
end
