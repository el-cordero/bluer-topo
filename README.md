
# bluertopo

<img src="man/figures/logo.png" align="right" height="139" alt="bluertopo logo" />

[![R-CMD-check](https://github.com/el-cordero/bluer-topo/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/el-cordero/bluer-topo/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/el-cordero/bluer-topo/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/el-cordero/bluer-topo/actions/workflows/pkgdown.yaml)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)

`bluertopo` discovers, downloads, verifies, and opens NOAA BlueTopo
bathymetry for an area of interest using `terra`. The package keeps
source GeoTIFF and RAT sidecar files intact by default, records query
and catalog provenance, and makes native source-resolution choices
explicit.

BlueTopo is not for navigation. This package performs no vertical-datum
conversion and is not affiliated with, endorsed by, or supported by
NOAA.

Reference: NOAA,
[BlueTopo](https://nauticalcharts.noaa.gov/data/bluetopo.html).

## Installation

``` r
# install.packages("pak")
pak::pak("el-cordero/bluer-topo")
```

## Basic workflow

``` r
library(bluertopo)
library(terra)

aoi <- vect("my_area.gpkg")

bathy <- bluertopo(
  aoi,
  layers = "elevation",
  resolution = "native",
  coverage = "warn",
  details = TRUE
)

bathy$data
bathy$tiles
bathy$provenance
```

## Download original NOAA assets

Use `bluertopo_download()` when the durable deliverable is the original
NOAA GeoTIFF plus optional RAT sidecars rather than an extracted raster
object.

``` r
files <- bluertopo_download(
  aoi,
  path = "data/bluetopo",
  rat = TRUE,
  verify = "sha256",
  coverage = "fill"
)
```

`verify = "sha256"` is the default and requires NOAA-provided checksums.
`verify = "none"` is available only for explicitly unverified workflows.
`verify = "size"` is rejected unless trustworthy expected byte counts
are available before any transfer starts.

## Native resolution policies

`resolution` filters NOAA BlueTopo source tiles by their native cell
size. Smaller meter values mean finer native source detail.
`output_resolution` requests an explicit output grid and therefore
resamples the output.

``` r
# Exact native resolution
bathy_8m <- bluertopo(aoi, resolution = 8)

# Highest native detail, with lower-resolution fallback for coverage
bathy_best <- bluertopo(aoi, resolution = "finest", coverage = "fill")

# Lowest native detail
bathy_low <- bluertopo(aoi, resolution = "coarsest")

# Closest available native resolution to 10 m
bathy_near <- bluertopo(
  aoi,
  resolution = bluertopo_resolution("nearest", value = 10, tie = "finer")
)

# Keep source tiles from 4 through 16 m
bathy_range <- bluertopo(
  aoi,
  resolution = bluertopo_resolution("between", min_m = 4, max_m = 16)
)
```

## Mixed source grids

Native BlueTopo tiles can span multiple UTM zones, resolutions, or grid
alignments. When the selected source files are not compatible,
`bluertopo()` returns a `terra::SpatRasterCollection` unless the user
explicitly requests an output grid.

``` r
bathy_10m <- bluertopo(
  aoi,
  resolution = "native",
  output_crs = "EPSG:26918",
  output_resolution = 10,
  combine = "single"
)
```

## Cache operations

Package cache operations are intentionally conservative.
`bluertopo_cache_clear()` clears only the configured `bluertopo` cache,
requires confirmation in noninteractive sessions, and refuses to remove
content unless a package-owned cache marker is present.

``` r
bluertopo_cache_dir()
bluertopo_cache_clear(confirm = TRUE)
```

## Examples

The [Examples
tab](https://el-cordero.github.io/bluer-topo/articles/examples.html) on
the pkgdown site is rendered from actual NOAA BlueTopo source tiles.
Normal package tests use small synthetic fixtures so checks remain
network-free. Example downloads are intentionally small and cached
during website builds, but they still access NOAA public data. Users
should expect real BlueTopo tiles to vary in size by location.

- [Example
  gallery](https://el-cordero.github.io/bluer-topo/articles/examples.html)
- [Discover tiles and
  coverage](https://el-cordero.github.io/bluer-topo/articles/example-discover-tiles.html)
- [Download original
  assets](https://el-cordero.github.io/bluer-topo/articles/example-download-assets.html)
- [Extract elevation with
  terra](https://el-cordero.github.io/bluer-topo/articles/example-extract-elevation.html)
- [Compare resolution
  policies](https://el-cordero.github.io/bluer-topo/articles/example-resolution-policies.html)
- [Mixed grids and output
  grid](https://el-cordero.github.io/bluer-topo/articles/example-mixed-grids.html)
- [Layers and RAT
  metadata](https://el-cordero.github.io/bluer-topo/articles/example-layers-rat.html)

## Reference

NOAA. BlueTopo. <https://nauticalcharts.noaa.gov/data/bluetopo.html>
