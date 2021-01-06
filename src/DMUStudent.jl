module DMUStudent

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

end # module
