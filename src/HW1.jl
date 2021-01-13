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

evaluate = @binclude(".bin/hw1_eval")

end
