module DMUStudent

using Nettle: hexdigest

include("Obfuscatee.jl")

export HW1,
       HW2,
       HW3,
       HW4,
       HW5,
       HW6


include("HW1.jl")
include("HW2.jl")
include("HW3.jl")
include("HW4.jl")
include("HW5.jl")
include("HW6.jl")


@deprecate hash_score(hw, email, score, key) hexdigest("sha256", string(hw)*email*string(score)*key)

end # module
