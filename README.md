# DMUStudent.jl

Julia package for students in Decision Making under Uncertainty. This package contains code needed for homeworks and submission to the leaderboard at http://dmuscoreboard.com.

It is ok for students to examine and use any of the code in this package EXCEPT FOR THE OBFUSCATED CODE. Obfuscated code is hidden by default and will look like files full of numbers; it will not be easy to accidentally see. Any deliberate attempt to de-obfuscate this code or look inside it using another tool will be considered a violation of the Honor Code.

## Installation and Testing

### Installation

In Julia, run

```julia
using Pkg
pkg"update"
pkg"registry add https://github.com/sisl/Registry"
pkg"add https://github.com/zsunberg/DMUStudent.jl"
```

### Updating

Students should always use the latest version. To get the latest version, use
```julia
using Pkg; pkg"update"
```

### Testing

Tests for the package can be run with:
```julia
using Pkg; pkg"test DMUStudent"
```

To test that the package can communicate with the server at `dmuscoreboard.com`, run
```julia
using DMUStudent; status("your.email@colorado.edu")
```
If it prints something about no entry for hw1, it has communicated successfully.

## Interface

The package has three functions, `status`, `evaluate`, and `submit`. Use the built-in julia help, e.g.
```julia
julia> using DMUStudent
# press ? to get the help prompt
help?> submit
```

## Homework code

Homework code is contained in submodules, for example to import all functions needed to complete homework 1, run
```julia
using DMUStudent.HW1
```

### Starter code

"Starter code" that shows how to get started on the homeworks is not part of this package. See Canvas for links to starter code.

## FAQ

### Where is this code located on my machine?

You should not ever need to edit the code in this package. The easiest way to look at the code is on github. On your machine, a copy will be located in `~/.julia/packages/DMUStudent`, but you should not edit this copy.
