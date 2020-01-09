module DMUStudent

import RedPen

export
    status,
    HW1

config = Dict("address"=>"submission_url",
              "port"=>8228,
              "email"=>"zachary.sunberg@colorado.edu"
             )

# Interface
function status(email)
    payload = Dict{String,Any}("email"=>email,
                   "project"=>"status",
                   "data"=>"",
                  )
    RedPen.Client.submit(payload, config)
end

function submit(data, project::AbstractString, email; nickname=email)
    error("submission has not been set up in this version")
end

include("HW1.jl")


end # module
