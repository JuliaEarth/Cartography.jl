# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    EqualAreaCylindrical{latₜₛ,lon₀,Datum}

Equal Area Cylindrical CRS with latitude of true scale `latₜₛ` and longitude origin `lon₀`
in degrees and a given `Datum`.
"""
struct EqualAreaCylindrical{latₜₛ,lon₀,Datum,M<:Met} <: Projected{Datum}
  x::M
  y::M
  EqualAreaCylindrical{latₜₛ,lon₀,Datum}(x::M, y::M) where {latₜₛ,lon₀,Datum,M<:Met} =
    new{latₜₛ,lon₀,Datum,float(M)}(x, y)
end

EqualAreaCylindrical{latₜₛ,lon₀,Datum}(x::Met, y::Met) where {latₜₛ,lon₀,Datum} =
  EqualAreaCylindrical{latₜₛ,lon₀,Datum}(promote(x, y)...)
EqualAreaCylindrical{latₜₛ,lon₀,Datum}(x::Len, y::Len) where {latₜₛ,lon₀,Datum} =
  EqualAreaCylindrical{latₜₛ,lon₀,Datum}(uconvert(u"m", x), uconvert(u"m", y))
EqualAreaCylindrical{latₜₛ,lon₀,Datum}(x::Number, y::Number) where {latₜₛ,lon₀,Datum} =
  EqualAreaCylindrical{latₜₛ,lon₀,Datum}(addunit(x, u"m"), addunit(y, u"m"))

EqualAreaCylindrical{latₜₛ,lon₀}(args...) where {latₜₛ,lon₀} = EqualAreaCylindrical{latₜₛ,lon₀,WGS84Latest}(args...)

"""
    Lambert(x, y)
    Lambert{Datum}(x, y)

Lambert cylindrical equal-area coordinates in length units (default to meter)
with a given `Datum` (default to `WGS84`).

## Examples

```julia
Lambert(1, 1) # add default units
Lambert(1u"m", 1u"m") # integers are converted converted to floats
Lambert(1.0u"km", 1.0u"km") # length quantities are converted to meters
Lambert(1.0u"m", 1.0u"m")
Lambert{WGS84Latest}(1.0u"m", 1.0u"m")
```

See [ESRI:54034](https://epsg.io/54034).
"""
const Lambert{Datum} = EqualAreaCylindrical{0.0u"°",0.0u"°",Datum}

"""
    Behrmann(x, y)
    Behrmann{Datum}(x, y)

Behrmann coordinates in length units (default to meter)
with a given `Datum` (default to `WGS84`).

## Examples

```julia
Behrmann(1, 1) # add default units
Behrmann(1u"m", 1u"m") # integers are converted converted to floats
Behrmann(1.0u"km", 1.0u"km") # length quantities are converted to meters
Behrmann(1.0u"m", 1.0u"m")
Behrmann{WGS84Latest}(1.0u"m", 1.0u"m")
```

See [ESRI:54017](https://epsg.io/54017).
"""
const Behrmann{Datum} = EqualAreaCylindrical{30.0u"°",0.0u"°",Datum}

"""
    GallPeters(x, y)
    GallPeters{Datum}(x, y)

Gall-Peters coordinates in length units (default to meter)
with a given `Datum` (default to `WGS84`).

## Examples

```julia
GallPeters(1, 1) # add default units
GallPeters(1u"m", 1u"m") # integers are converted converted to floats
GallPeters(1.0u"km", 1.0u"km") # length quantities are converted to meters
GallPeters(1.0u"m", 1.0u"m")
GallPeters{WGS84Latest}(1.0u"m", 1.0u"m")
```
"""
const GallPeters{Datum} = EqualAreaCylindrical{45.0u"°",0.0u"°",Datum}

# ------------
# CONVERSIONS
# ------------

# Adapted from PROJ coordinate transformation software
# Initial PROJ 4.3 public domain code was put as Frank Warmerdam as copyright
# holder, but he didn't mean to imply he did the work. Essentially all work was
# done by Gerald Evenden.

# reference code: https://github.com/OSGeo/PROJ/blob/master/src/projections/cea.cpp
# reference formula: https://neacsu.net/docs/geodesy/snyder/3-cylindrical/sect_10/

function formulas(::Type{<:EqualAreaCylindrical{latₜₛ,lon₀,Datum}}, ::Type{T}) where {latₜₛ,lon₀,Datum,T}
  🌎 = ellipsoid(Datum)
  e = T(eccentricity(🌎))
  e² = T(eccentricity²(🌎))
  λ₀ = T(ustrip(deg2rad(lon₀)))
  ϕₜₛ = T(ustrip(deg2rad(latₜₛ)))

  k₀ = cos(ϕₜₛ) / sqrt(1 - e² * sin(ϕₜₛ)^2)

  fx(λ, ϕ) = k₀ * (λ - λ₀)

  function fy(λ, ϕ)
    sinϕ = sin(ϕ)
    esinϕ = e * sinϕ
    q = (1 - e²) * (sinϕ / (1 - esinϕ^2) - (1 / 2e) * log((1 - esinϕ) / (1 + esinϕ)))
    q / 2k₀
  end

  fx, fy
end

function Base.convert(::Type{LatLon{Datum}}, coords::EqualAreaCylindrical{latₜₛ,lon₀,Datum}) where {latₜₛ,lon₀,Datum}
  🌎 = ellipsoid(Datum)
  x = coords.x
  y = coords.y
  a = oftype(x, majoraxis(🌎))
  e = convert(numtype(x), eccentricity(🌎))
  e² = convert(numtype(x), eccentricity²(🌎))
  λ₀ = numconvert(numtype(x), deg2rad(lon₀))
  ϕₜₛ = numconvert(numtype(x), deg2rad(latₜₛ))

  ome² = 1 - e²
  k₀ = cos(ϕₜₛ) / sqrt(1 - e² * sin(ϕₜₛ)^2)
  # same formula as q, but ϕ = 90°
  qₚ = ome² * (1 / ome² - (1 / 2e) * log((1 - e) / (1 + e)))

  λ = λ₀ + x / (a * k₀)
  q = 2y * k₀ / a
  β = asin(q / qₚ)
  ϕ = auth2geod(β, e²)

  LatLon{Datum}(rad2deg(ϕ) * u"°", rad2deg(λ) * u"°")
end
