immutable Sweep{O <: Obs} <: OfflineAlgorithm
    a::MatF
    s::MatF
    obs::O
end
function Base.show(io::IO, alg::Sweep)
    print_with_color(:light_cyan, io, "Sweep")
end

function Sweep(x, y)
    obs = Obs(x, y)
    n, p = size(obs.x)
    a = zeros(p + 1, p + 1)
    b = zeros(p + 1, p + 1)
    BLAS.syrk!('U', 'T', 1 / n, Diagonal(sqrt.(obs.w)) * obs.x, 0.0, view(a, 1:p, 1:p))  # x'wx
    BLAS.gemv!('T', 1 / n, Diagonal(obs.w) * obs.x, obs.y, 0.0, @view(a[1:p, end]))     # x'wy
    a[end, end] = dot(obs.y, Diagonal(obs.w) * obs.y) / n                               # y'wy
    Sweep(a, b, obs)
end
function Sweep(x, y, w)
    obs = Obs(x, y, w)
    n, p = size(obs.x)
    a = zeros(p + 1, p + 1)
    b = zeros(p + 1, p + 1)
    BLAS.syrk!('U', 'T', 1 / n, obs.x, 0.0, view(a, 1:p, 1:p))      # x'x
    BLAS.gemv!('T', 1 / n, obs.x, obs.y, 0.0, @view(a[1:p, end]))   # x'y
    a[end, end] = dot(obs.y, obs.y) / n                             # y'y
    Sweep(a, b, obs)
end

Sweepable = Union{NoPenalty, L2Penalty}

function fit!(o::SparseReg{<:Sweep, LinearRegression, <:Sweepable})
    A = o.algorithm
    p = size(A.obs.x, 2)
    copy!(A.s, A.a)
    add_ridge!(o, A)
    SweepOperator.sweep!(A.s, 1:p)
    o.β[:] = A.s[1:p, end]
    o
end


function add_ridge!{S,L}(o::SparseReg{S, L, NoPenalty}, A) end
function add_ridge!{S,L}(o::SparseReg{S, L, L2Penalty}, A)
    for i in 1:size(A.obs.x, 2)
        A.s[i, i] += o.λ * o.factor[i]
    end
end
