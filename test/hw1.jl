@testset "HW1" begin
    using DMUStudent.HW1
    @test 1 <= fx([2]) <= 4
    @test 1 <= fy([2]) <= 4
    @test 1 <= fy([1, 2, 4]) <= 7

    f(x, y) = sqrt(x^2 + y^2)
    score, _ = HW1.evaluate(f, "test@colorado.edu")
    @test score == 1

    g(x, y) = x+y
    score, _  = HW1.evaluate(g, "test@colorado.edu")
    @test score == 0

    @test evaluate(f, "hw1") == 1
    @test evaluate(g, "hw1") == 0
    
    @test submit(f, "hw1", "test@colorado.edu") == 1
    sleep(0.1)
    shw1 = server_state["hw1"]
    @test shw1["email"] == "test@colorado.edu"
    @test shw1["score"] == 1
end
