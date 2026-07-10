# Discover BlueTopo tiles intersecting an AOI

Returns selected NOAA BlueTopo tile footprints and standardized metadata
without downloading raster assets.

## Usage

``` r
bluertopo_tiles(
  aoi,
  resolution = "native",
  coverage = "warn",
  min_coverage = 1,
  cache_dir = bluertopo_cache_dir(),
  refresh = "if_stale",
  quiet = FALSE
)
```

## Arguments

- aoi:

  Area of interest.

- resolution:

  Native source-resolution policy.

- coverage:

  Coverage policy: `"ignore"`, `"warn"`, `"error"`, or `"fill"`.

- min_coverage:

  Target share of published tile coverage.

- cache_dir:

  Package cache directory.

- refresh:

  Catalog refresh policy.

- quiet:

  Suppress routine messages.

## Value

A
[`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
with selected tile metadata. Coverage diagnostics are attached as an
attribute.

## Examples

``` r
if (FALSE) { # \dontrun{
tiles <- bluertopo_tiles(c(-66.2, 18.2, -66.1, 18.3))
} # }
```
