struct Measurement
    mean
    error

    variance
    tau
    R
end

value(x::Measurement)       = x.mean
Statistics.mean(x::Measurement) = x.mean
uncertainty(x::Measurement) = x.error
Base.real(x::Measurement) = Measurement(real(x.mean), x.error, x.variance, x.tau, x.R)
Base.imag(x::Measurement) = Measurement(imag(x.mean), x.error, x.variance, x.tau, x.R)

Measurement(x::Measurement) = copy(x)

Base.copy(x::Measurement) =
    Measurement(x.mean, x.error, x.variance, x.tau, x.R)


stat_analysis(vals::AbstractMatrix, par_data::NotParallel) =
    _single_stat_analysis(vals)


function _single_stat_analysis(vals::AbstractMatrix)
    tmp = similar(vals, size(vals, 1))
    n    = size(vals, 1)
    L    = size(vals, 2)

    tmp = similar(vals, size(vals, 1))

    μ_chains = mean!(tmp, vals)
    μ        = mean(μ_chains)

    var_chains = var(vals, dims=2, mean=μ_chains)
    var_μ_ch   = var(μ_chains)
    var_μ      = var(vals, mean=μ)


    μ_err = sqrt(var_μ_ch/n)
    μ_var = mean(var_chains)

    t = var_μ_ch/var_μ
    corr = max(0.0, 0.5 * ( t * L - 1))
    R = sqrt((L-1)/L + t)

    return Measurement(μ,
            μ_err, μ_var, corr, R)
end

function stat_analysis(vals::AbstractMatrix, par_data)
    tmp = similar(vals, size(vals, 1))
    n    = size(vals, 1)
    L    = size(vals, 2)

    tmp = similar(vals, size(vals, 1))
    #println("Stat $(Threads.threadid())")

    μ_chains = mean!(tmp, vals)
    μ        = workers_mean(μ_chains, par_data)

    var_chains = var(vals, dims=2, mean=μ_chains)
    var_μ_ch   = var(μ_chains)
    var_μ      = var(vals, mean=μ)


    μ_err = sqrt(var_μ_ch/n)
    μ_var = mean(var_chains)

    t = var_μ_ch/var_μ
    corr = max(0.0, 0.5 * ( t * L - 1))
    R = sqrt((L-1)/L + t)

    return Measurement(μ,
            μ_err, μ_var, corr, R)
end


Base.show(io::IO, ::MIME"text/plain", v::Measurement) =
    print(io, _meas_to_str(v))

Base.show(io::IO, v::Measurement) =
    print(io, _meas_to_str(v))

function _meas_to_str(v)
    μ = v.mean
    if μ isa Complex
        sgn = sign(imag(μ)) == 1 ? "+" : "-"
        μs = @sprintf "%6.4f %s %6.4f im" real(μ) sgn abs(imag(μ))
    else
        μs = @sprintf "%6.4f" real(μ)
    end

    @sprintf "(%s) ± %6.4f [var=%6.4f, tau=%6.4f, R=%6.4f]" μs v.error v.variance v.tau v.R
end
