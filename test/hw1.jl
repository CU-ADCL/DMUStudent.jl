@testset "HW1" begin
    using DMUStudent.HW1
    @test 1 <= fx([2]) <= 4
    @test 1 <= fy([2]) <= 4
    @test 1 <= fy([1, 2, 4]) <= 7

    f(x, y) = sqrt(x^2 + y^2)
    results = HW1.evaluate(f, "test1234@colorado.edu")
    @test results.score == 1

    results = HW1.evaluate(f)
    @test results.score == 1

    g(x, y) = x+y
    results = HW1.evaluate(g, "test1234@colorado.edu")
    @test results.score == 0
end
