@testset "HW1" begin
    using DMUStudent.HW1
    @test 1 <= fx([2]) <= 4
    @test 1 <= fy([2]) <= 4
    @test 1 <= fy([1, 2, 4]) <= 7

    @test titanic isa DataFrame
end
