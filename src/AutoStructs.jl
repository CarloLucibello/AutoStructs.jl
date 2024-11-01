module AutoStructs

export @autostruct

"""
    @autostruct function MyType(d); ...; MyType(f1, f2, ...); end

This is a macro for easily defining new types.

Typically the steps to define a new `struct` are:
1. Define a `struct MyType` with the desired fields.
2. Define a constructor function like `MyType(arg1, arg2, ...)`,
   which initialises the fields.

This macro combines these steps into one, by taking the construcor definition
of step 2 and using the return line to automatically define the `struct`.

Moreover, if you change the name or types of the fields, 
then the `struct` definition is automatically replaced.
This works because this definition uses an auto-generated name, which is `== MyType`.
(But existing instances of the old `struct` are not changed in any way!)
Thanks to this, you can easily experiment with different field names and types, 
overcoming a major limitation of a Revise.jl workflow.

## Examples

```julia
@autostruct function Layer(din::Int, dout::Int)
    weight = randn(dout, din)
    bias = zeros(dout)
    return Layer(weight, bias)
end

layer = Layer(2, 4)
layer isa Layer  # true
```

The `struct` defined by the macro here is something like this:

```julia
struct MyModel001{T1, T2}
  weight::T1
  bias::T2
end
```

Since this can hold any objects, even `MyModel("hello", "world")`.
As you can see by looking `methods(MyModel)`, there should never be an ambiguity
between the `struct`'s own constructor, and your `MyModel(d::Int)`.

You can also restrict the types allowed in the struct:
```
@autostruct function MyOtherModel(d1, d2, act=identity)
  gamma = Embedding(128 => d1)
  delta = Dense(d1 => d2, act)
  MyOtherModel(gamma::Embedding, delta::Dense)  # struct will only hold these types
end
```

This creates a struct like this:

```julia
struct MyOtherModel001{T1 <: Embedding, T2 <: Dense}
  gamma::T1
  delta::T2
end
```

"""
macro autostruct(ex)
    esc(_autostruct(ex))
end

const DEFINE = Dict{UInt, Tuple}()

function _autostruct(expr)
    # Check first & last line of the input expression:
    Meta.isexpr(expr, :function) || throw("Expected a function definition, like `@autostruct function MyStruct(...); ...`")
    fun = expr.args[1].args[1]
    ret = expr.args[2].args[end]
    if Meta.isexpr(ret, :return)
        ret = only(ret.args)
    end
    Meta.isexpr(ret, :call) || throw("Last line of `@autostruct function $fun` must return `$fun(field1, field2, ...)`")
    ret.args[1] === fun || throw("Last line of `@autostruct function $fun` must return `$fun(field1, field2, ...)`")
    for ex in ret.args
        ex isa Symbol && continue
        Meta.isexpr(ex, :(::)) && continue
        throw("Last line of `@autostruct function $fun` must return `$fun(field1, field2, ...)` or `$fun(field1::T1, field2::T2, ...)`, but got $ex")
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
        
        str = "$fun(...)"
        ex = quote
            struct $name{$(types...)}
                $(fields...)
            end
            $Base.show(io::IO, _::$name) = $print(io, $str)
            $Base.show(io::IO, ::MIME"text/plain", x) = $prettyprint(io, $fun, x)
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


function prettyprint(io::IO, name, x)
    print(io, "$name", nt(x))
end

function nt(x::T) where T
    (; (f => getfield(x, f) for f in fieldnames(T))...)
end

end # module
