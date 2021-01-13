using DMUStudent
using Test
using DataFrames
import JSON

@testset "email check" begin
    @test DMUStudent.is_identikey_colorado_email("zasu3213@colorado.edu")
    @test !DMUStudent.is_identikey_colorado_email("zachary.sunberg@colorado.edu")
    @test !DMUStudent.is_identikey_colorado_email("sunbergzach@gmail.com")
end

include("hw1.jl")
# include("hw2.jl")
# include("hw3.jl")
# include("hw4.jl")
# include("hw6.jl")
