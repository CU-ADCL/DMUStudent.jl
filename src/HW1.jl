module HW1

using Obfuscatee
using CSV
using Nettle
using JSON

export
    fx,
    fy

# mostly to get binaries to recompile
version = v"0.1.3"

@binclude(".bin/hw1_4")

evaluate = evaluate_for_submission = @binclude(".bin/hw1_eval")

end
