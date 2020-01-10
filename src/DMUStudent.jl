module DMUStudent

import RedPen

export
    status,
    submit,
    evaluate,
    HW1

include("HW1.jl")

config = Dict("address"=>"submission_url",
              "port"=>8228,
              "email"=>"zachary.sunberg@colorado.edu"
             )

projects = Dict("hw1"=>HW1)

# Interface
function status(email)
    payload = Dict{String,Any}("email"=>email,
                   "project"=>"status",
                   "data"=>"",
                  )
    RedPen.Client.submit(payload, config)
end

function evaluate(submission, project::AbstractString)
    score = projects[project].evaluate(submission)
    println("Evaluation complete! Score: $score")
    return score
end

function submit(submission, project::AbstractString, email::AbstractString; nickname=email)
    score, data = projects[project].evaluate_for_submission(submission, email)
    println("Evaluation complete! Score: $score")
    payload = Dict{String,Any}("email"=>email,
                               "project"=>project,
                               "data"=>data,
                               "score"=>score,
                               "nickname"=>nickname
                              )
    RedPen.Client.submit(payload, config)
    return score
end

end # module
