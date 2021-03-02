@testset "HW5" begin
    using DMUStudent.HW5: mc
    using CommonRLInterface
    using Compose

    @test mc isa AbstractEnv

    A = actions(mc)
    done = false
    rsum = 0.0
    reset!(mc)
    s = observe(gw)
    t = 1
    γ = 0.95
    max_t = 200
    while t <= max_t && !terminated(mc)
        a = rand(A)
        
        r = act!(mc, a)
        sp = observe(mc)
       
        rsum += γ^t*r
        
        s = sp
        t += 1
    end
    @test -5.0 <= rsum <= 1000.0

    # rendering
    rndr = render(mc)
    @test rndr isa Context
    sprint((io, x)->show(io, MIME("text/html"), x), rndr)

    @test HW5.evaluate(s->0.0).score < 0.0
    @test HW5.evaluate(s->0.0, "zachary.sunberg@colorado.edu").score < 0.0
    @test HW5.evaluate(s->rand(actions(mc)), "zachary.sunberg@colorado.edu").score < 0.0

    # test whether it has enough energy
    disc = 1.0
    rsum = 0.0
    mc.s = [1.5, 0.0]
    while !terminated(mc) && disc > 0.005
        r = act!(mc, -1.0)
        rsum += disc*r
        disc *= 0.99
    end
    @test rsum > 200.0
end
