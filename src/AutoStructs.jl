module AutoStructs

export @autostruct

"""
    @autostruct <constructor>


This is a macro for easily defining new types, creating a struct out of a well-formed constructor function.

`@autostruct` is Revise-friendly, so you can modify the constructor function 
and re-run the macro to update the struct definition without restarting Julia.   

# Usage

The following code
```julia
using AutoStructs, Random

@autostruct function Linear(din::Int, dout::Int)
    W = randn(dout, din)
    b = zeros(dout)
    σ = tanh
    return Linear(W, b, σ) # The last line defines the struct fields
end
```
translates to
```julia
struct var"##Linear#232"{T1, T2, T3}
    W::T1
    b::T2
    σ::T3
end

Linear = var"##Linear#230"

function Linear(din::Int, dout::Int)
    W = randn(dout, din)
    b = zeros(dout)
    σ = tanh
    return Linear(W, b, σ)
end
```
After this, you can use `Linear` as a type, and `Linear(din, dout)` as a constructor: 
```julia
julia> Linear
var"##Linear#230"

julia> lin = Linear(2,3)
Linear(...)
```
"""
macro autostruct(ex)
    esc(_autostruct(ex))
end

const DEFINE = Dict{Expr, Tuple}()

function _autostruct(expr)
    Meta.isexpr(expr, :function) || throw("Expected a function definition, like `@autostruct function MyStruct(...); ...`")
    fun = expr.args[1].args[1]
    ret = expr.args[2].args[end]
    if Meta.isexpr(ret, :return)
        ret = only(ret.args)
    end
    Meta.isexpr(ret, :call) || throw("Last line of `@autostruct function $fun` must return `$fun(field1, field2, ...)`")
    ret.args[1] === fun || throw("Last line of `@autostruct function $fun` must return `$fun(field1, field2, ...)`")
    for ex in ret.args
        ex isa Symbol || throw("Last line of `@autostruct function $fun` must return `$fun(field1, field2, ...)` with only symbols, got $ex")
    end
    name, defex = get!(DEFINE, ret) do  # If we've seen same `ret` before, get it from dict
        str = "$fun(...)"
        name = gensym(fun)
        fields = map(enumerate(ret.args[2:end])) do (i, field)
            type = Symbol("T#", i)
            :($field::$type)
        end
        types = map(f -> f.args[2], fields)
        ex = quote
            struct $name{$(types...)}
                $(fields...)
            end
            $Base.show(io::IO, _::$name) = $print(io, $str)
            $fun = $name
        end
        (name, ex)
    end
    expr.args[1].args[1] = name  # this is the generated struct name
    # newret = deepcopy(ret)
    # newret.args[1] = name
    # expr.args[2].args[end] = newret
    quote
        $(defex.args...)  # struct definition
        $expr  # constructor function
    end
end

end # module
