module SparseRegression

using Reexport
@reexport using LearnBase
@reexport using LossFunctions
@reexport using PenaltyFunctions
importall LossFunctions
import SweepOperator
import StatsBase: predict, coef

export
    SparseReg, SolutionPath, predict, coef,
    # algorithms
    ProxGrad,
    # Model typealiases
    LinearRegression, L1Regression, LogisticRegression, PoissonRegression, HuberRegression, SVMLike, DWDLike, QuantileRegression


#---------------------------------------------------------------------------------# types
AVec        = AbstractVector
AMat        = AbstractMatrix
AVecF       = AbstractVector{Float64}
AMatF       = AbstractMatrix{Float64}
VecF        = Vector{Float64}
MatF        = Matrix{Float64}
AverageMode = LossFunctions.AverageMode

LinearRegression      = LossFunctions.ScaledDistanceLoss{L2DistLoss,0.5}
L1Regression          = L1DistLoss
LogisticRegression    = LogitMarginLoss
PoissonRegression     = PoissonLoss
HuberRegression       = HuberLoss
SVMLike               = L1HingeLoss
QuantileRegression    = QuantileLoss
DWDLike               = DWDMarginLoss


abstract Algorithm
abstract OfflineAlgorithm   <: Algorithm
abstract OnlineAlgorithm    <: Algorithm
Base.show(io::IO, a::Algorithm) = print(io, name(a))

#----------------------------------------------------------------------# SparseReg
immutable SparseReg{A <: Algorithm, L <: Loss, P <: Penalty}
    β::VecF
    loss::L
    penalty::P
    algorithm::A
    λ::Float64
    factor::VecF
end
function SparseReg(p::Integer, l::Loss, r::Penalty, a::Algorithm, λ::Float64, factor::VecF)
    SparseReg(zeros(p), l, r, a, λ, factor)
end

# TODO: add type stable version
function SparseReg(p::Integer, args...)
    l = LinearRegression()
    r = NoPenalty()
    a = default(Algorithm)
    λ = 0.0
    factor = ones(p)
    for arg in args
        if typeof(arg) <: Loss
            l = arg
        elseif typeof(arg) <: Penalty
            r = arg
        elseif typeof(arg) <: Algorithm
            a = arg
        elseif typeof(arg) == Float64
            λ = arg
        elseif typeof(arg) == VecF
            factor = arg
        else
            throw(ArumentError("Argument $arg is invalid"))
        end
    end
    SparseReg(p, l, r, a, λ, factor)
end

function SparseReg(x::AMatF, y::AVecF, args...)
    o = SparseReg(size(x, 2), args...)
    fit!(o, x, y)
    o
end

function Base.show(io::IO, o::SparseReg)
    println(io, "Sparse Regression Model")
    print_item(io, "β", o.β)
    print_item(io, "Loss", o.loss)
    print_item(io, "Penalty", o.penalty)
    print_item(io, "λ", o.λ)
    any(x -> x != 1.0, o.factor) && print_item(io, "λ scaling", o.factor)
    print_item(io, "Algorithm", o.algorithm)
end

coef(o::SparseReg) = o.β
logistic(x::Float64) = 1.0 / (1.0 + exp(-x))
xβ(o::SparseReg, x::AMat) = x * o.β
xβ(o::SparseReg, x::AVec) = dot(x, o.β)
predict(o::SparseReg, x::AVec) = _predict(o.loss, xβ(o, x))
predict(o::SparseReg, x::AMat) = _predict.(o.loss, xβ(o, x))
loss(o::SparseReg, x::AMat, y::AVec, args...) = value(o.loss, y, predict(o, x), args...)

#-------------------------------------------------------------------------------# helpers
name(a) = replace(string(typeof(a)), "SparseRegression.", "")
function print_item(io::IO, name::AbstractString, value)
    print(io, "  >" * @sprintf("%13s", name * ":  "))
    println(io, value)
end

# scary names so that nobody uses them
predict_from_xβ(l::Loss, xβ::Real) = xβ
predict_from_xβ(l::LogitMarginLoss, xβ::Real) = logistic(xβ)
predict_from_xβ(l::PoissonLoss, xβ::Real) = exp(xβ)
function xβ_to_ŷ!(l::Union{LogitMarginLoss, PoissonLoss}, xβ::AVec)
    for i in eachindex(xβ)
        @inbounds xβ[i] = predict_from_xβ(l, xβ[i])
    end
    xβ
end
xβ_to_ŷ!(l::Loss, xβ::AVec) = xβ;  # no-op if linear predictor == ŷ



#-------------------------------------------------------------------------------# algorithms
include("algorithms/proxgrad.jl")
# include("solutionpath.jl")

end
