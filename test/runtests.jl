using AutoStructs
using Test

@testset "AutoStructs.jl" begin
    
end

using AutoStructs, Random

@autostruct function Linear(din::Int, dout::Int)
    W = randn(dout, din)
    b = zeros(dout)
    σ = tanh
    return Linear(W, b, σ) # The last line defines the struct fields
end