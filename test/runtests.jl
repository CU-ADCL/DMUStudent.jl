using DMUStudent
using Test
import RedPen
using RedPen.Server
using DataFrames

server_state = Dict{String, Any}()

function store_payload(p)
    server_state[p["project"]] = p
    return "Success"
end

callbacks = Dict("status"=>store_payload,
                 "hw1"=>store_payload
                )

test_server_config = Dict("address"=>"127.0.0.1",
              "port"=>8228,
              "email"=>"zachary.sunberg@colorado.edu")

@async RedPen.Server.listen(callbacks, test_server_config)
sleep(1)

DMUStudent.config["address"] = "127.0.0.1"

@testset "status" begin
    status("student@colorado.edu")
    sleep(0.1)
    sr = server_state["status"]
    @test sr["email"] == "student@colorado.edu"
    @test sr["project"] == "status"
end

include("hw1.jl")
