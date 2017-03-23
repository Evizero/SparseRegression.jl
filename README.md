# SparseRegression

This package relies on primitives defined in the JuliaML ecosystem to implement high-performance algorithms for linear models which often produce sparsity in the coefficients.

# Installation

Note: SparseRegression requires Julia 0.6

```julia
Pkg.clone("https://github.com/JuliaML/PenaltyFunctions.jl")
Pkg.clone("https://github.com/joshday/SparseRegression.jl")
Pkg.checkout("LossFunctions")
```

# Example

```julia
using SparseRegression
include(Pkg.dir("SparseRegression", "test", "datagenerator.jl"))

x, y, b = DataGenerator.linregdata(10_000, 10)

observations = Obs(x, y)

SweepModel(observations; penalty = L2Penalty(), λ = collect(0:.01:.1))
# fit(SweepModel, observations; penalty = L2Penalty, λ = collect(0:.01:.1))

ProximalGradientModel(observations; loss = HuberLoss(2.0), penalty = L1Penalty())
# fit(ProximalGradientModel, x, y; loss = HuberLoss(2.0), penalty = L1Penalty())

StochasticModel(observations, ADAGRAD(); loss = L1Regression(), penalty = ElasticNetPenalty(.1))
```

# Notes on Design
SparseRegression fits models of the form `f(β) +  λ * g(β)` where
- `f` is a `Loss` from [LossFunctions.jl](https://github.com/JuliaML/LossFunctions.jl)
  - SparseRegression provides a few aliases for easy use:
    - `LinearRegression()`: `scaled(L2DistLoss(), .5)`
    - `LogisticRegression()`
    - `PoissonRegression()`
    - `L1Regression()`
    - `QuantileRegression(q)`
    - `HuberRegression(v)`
    - `SVMLike()`
    - `DWDLike(q)`
- `g` is a `Penalty` from [PenaltyFunctions.jl](https://github.com/JuliaML/PenaltyFunctions.jl)
- `λ` is a regularization parameter

Many statistical learning models fit in this form (regularized GLMs, SVMs, etc.)

Types are designed around the abstract type `AbstractSparseReg`.  These types define the algorithm used to fit a model and hold "sufficient statistics"/buffers.  

  - `ProximalGradientModel`
    - Any Loss
    - Convex penalties: `NoPenalty()`, `L1Penalty()`, `L2Penalty()`, `ElasticNetPenalty(a)`
  - `SweepModel`
    - `LinearRegression()`, `L2DistLoss()`
    - `NoPenalty()` or `L2Penalty()`
  - `StochasticModel`
    - Any Loss
    - Convex penalties: : `NoPenalty()`, `L1Penalty()`, `L2Penalty()`, `ElasticNetPenalty(a)`
