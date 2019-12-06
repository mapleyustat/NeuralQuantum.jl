export Dense, WSum

struct Dense{Ta,Tb,C}
    W::Ta
    b::Tb
    σ::C
end
functor(d::Dense) = (W=d.W, b=d.b), (W,b) -> Dense(W,b,d.σ)
(l::Dense)(x) = l.σ.(l.W*x .+ l.b)

Dense(in::Integer, args...;kwargs...)= Dense(Complex{STD_REAL_PREC}, in, args...;kwargs...)
function Dense(T::Type, in::Integer, out::Integer, σ = identity;
               initW = glorot_uniform, initb = glorot_uniform)
  return Dense(initW(T, out, in), initb(T, out), σ)
end

struct DenseCache{Ta,Tb,Tc,Td}
    σ::Tc
    out::Tb
    δℒℒ::Td

    θ::Ta
    out2::Tb
    valid::Bool
end

function cache(l::Dense{Ta,Tb}, arr_T, in_T, in_sz) where {Ta,Tb}
    c = DenseCache(similar(l.W, size(l.W,2)),
               similar(l.b),
               similar(l.W, size(l.W,1)),
               similar(l.b),
               similar(l.b),
               false)
    return c
end

function layer_out_type_size(l::Dense, in_T ,in_sz)
    T1     = promote_type(in_T, eltype(l.W))
    out_T  = promote_type(T1, eltype(l.b))
    out_sz = size(l.b)
    return out_T, out_sz
end

function (l::Dense)(c::DenseCache, x)
    # The preallocated caches
    logℒθ  = c.out
    θ = c.θ

    # Store the input to this layer for the backpropagation
    σ = copyto!(c.σ, x)

    #θ .= net.b .+ net.W * x
    mul!(θ, l.W, σ)
    θ .+= l.b

    # Apply the nonlinear function
    logℒθ  .= l.σ.(θ)
    return logℒθ
end

function backprop(∇, l::Dense, c::DenseCache, δℒ)
    # The preallocated caches
    θ = c.θ
    δℒℒ = c.δℒℒ

    # Compute the actual sensitivity
    copyto!(δℒℒ, δℒ)
    δℒℒ .*= fwd_der.(l.σ, θ)

    ∇.W .= δℒℒ.*transpose(c.σ)
    ∇.b .= δℒℒ

    return transpose(δℒℒ)*l.W
end
