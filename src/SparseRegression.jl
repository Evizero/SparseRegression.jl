module SparseRegression

import StatsBase: coef, predict, zscore, fit!, loglikelihood
import StandardizedMatrices; SM = StandardizedMatrices
import Distributions; Ds = Distributions
import StatsBase

export
    SparseReg,
    Penalty, NoPenalty, RidgePenalty, LassoPenalty, ElasticNetPenalty, SCADPenalty,
    LinearRegression, L1Regression, LogisticRegression, SVMLike, QuantileRegression,
    HuberRegression, PoissonRegression, Model,
    Algorithm, Fista, Sweep, Prox,
    coef, predict, fit!, loglikelihood, loss, sweep!, penalty, prox, prox!, classify

#-----------------------------------------------------------------------------# types
typealias VecF Vector{Float64}
typealias MatF Matrix{Float64}
typealias AVec{T} AbstractVector{T}
typealias AMat{T} AbstractMatrix{T}
typealias AVecF AVec{Float64}
typealias AMatF AMat{Float64}

abstract Algorithm
Base.show(io::IO, o::Algorithm) = print(io, replace(string(typeof(o)), "SparseRegression.", ""))

#--------------------------------------------------------------------------# printing
print_header(io::IO, s::AbstractString) = println(io, "■ $s")
function print_item(io::IO, name::AbstractString, value)
    println(io, "  >" * @sprintf("%14s", name * ":  "), value)
end


#----------------------------------------------------------------------# source files
include("penalty.jl")
include("model.jl")
include("sparsereg.jl")
include("algorithms/fista.jl")
include("algorithms/sweep.jl")
include("algorithms/coordinate_descent.jl")
include("plots.jl")

end # module
