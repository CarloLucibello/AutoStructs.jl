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

    
@testset "basic tests" begin
    linear = Linear(2, 4)
    @test linear isa Linear
    @test linear isa Linear{Matrix{Float64}, Vector{Float64}, typeof(tanh)}
    @test linear.W isa Matrix{Float64}
    @test linear.b isa Vector{Float64}
    @test linear.σ === tanh
end 


@testset "output restiction" begin
    linear = LinearOutRestr(2, 4)
    @test linear isa LinearOutRestr
    @test linear isa LinearOutRestr{Matrix{Float64}, Vector{Float64}}
    @test linear.W isa Matrix{Float64}
    @test linear.b isa Vector{Float64}
end 



