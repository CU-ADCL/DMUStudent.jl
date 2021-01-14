module HW1

using Obfuscatee
using Nettle: hexdigest
import JSON

import DMUStudent

export
    fx,
    fy

# mostly to get binaries to recompile
version = v"1.0.11"

@binclude(".bin/hw1_4")

"""
    evaluate(f, [email]; fname="results.json")

Evaluate homework 1 programming assignment.

# Arguments
- `f::Function`: submitted function
- `email::String`: email of submitting student - must match gradescope email!

# Keyword Arguments
- `fname::String`: submission output file name
"""
evaluate = @binclude(".bin/hw1_eval")

end
