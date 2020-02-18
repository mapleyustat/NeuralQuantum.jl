const jlAState{T} = JLArray{T,1}
const jlAStateBatch{T} = JLArray{T,2}
const jlAStateBatchVec{T} = JLArray{T,3}


function build_rng_generator_T(arrT::GPUArray, seed)
    c = similar(arrT)
    fill!(c, seed)
    return GPUArrays.global_rng(c)
end

@inline unsafe_get_el(σ::gpuAStateBatchVec, i) =
    view(σ, :, :, i)
@inline unsafe_get_el(σ::gpuAStateBatchVec, batch, el) =
    view(σ, :, batch, el)