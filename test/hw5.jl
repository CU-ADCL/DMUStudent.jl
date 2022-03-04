@testset "HW5" begin
    using DMUStudent.HW5: mc
    using CommonRLInterface
    using Compose
    using Random: MersenneTwister

    easier_env = Wrappers.QuickWrapper(mc,
        actions = [-1.0, 0.0, 1.0],
        observe = env->observe(env)[1:2]
    )

    @testset "Check consistency of rng in evaluation" begin
        rng = MersenneTwister(3)
        env1 = HW5.MountainCar(;rng=rng)
        rng2 = MersenneTwister(3)
        env2 = HW5.MountainCar(;rng=rng2)

        @test observe(env1) == observe(env2)

        for _ in 1:10
            act!(env1, 1.0)
            act!(env2, 1.0)
        end
        @test observe(env1) == observe(env2)

        reset!(env1)
        reset!(env2)

        @test observe(env1) == observe(env2)
    end

    @testset "observe before reset" begin
        @test observe(easier_env) isa AbstractArray
    end

    @testset "easier_env" begin
        @test mc isa AbstractEnv
        A = actions(easier_env)
        done = false
        rsum = 0.0
        reset!(easier_env)
        s = observe(easier_env)
        t = 1
        γ = 0.95
        max_t = 200
        while t <= max_t && !terminated(easier_env)
            a = rand(A)
            
            r = act!(easier_env, a)
            sp = observe(easier_env)
           
            rsum += γ^t*r
            
            s = sp
            t += 1
        end
        @test -5.0 <= rsum <= 15000.0
    end

    @testset "rendering" begin
        rndr = render(easier_env)
        @test rndr isa Context
        sprint((io, x)->show(io, MIME("text/html"), x), rndr)
    end

    @testset "evaluate" begin
        @test HW5.evaluate(s->0.0, n_episodes=10).score < 0.0
        @test HW5.evaluate(s->0.0, "zachary.sunberg@colorado.edu", n_episodes=10).score < 0.0
        @test HW5.evaluate(s->rand(actions(easier_env)), "zachary.sunberg@colorado.edu", n_episodes=10).score < 0.0

        energy(s) = sign(s[2])
        @test HW5.evaluate(energy).score > 0.0
        @test HW5.evaluate(energy, "zachary.sunberg@colorado.edu").score > 0.0
    end

    @testset "sufficient energy" begin
        disc = 1.0
        rsum = 0.0
        mc.s = [1.56, 0.0]
        while !terminated(mc) && disc > 0.001
            r = act!(mc, -1.0)
            rsum += disc*r
            disc *= 0.99
        end
        @test rsum > 200.0

        disc = 1.0
        rsum = 0.0
        mc.s = [1.4, 0.0]
        while !terminated(mc) && disc > 0.001
            r = act!(mc, -1.0)
            rsum += disc*r
            disc *= 0.99
        end
        @test rsum < 0.0
    end

    @testset "completion" begin
        disc = 1.0
        rsum = 0.0
        reset!(mc)
        deleteat!(mc.veuxjs, 1:length(mc.veuxjs))
        r = act!(mc, -1.0)
        @test r > 10000
        @test mc.gameover == true

        reset!(mc)
        mc.s = [1.0, 0.0]
        act!(mc, 0.0)
        @test mc.nar.centerx < 200-9
        @test mc.nar.right < 200
        mc.s = [-1.0, 0.0]
        act!(mc, 0.0)
        @test mc.nar.centerx > 9
        @test mc.nar.left > 0
    end
end
