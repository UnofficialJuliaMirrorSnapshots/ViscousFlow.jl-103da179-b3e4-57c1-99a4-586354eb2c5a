# Laplacian

"""
    laplacian!(v,w)

Evaluate the discrete Laplacian of `w` and return it as `v`. The data `w` can be
of type dual/primary nodes or edges; `v` must be of the same type.

# Example

```jldoctest
julia> w = Nodes(Dual,(8,6));

julia> v = deepcopy(w);

julia> w[4,3] = 1.0;

julia> laplacian!(v,w)
Nodes{Dual,8,6} data
Printing in grid orientation (lower left is (1,1))
6×8 Array{Float64,2}:
 0.0  0.0  0.0   0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0   0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0   1.0  0.0  0.0  0.0  0.0
 0.0  0.0  1.0  -4.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0   1.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0   0.0  0.0  0.0  0.0  0.0
```
"""
function laplacian!(out::Nodes{Dual,NX, NY}, w::Nodes{Dual,NX, NY}) where {NX, NY}
    @inbounds for y in 2:NY-1, x in 2:NX-1
        out[x,y] = w[x,y-1] + w[x-1,y] - 4w[x,y] + w[x+1,y] + w[x,y+1]
    end
    out
end

function laplacian!(out::Nodes{Primal,NX, NY}, w::Nodes{Primal,NX, NY}) where {NX, NY}
    @inbounds for y in 2:NY-2, x in 2:NX-2
        out[x,y] = w[x,y-1] + w[x-1,y] - 4w[x,y] + w[x+1,y] + w[x,y+1]
    end
    out
end

function laplacian!(out::Edges{Dual,NX, NY}, w::Edges{Dual,NX, NY}) where {NX, NY}
  @inbounds for y in 2:NY-1, x in 2:NX-2
      out.u[x,y] = w.u[x,y-1] + w.u[x-1,y] - 4w.u[x,y] + w.u[x+1,y] + w.u[x,y+1]
  end
  @inbounds for y in 2:NY-2, x in 2:NX-1
      out.v[x,y] = w.v[x,y-1] + w.v[x-1,y] - 4w.v[x,y] + w.v[x+1,y] + w.v[x,y+1]
  end
  out
end

function laplacian!(out::Edges{Primal,NX, NY}, w::Edges{Primal,NX, NY}) where {NX, NY}
  @inbounds for y in 2:NY-2, x in 2:NX-1
      out.u[x,y] = w.u[x,y-1] + w.u[x-1,y] - 4w.u[x,y] + w.u[x+1,y] + w.u[x,y+1]
  end
  @inbounds for y in 2:NY-1, x in 2:NX-2
      out.v[x,y] = w.v[x,y-1] + w.v[x-1,y] - 4w.v[x,y] + w.v[x+1,y] + w.v[x,y+1]
  end
  out
end

"""
    laplacian(w)

Evaluate the discrete Laplacian of `w`. The data `w` can be of type dual/primary
nodes or edges. The returned result is of the same type as `w`.

# Example

```jldoctest
julia> q = Edges(Primal,(8,6));

julia> q.u[2,2] = 1.0;

julia> laplacian(q)
Edges{Primal,8,6} data
u (in grid orientation)
5×8 Array{Float64,2}:
 0.0   0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0   0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0   1.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  -4.0  1.0  0.0  0.0  0.0  0.0  0.0
 0.0   0.0  0.0  0.0  0.0  0.0  0.0  0.0
v (in grid orientation)
6×7 Array{Float64,2}:
 0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0
```
"""
function laplacian(w::Nodes{T,NX,NY}) where {T<:CellType,NX,NY}
  laplacian!(Nodes(T,(NX,NY)), w)
end

function laplacian(w::Edges{T,NX,NY}) where {T<:CellType,NX,NY}
  laplacian!(Edges(T,(NX,NY)), w)
end


"""
    plan_laplacian(dims::Tuple,[with_inverse=false],[fftw_flags=FFTW.ESTIMATE],
                          [dx=1.0])

Constructor to set up an operator for evaluating the discrete Laplacian on
dual or primal nodal data of dimension `dims`. If the optional keyword
`with_inverse` is set to `true`, then it also sets up the inverse Laplacian
(the lattice Green's function, LGF). These can then be applied, respectively, with
`*` and `\\` operations on data of the appropriate size. The optional parameter
`dx` is used in adjusting the uniform value of the LGF to match the behavior
of the continuous analog at large distances; this is set to 1.0 by default.

Instead of the first argument, one can also supply `w::Nodes` to specify the
size of the domain.

# Example

```jldoctest
julia> w = Nodes(Dual,(5,5));

julia> w[3,3] = 1.0;

julia> L = plan_laplacian(5,5;with_inverse=true)
Discrete Laplacian (and inverse) on a (nx = 5, ny = 5) grid with spacing 1.0

julia> s = L\\w
Nodes{Dual,5,5} data
Printing in grid orientation (lower left is (1,1))
5×5 Array{Float64,2}:
 0.16707    0.129276     0.106037     0.129276    0.16707
 0.129276   0.0609665   -0.00734343   0.0609665   0.129276
 0.106037  -0.00734343  -0.257343    -0.00734343  0.106037
 0.129276   0.0609665   -0.00734343   0.0609665   0.129276
 0.16707    0.129276     0.106037     0.129276    0.16707

julia> L*s ≈ w
true
```
"""
function plan_laplacian end

"""
    plan_laplacian!(dims::Tuple,[with_inverse=false],[fftw_flags=FFTW.ESTIMATE],
                          [dx=1.0])

Same as [`plan_laplacian`](@ref), but operates in-place on data.
"""
function plan_laplacian! end

struct Laplacian{NX, NY, R, DX, inplace}
    conv::Union{CircularConvolution{NX, NY},Nothing}
end



for (lf,inplace) in ((:plan_laplacian,false),
                     (:plan_laplacian!,true))
    @eval function $lf(dims::Tuple{Int,Int};
                   with_inverse = false, fftw_flags = FFTW.ESTIMATE, dx = 1.0)
        NX, NY = dims
        if !with_inverse
            #return Laplacian{NX, NY, false, dx, $inplace}(Nullable())
            return Laplacian{NX, NY, false, dx, $inplace}(nothing)
        end

        G = view(LGF_TABLE, 1:NX, 1:NY)
        #Laplacian{NX, NY, true, dx, $inplace}(Nullable(CircularConvolution(G, fftw_flags)))
        Laplacian{NX, NY, true, dx, $inplace}(CircularConvolution(G, fftw_flags))
    end

    @eval function $lf(nx::Int, ny::Int;
        with_inverse = false, fftw_flags = FFTW.ESTIMATE, dx = 1.0)
        $lf((nx, ny), with_inverse = with_inverse, fftw_flags = fftw_flags, dx = dx)
    end

    @eval function $lf(nodes::Nodes{T,NX,NY};
        with_inverse = false, fftw_flags = FFTW.ESTIMATE, dx = 1.0) where {T<:CellType,NX,NY}
        $lf(node_inds(T,(NX,NY)), with_inverse = with_inverse, fftw_flags = fftw_flags, dx = dx)
    end
end



function Base.show(io::IO, L::Laplacian{NX, NY, R, DX, inplace}) where {NX, NY, R, DX, inplace}
    nodedims = "(nx = $NX, ny = $NY)"
    inverse = R ? " (and inverse)" : ""
    isinplace = inplace ? " in-place" : ""
    print(io, "Discrete$isinplace Laplacian$inverse on a $nodedims grid with spacing $DX")
end

mul!(out::Nodes{T,NX,NY}, L::Laplacian, s::Nodes{T,NX,NY}) where {T<:CellType,NX,NY} = laplacian!(out, s)
*(L::Laplacian{MX,MY,R,DX,false}, s::Nodes{T,NX,NY}) where {MX,MY,R,DX,T <: CellType,NX,NY} =
      laplacian(s)
function (*)(L::Laplacian{MX,MY,R,DX,true}, s::Nodes{T,NX,NY}) where {MX,MY,R,DX,T <: CellType,NX,NY}
    laplacian!(s,deepcopy(s))
end
#L::Laplacian * s::Nodes{T,NX,NY} where {T <: CellType, NX,NY} = laplacian(s)


function ldiv!(out::Nodes{T,NX, NY},
                   L::Laplacian{MX, MY, true, DX, inplace},
                   s::Nodes{T, NX, NY}) where {T <: CellType, NX, NY, MX, MY, DX, inplace}

    mul!(out.data, L.conv, s.data)

    # Adjust the behavior at large distance to match continuous kernel
    out.data .-= (sum(s.data)/2π)*(GAMMA+log(8)/2-log(DX))
    out
end

\(L::Laplacian{MX,MY,R,DX,false},s::Nodes{T,NX,NY}) where {MX,MY,R,DX,T <: CellType,NX,NY} =
  ldiv!(Nodes(T,s), L, s)

\(L::Laplacian{MX,MY,R,DX,true},s::Nodes{T,NX,NY}) where {MX,MY,R,DX,T <: CellType,NX,NY} =
  ldiv!(s, L, deepcopy(s))
