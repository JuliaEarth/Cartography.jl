# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    CRS{Datum}

Coordinate Reference System (CRS) with a given `Datum`.
"""
abstract type CRS{Datum} end

"""
    CoordRefSystems.ncoords(coords)

Number of coordinates of `coords`.

See also [`ndims`](@ref).
"""
ncoords(coords::CRS) = ncoords(typeof(coords))
ncoords(C::Type{<:CRS}) = fieldcount(C)

"""
    CoordRefSystems.coords(coords)

Coordinate values of `coords` as tuple.
"""
cvalues(coords::CRS) = ntuple(i -> getfield(coords, i), nfields(coords))

"""
    CoordRefSystems.cnames(coords)

Coordinate names of `coords`.
"""
cnames(coords::CRS) = cnames(typeof(coords))
cnames(C::Type{<:CRS}) = fieldnames(C)

"""
    CoordRefSystems.ndims(coords)

Number of embedding dimensions of `coords`.

See also [`ncoords`](@ref).
"""
ndims(coords::CRS) = ndims(typeof(coords))

"""
    isapprox(coords₁, coords₂; kwargs...)

Checks whether the coordinates `coords₁` and `coords₂`
are approximate using the `isapprox` function.
"""
Base.isapprox(coords₁::C, coords₂::C; kwargs...) where {C<:CRS} =
  isapprox(convert(Cartesian, coords₁), convert(Cartesian, coords₂); kwargs...)

"""
    allapprox(coords₁, coords₂; kwargs...)

Checks whether all fields of `coords₁` and `coords₂`
are approximate using the `isapprox` function.
"""
allapprox(coords₁::C, coords₂::C; kwargs...) where {C<:CRS} =
  all(ntuple(i -> isapprox(getfield(coords₁, i), getfield(coords₂, i); kwargs...), nfields(coords₁)))

"""
    CoordRefSystems.tol(coords)

Absolute tolerance for the underlying machine type (e.g. `Float64`) used to represent the `coords`. 
The result inherits the unit of the `coords` after conversion to [`Cartesian`](@ref).
"""
tol(coords::CRS) = tol(convert(Cartesian, coords))

"""
    CoordRefSystems.lentype(coords)

Length unit type of `coords`.
"""
lentype(coords::CRS) = lentype(typeof(coords))

# ------
# DATUM
# ------

"""
    datum(coords)

Returns the datum of the coordinates `coords`.
"""
datum(coords::CRS) = datum(typeof(coords))
datum(::Type{<:CRS{Datum}}) where {Datum} = Datum

"""
    ellipsoid(coords)

Returns the ellipsoid of the coordinates `coords`.
"""
ellipsoid(coords::CRS) = ellipsoid(typeof(coords))
ellipsoid(C::Type{<:CRS}) = ellipsoid(datum(C))

# -----------
# IO METHODS
# -----------

function Base.summary(io::IO, coords::CRS)
  name = prettyname(coords)
  Datum = datum(coords)
  print(io, "$name{$(rmmodule(Datum))} coordinates")
end

function Base.show(io::IO, coords::CRS)
  name = prettyname(coords)
  Datum = datum(coords)
  print(io, "$name{$(rmmodule(Datum))}(")
  printfields(io, coords, compact=true)
  print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", coords::CRS)
  summary(io, coords)
  printfields(io, coords)
end

# ----------------
# IMPLEMENTATIONS
# ----------------

include("crs/basic.jl")
include("crs/geographic.jl")
include("crs/projected.jl")
