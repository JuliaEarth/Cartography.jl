# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    CRS{Datum}

Coordinate Reference System (CRS) with a given `Datum`
"""
abstract type CRS{Datum} end

Base.isapprox(coords₁::C, coords₂::C; kwargs...) where {C<:CRS} =
  all(ntuple(i -> isapprox(getfield(coords₁, i), getfield(coords₂, i); kwargs...), nfields(coords₁)))

"""
    formulas(CRS, T)

Returns the forward formulas of the `CRS`: `fx(λ, ϕ)` and `fy(λ, ϕ)`,
with `f(λ::T, ϕ::T) -> T` for both functions.
"""
function formulas end

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
ellipsoid(T::Type{<:CRS}) = ellipsoid(datum(T))

"""
    latitudeₒ(coords)

Returns the latitude origin of the coordinates `coords`.
"""
latitudeₒ(coords::CRS) = latitudeₒ(typeof(coords))
latitudeₒ(T::Type{<:CRS}) = latitudeₒ(datum(T))

"""
    longitudeₒ(coords)

Returns the longitude origin of the coordinates `coords`.
"""
longitudeₒ(coords::CRS) = longitudeₒ(typeof(coords))
longitudeₒ(T::Type{<:CRS}) = longitudeₒ(datum(T))

"""
    altitudeₒ(coords)

Returns the altitude origin of the coordinates `coords`.
"""
altitudeₒ(coords::CRS) = altitudeₒ(typeof(coords))
altitudeₒ(T::Type{<:CRS}) = altitudeₒ(datum(T))

# -----------
# IO METHODS
# -----------

function Base.summary(io::IO, coords::CRS)
  name = prettyname(coords)
  Datum = datum(coords)
  print(io, "$name{$Datum} coordinates")
end

function Base.show(io::IO, coords::CRS)
  name = prettyname(coords)
  Datum = datum(coords)
  print(io, "$name{$Datum}(")
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

const Len{T} = Quantity{T,u"𝐋"}
const Met{T} = Quantity{T,u"𝐋",typeof(u"m")}
const Rad{T} = Quantity{T,NoDims,typeof(u"rad")}
const Deg{T} = Quantity{T,NoDims,typeof(u"°")}

include("crs/basic.jl")
include("crs/latlon.jl")
include("crs/mercator.jl")
include("crs/webmercator.jl")
include("crs/eqdistcylindrical.jl")
include("crs/eqareacylindrical.jl")
include("crs/winkeltripel.jl")
include("crs/robinson.jl")
include("crs/orthographic.jl")

# ----------
# FALLBACKS
# ----------

function Base.convert(::Type{C}, coords::LatLon{Datum}) where {Datum,C<:CRS{Datum}}
  T = numtype(coords.lon)
  λ = ustrip(deg2rad(coords.lon))
  ϕ = ustrip(deg2rad(coords.lat))
  a = numconvert(T, majoraxis(ellipsoid(Datum)))
  fx, fy = formulas(C, T)
  x = fx(λ, ϕ) * a
  y = fy(λ, ϕ) * a
  C(x, y)
end
