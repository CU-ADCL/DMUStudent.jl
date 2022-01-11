module HW1

using ..Obfuscatee
using Nettle: hexdigest
import JSON
using Test: @inferred

import DMUStudent

# mostly to get binaries to recompile
version = v"3.0.0"

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
