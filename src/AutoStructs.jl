module AutoStructs

export @structdef

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
@kwdef struct Layer001{T1, T2}
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
@kwdef struct Layer002{T1<:AbstractMatrix, T2<:AbstractVector}
    weight::T1
    bias::T2
end
```
and reassigns `Layer = Layer002`.
"""
macro structdef(ex)
    esc(_structdef(ex))
end

const DEFINE = Dict{UInt, Tuple}()

function _structdef(expr)
    # Check first & last line of the input expression:
    Meta.isexpr(expr, :function) || throw("Expected a function definition, like `@structdef function MyStruct(...); ...`")
    fun = expr.args[1].args[1]
    ret = expr.args[2].args[end]
    if Meta.isexpr(ret, :return)
        ret = only(ret.args)
    end
    Meta.isexpr(ret, :call) || throw("Last line of `@structdef function $fun` must return `$fun(field1, field2, ...)`")
    ret.args[1] === fun || throw("Last line of `@structdef function $fun` must return `$fun(field1, field2, ...)`")
    for ex in ret.args
        ex isa Symbol && continue
        Meta.isexpr(ex, :(::)) && continue
        throw("Last line of `@structdef function $fun` must return `$fun(field1, field2, ...)` or `$fun(field1::T1, field2::T2, ...)`, but got $ex")
    end

    # If the last line is new, construct struct definition:
    name, defex = get!(DEFINE, hash(ret)) do
        name = gensym(fun)
        fields = map(enumerate(ret.args[2:end])) do (i, ex)
            field = ex isa Symbol ? ex : ex.args[1]  # we allow `return MyModel(alpha, beta::Chain)`
            type = Symbol("T#", i)
            :($field::$type)
        end
        types = map(fields, ret.args[2:end]) do ft, ex
            if ex isa Symbol  # then no type spec on return line
                ft.args[2]
            else
                Expr(:(<:), ft.args[2], ex.args[2])
            end
        end
        
        strfun = "$fun"
        ex = quote
            @kwdef struct $name{$(types...)}
                $(fields...)
            end
            $Base.show(io::IO, x::$name) = $printinline(io, $strfun, x)
            $Base.show(io::IO, ::MIME"text/plain", x::$name) = $printplain(io, $strfun, x)
            # $Base.show(io::IO, T::Type{$name}) = printtype(io, $strfun, T)
            $fun = $name
        end
        (name, ex)
    end

    # Change first line to use the struct's name:
    expr.args[1].args[1] = name
    quote
        $(defex.args...)  # struct definition
        $expr  # constructor function
    end
end

function printinline(io::IO, name, x)
    print(io, "$name")
    show(io, nt(x))
end

function printplain(io::IO, name, x)
    print(io, "$name")
    show(io, "text/plain", nt(x))
end

function nt(x::T) where T
    (; (f => getfield(x, f) for f in fieldnames(T))...)
end

end # module
