module DMUStudent

import RedPen

export
    status,
    submit,
    evaluate,
    HW1

include("HW1.jl")

config = Dict("address"=>"dmuleaderboard.com",
              "port"=>8228,
              "email"=>"zachary.sunberg@colorado.edu"
             )

projects = Dict("hw1"=>HW1)

"""
    status(email)

Check the status of submissions on dmuleaderboard.com for a given email.

# Arguments
- `email::String`: email of a student specified as a string.
"""
function status(email)
    payload = Dict{String,Any}("email"=>email,
                   "project"=>"status",
                   "data"=>"",
                  )
    RedPen.Client.submit(payload, config)
end

"""
    evaluate(submission, assignment)

Evaluate a submission for a homework assignment on your local machine and print a score. This will NOT send the result to dmuleaderboard.com.

# Arguments
- `submission`: This is the object that the homework prompt asks for. It could be a function, vector, string, or some other data. See the homework starter code for examples.
- `assignment::String`: A string indicating which assignment this is for, e.g. `"hw1"`
"""
function evaluate(submission, project::AbstractString)
    score = projects[project].evaluate(submission)
    println("Evaluation complete! Score: $score")
    return score
end

"""
    submit(submission, assignment, email; [nickname=email])

Evaluate a submission for a homework assignment on your local machine and submit it to dmuleaderboard.com.

# Positional Arguments
- `submission`: This is the object that the homework prompt asks for. It could be a function, vector, string, or some other data. See the homework starter code for examples.
- `assignment::String`: A string indicating which assignment this is for, e.g. `"hw1"`
- `email::String`: email of a student specified as a string.

# Keyword Arguments
- `nickname::String`: A nickname to be displayed on the scoreboard instead of your email. If none is supplied your email will be used.

# Example
```
using DMUStudent
f(x, y) = x+y
submit(f, "hw1", "your.email@colorado.edu", nickname="ralphie")
```
"""
function submit(submission, project::AbstractString, email::AbstractString; nickname="I forgot to change the default nickname 🤦")
    if !is_identikey_colorado_email(email)
        error("You must use your indentikey@colorado.edu email address. Your identikey is four letters followed by four numbers.")
    end

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

is_identikey_colorado_email(email) = !isnothing(match(r"^[a-z]{4}\d{4}@colorado.edu$", email))

end # module
