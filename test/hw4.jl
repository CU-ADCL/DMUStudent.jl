@testset "HW4" begin
    using DMUStudent
    using DMUStudent.HW4
    using POMDPPolicies
    using RLInterface
    using Compose

    # Q learning loop for gw
    A = actions(gw)
    done = false
    rsum = 0.0
    s = reset!(gw)
    t = 1
    γ = 0.95
    max_t = 200
    while t <= max_t
        a = rand(A)
        
        sp, r, done, info = step!(gw, a)
       
        rsum += γ^t*r
        
        if done
            break
        end
        
        s = sp
        t += 1
    end
    @test -10.0 <= rsum <= 10.0

    # rendering gw
    @test RLInterface.render(gw, policy=FunctionPolicy(s->:left)) isa Context
   
    # evaluation
    score, data = HW4.evaluate_for_submission(s->1.0, "test1234@colorado.edu")
    @test score < 0.0
    score, data = HW4.evaluate_for_submission(FunctionPolicy(s->1.0), "test1234@colorado.edu")
    @test score < 0.0

    score = DMUStudent.evaluate(s->1.0, "hw4", n_episodes=100)
    @test score < 0.0

    @test_throws AssertionError HW4.evaluate_for_submission(s->1.0, "test1234@colorado.edu", n_episodes=100)

    # rendering mc
    @test RLInterface.render(mc) isa Context
end
