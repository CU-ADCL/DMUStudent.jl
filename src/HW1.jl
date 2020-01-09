module HW1

using Obfuscatee
using CSV

export
    fx,
    fy,
    titanic

# mostly to get binaries to recompile
version = v"0.1.2"

@binclude(".bin/hw1_4")

titanic = CSV.read("../data/titanic.csv")

end
