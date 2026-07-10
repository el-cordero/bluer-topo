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
[BlueTopo](https://nauticalcharts.noaa.gov/data/bluetopo.html) and
[BlueTopo
specifications](https://nauticalcharts.noaa.gov/data/bluetopo_specs.html).

## Real NOAA Proof

Example AOI: New York Harbor, centered on Lower Manhattan, the Upper
Bay, Governors Island, and the East River mouth. This homepage proof
uses actual NOAA BlueTopo source tiles downloaded during the pkgdown
build.

<div class="figure">

<img src="man/figures/home-proof-map-1.png" alt="Hillshaded real NOAA BlueTopo bathymetry map for New York Harbor with contour lines and the AOI outline."  />
<p class="caption">

Actual NOAA BlueTopo source data: New York Harbor elevation with
hillshade, contours, and AOI outline.
</p>

</div>

| tile_id  | resolution_m | utm_zone | intersection_fraction | selection_reason |
|:---------|-------------:|:---------|----------------------:|:-----------------|
| BH4XC5FK |            4 | 18       |                 0.142 | native           |
| BH4XD5FK |            4 | 18       |                 0.213 | native           |

| tile_id  | asset_type | status          | verified | downloaded_mb | actual_sha256 |
|:---------|:-----------|:----------------|:---------|--------------:|:--------------|
| BH4XC5FK | geotiff    | reused_verified | TRUE     |         5.393 | 878be33a85f5  |
| BH4XC5FK | rat        | reused_verified | TRUE     |         0.104 | 21405b45e162  |
| BH4XD5FK | geotiff    | reused_verified | TRUE     |         4.093 | 35174b851869  |
| BH4XD5FK | rat        | reused_verified | TRUE     |         0.067 | 59814a3e330c  |

## Basic Workflow

``` r
library(bluertopo)
library(terra)

aoi <- vect("my_area.gpkg")
bathy <- bluertopo(aoi)
plot(bathy)
```

## Provenance Workflow

``` r
result <- bluertopo(aoi, details = TRUE)

result$tiles
result$downloads
result$coverage
result$provenance
```

## Examples

The [Examples tab](articles/examples.html) is rendered from actual NOAA
BlueTopo source tiles for New York Harbor. Normal package tests use
small synthetic fixtures so checks remain network-free. The mixed-grid
example uses a documented secondary real AOI near Key West and Boca
Chica Channel because the current New York Harbor plan is one compatible
4 m native grid.

- [Example gallery](articles/examples.html)
- [Discover tiles and coverage](articles/example-discover-tiles.html)
- [Download original assets](articles/example-download-assets.html)
- [Extract elevation with
  terra](articles/example-extract-elevation.html)
- [Compare resolution
  policies](articles/example-resolution-policies.html)
- [Mixed grids and output grid](articles/example-mixed-grids.html)
- [Layers and RAT metadata](articles/example-layers-rat.html)
