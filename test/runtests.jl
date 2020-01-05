using DMUStudent
using Test
using RedPen
using RedPen.Server

server_state = Dict{String, Any}("status request"=>nothing)

callbacks = Dict("status"=>function (payload)
                     server_state["status request"] = payload
                     return "Success"
                 end
                )

test_server_config = Dict("address"=>"127.0.0.1",
              "port"=>8228,
              "email"=>"zachary.sunberg@colorado.edu")

@async listen(callbacks, test_server_config)

DMUStudent.config["address"] = "127.0.0.1"

@testset "status" begin
    status("student@colorado.edu")
    sleep(0.1)
    sr = server_state["status request"]
    @test sr["email"] == "student@colorado.edu"
    @test sr["project"] == "status"
end
