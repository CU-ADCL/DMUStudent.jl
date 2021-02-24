@testset "HW4" begin
    using DMUStudent.HW4: gw
    using CommonRLInterface
    using Compose

    A = actions(gw)
    done = false
    rsum = 0.0
    reset!(gw)
    s = observe(gw)
    t = 1
    γ = 0.95
    max_t = 200
    while t <= max_t && !terminated(gw)
        a = rand(A)
        
        r = act!(gw, a)
        sp = observe(gw)
       
        rsum += γ^t*r
        
        s = sp
        t += 1
    end
    @test -12.0 <= rsum <= 10.0

    # rendering gw
    rndr = HW4.render(gw, color=s->10.0*rand(), policy=s->rand(A))
    @test rndr isa Context
    sprint((io, x)->show(io, MIME("text/html"), x), rndr)

    rndr = HW4.render(gw)
    @test rndr isa Context
    sprint((io, x)->show(io, MIME("text/html"), x), rndr)
end
