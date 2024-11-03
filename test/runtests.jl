using AutoStructs
using Test


@structdef function Linear(din::Int, dout::Int)
    W = rand(dout, din)
    b = zeros(dout)
    σ = tanh
    return Linear(W, b, σ) # The last line defines the struct fields
end

@structdef function LinearOutRestr(din, dout)
    W = rand(dout, din)
    b = zeros(dout)
    return LinearOutRestr(W::AbstractMatrix, b::AbstractVector) # The last line defines the struct fields
end

@structdef function NoArgs(; a=1, b)
    x = a+b
    y = a-b
    return NoArgs(x, y)
end
    
@testset "basic tests" begin
    linear = Linear(2, 4)
    @test linear isa Linear
    @test linear isa Linear{Matrix{Float64}, Vector{Float64}, typeof(tanh)}
    @test linear.W isa Matrix{Float64}
    @test linear.b isa Vector{Float64}
    @test linear.σ === tanh
end 

@testset "output restriction" begin
    linear = LinearOutRestr(2, 4)
    @test linear isa LinearOutRestr
    @test linear isa LinearOutRestr{Matrix{Float64}, Vector{Float64}}
    @test linear.W isa Matrix{Float64}
    @test linear.b isa Vector{Float64}
end 

@testset "keyword constructor" begin
    linear = Linear(W=rand(4, 2), b=zeros(4), σ=tanh)
    @test linear isa Linear

    noargs = NoArgs(a = 3, b = 4)
    @test noargs isa NoArgs
    @test noargs.x == 7
    @test noargs.y == -1
end
