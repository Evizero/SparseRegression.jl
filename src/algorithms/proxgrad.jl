immutable PROXGRAD <: OfflineAlgorithm
    maxit::Int
    tol::Float64
    verbose::Bool
end
PROXGRAD(; maxit::Int = 100, tol::Float64 = 1e-6, verbose::Bool = false) = PROXGRAD(maxit, tol, verbose)
init(alg::PROXGRAD, p::Integer) = alg
is_supported(loss::Loss, pen::Penalty, alg::PROXGRAD) = true


# TODOs:
# - weights
# - penalty factor
# - line search
# - Estimate Lipschitz constant for step size?
# - Other criteria for convergence?
function fit!(o::SparseReg{PROXGRAD}, x::AMat, y::AVec, wts::AVec = zeros(0), penalty_factor::AVec = ones(0))
    n, p = size(x)
    @assert p == length(o.β)
    use_weights = length(wts) > 0
    @assert !use_weights || length(wts) == n "`weights` must have length $n"
    β, A, L, P = o.β, o.algorithm, o.loss, o.penalty

    yhat = predict(o, x)
    deriv_buffer = zeros(n)
    ∇ = zeros(p)

    oldloss = -Inf
    newloss = meanvalue(L, y, yhat)
    niters = 0
    for k in 1:A.maxit
        oldloss = newloss
        deriv_buffer .= deriv.(L, y, yhat)
        At_mul_B!(∇, x, deriv_buffer)
        scale!(∇, 1 / n)
        for j in eachindex(β)
            β[j] = prox(P, β[j] - ∇[j])
        end
        yhat = predict(o, x)
        newloss = meanvalue(L, y, yhat)
        abs(newloss - oldloss) < min(abs(newloss), abs(oldloss)) * A.tol && break
        niters += 1
        if A.verbose
            tolerance = abs(newloss - oldloss) / min(abs(newloss), abs(oldloss))
            info("Iteration: $niters, Relative Tolerance: $tolerance")
        end

    end

    tolerance = abs(newloss - oldloss) / min(abs(newloss), abs(oldloss))
    if tolerance < A.tol
        A.verbose && info("CONVERGED")
    else
        warn("DID NOT CONVERGE in $niters iterations, tolerance=$tolerance")
    end
    o
end
