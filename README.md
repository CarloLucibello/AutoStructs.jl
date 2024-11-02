# AutoStructs

[![Build Status](https://github.com/CarloLucibello/AutoStructs.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/CarloLucibello/AutoStructs.jl/actions/workflows/CI.yml?query=branch%3Amain)

This package provides the macro `@structdef` to automatically define a struct with a given name and fields. 

# Usage
```julia
julia> using AutoStructs, Random

julia> @structdef function Layer(din::Int, dout::Int)
           weight = randn(dout, din)
           bias = zeros(dout)
           return Layer(weight, bias)
       end
var"##Layer#230"

julia> layer = Layer(2, 4)
Layer(weight = [-1.422950752982445 1.6242590842562115; -1.3393896739857631 0.8191382347282851; 0.3944420481119003 0.5955417101440335; 1.3944705999832914 1.1224997165166155], bias = [0.0, 0.0, 0.0, 0.0])

julia> layer isa Layer
true

julia> typeof(layer) # Layer is an alias for var"##Layer#230"
var"##Layer#230"{Matrix{Float64}, Vector{Float64}}

julia> layer isa Layer{Matrix{Float64}, Vector{Float64}} # Layer is a parametric type
true

# You can redefine the struct without restarting the REPL
julia> @structdef function Layer(din::Int, dout::Int, activation = identity)
           weight = randn(dout, din)
           bias = zeros(dout)
           return Layer(weight, bias, activation)
       end
var"##Layer#231"

julia> layer = Layer(2, 4, relu)
Layer(weight = [-0.7682741444223932 0.6155740231067407; -1.506126153999598 -0.7804554207069556; -0.10944649893432226 1.782291543052865; 0.26095648405623756 1.7713201612872245], bias = [0.0, 0.0, 0.0, 0.0], activation = tanh)

# Define methods for the struct
julia> predict(l::Layer, x) = l.activation.(l.weight * x .+ l.bias)
predict (generic function with 1 method)
```
# Documentation
Below is the docstring for the `@structdef` macro:
```
"""
    @structdef function MyType(args...; kws...); ...; return MyType(f1, f2, ...); end

This is a macro for easily defining new types.

Typically the steps to define a new `struct` are:
1. Define a `struct MyType` with the desired fields.
2. Define a constructor function like `MyType(arg1, arg2, ...)`,
   which initialises the fields.

This macro combines these steps into one, by taking the constructor definition
of step 2 and using the return line to automatically infer the field names 
and define the `struct`.

Moreover, if you change the name or types of the fields, 
then the `struct` definition is automatically replaced.
This works because this definition uses an auto-generated name, which is `== MyType`.
Thanks to this, you can easily experiment with different field names and types, 
overcoming a major limitation of a Revise.jl workflow.

## Examples

```julia
@structdef function Layer(din::Int, dout::Int)
    weight = randn(dout, din)
    bias = zeros(dout)
    return Layer(weight, bias)
end

layer = Layer(2, 4)
layer isa Layer  # true
```

The `@structdef` definition above is equivalent to the following code:

```julia
struct Layer001{T1, T2}
    weight::T1
    bias::T2
end

function Layer001(din::Int, dout::Int)
    weight = randn(dout, din)
    bias = zeros(dout)
    return Layer001(weight, bias)
end

Layer = Layer001

Base.show(io::IO, x::Layer) = ... # we do some pretty printing
Base.show(io::IO, ::MIME"text/plain", x::Layer) = ... 
```

Since `Layer001{T1, T2}` can hold any objects, even `Layer("hello", "world")`, 
there should never be an ambiguity between the `struct`'s own constructor, 
and your constructor function. If the two have the same number of arguments,
you can avoid the ambiguity by using type restrictions in the input arguments
(as in the example above) or in the return line:

```
@structdef function Layer(din, dout)
    weight = randn(dout, din)
    bias = zeros(dout)
    return Layer(weight::AbstractMatrix, bias::AbstractVector)
end

layer = Layer(2, 4)
```

This creates a struct like this:

```julia
struct Layer002{T1<:AbstractMatrix, T2<:AbstractVector}
    weight::T1
    bias::T2
end
```
and reassigns `Layer = Layer002`.
"""
```


# Similar Packages

- [ProtoStructs.jl](https://github.com/BeastyBlacksmith/ProtoStructs.jl): redefine structures without restarting the REPL.
