# DMUStudent.jl

Julia package for students in Decision Making under Uncertainty. This package contains code needed for homeworks and submission to gradescope.

It is ok for students to examine and use any of the code in this package except for obfuscated code. Obfuscated code is hidden by default and will look like files full of numbers; *it will not be easy to accidentally see*. However a *deliberate* attempt to de-obfuscate this code or look inside it using another tool will be considered a violation of the Honor Code.

## Installation and Testing

### Installation

In Julia, run

```julia
using Pkg
pkg"registry add https://github.com/JuliaRegistries/General" # this might take a while
pkg"registry add https://github.com/sisl/Registry" # for the Obfuscatee.jl package
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

## Homework code

Homework code is contained in submodules, for example to import all functions needed to complete homework 1, run
```julia
using DMUStudent.HW1
```
### Submitting json results from the evaluate function

Each homework module has an `evaluate` function that will be used for the challenge problems. The first argument is the submission required by the homework, and the second argument is the email that you used to register for gradescope. For example, on homework 1, you might call:
```julia
f(x, y) = x+y
HW1.evaluate(f, "your.email@colorado.edu)
```
This will produce a [json file](https://en.wikipedia.org/wiki/JSON) (`results.json` by default) that can be submitted to gradescope.

For some homeworks, the `evaluate` function may have keyword arguments. These can be accessed through julia's built in help, i.e. with `?HW1.evaluate`.

### Starter code

"Starter code" that shows how to get started on the homeworks is not part of this package. See Canvas for links to starter code.

## FAQ

### Where is this code located on my machine?

You should not ever need to edit the code in this package. The easiest way to look at the code is on github. On your machine, a copy will be located in `~/.julia/packages/DMUStudent`, but you should not edit this copy.
