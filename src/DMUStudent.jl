module DMUStudent

using Nettle: hexdigest

export
    # HW1,
    # HW2,
    HW3
    # HW4,
    # HW6

# include("HW1.jl")
# include("HW2.jl")
include("HW3.jl")
# include("HW4.jl")
# include("HW6.jl")

is_identikey_colorado_email(email) = !isnothing(match(r"^[a-z]{4}\d{4}@colorado.edu$", email))

function encode_score(email, score, key)
    @assert is_identikey_colorado_email(email)
    return hexdigest("sha256", email*string(score)*key)
end

end # module
