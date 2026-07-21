# bluertopo

[![R-CMD-check](https://github.com/el-cordero/bluer-topo/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/el-cordero/bluer-topo/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/el-cordero/bluer-topo/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/el-cordero/bluer-topo/actions/workflows/pkgdown.yaml)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/el-cordero/bluer-topo/blob/main/LICENSE.md)

`bluertopo` discovers, downloads, verifies, and opens National Oceanic
and Atmospheric Administration (NOAA) BlueTopo bathymetry for an area of
interest using `terra`. The package keeps source GeoTIFF and RAT sidecar
files intact by default, records query and catalog provenance, and makes
native source-resolution choices explicit.

BlueTopo is not for navigation. This package performs no vertical-datum
conversion and is not affiliated with, endorsed by, or supported by
NOAA.

Reference: NOAA,
[BlueTopo](https://nauticalcharts.noaa.gov/data/bluetopo.html) and
[BlueTopo
specifications](https://nauticalcharts.noaa.gov/data/bluetopo_specs.html).

## New York Harbor example

This example demonstrates tile discovery, verified asset retrieval, and
bathymetry extraction for New York Harbor. The area includes portions of
Lower Manhattan, Governors Island, Upper New York Bay, and the East
River entrance.

![BlueTopo bathymetry for New York Harbor with hillshade, contours, and
the example-area boundary.](reference/figures/home-bathy-map-1.png)

BlueTopo bathymetry for New York Harbor, displayed with hillshade,
contours, and the example-area boundary.

| Example area | Selected tiles | Native resolution | Retrieved assets | Verification |
|:---|---:|:---|:---|:---|
| New York Harbor | 2 | 4 m | 2 GeoTIFFs and 2 RAT files | SHA-256 verified |

## Basic workflow

``` r

library(bluertopo)

aoi <- vect("my_area.gpkg")
bathy <- bluertopo(aoi)
plot(bathy)
```

[`sf::sf`](https://r-spatial.github.io/sf/reference/sf.html) and
[`sf::sfc`](https://r-spatial.github.io/sf/reference/sfc.html) polygon
objects with a known CRS can also be passed directly to
[`bluertopo()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo.md),
[`bluertopo_tiles()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo_tiles.md),
and
[`bluertopo_download()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo_download.md).

| Function | Returns |
|:---|:---|
| `bluertopo_tiles(aoi)` | Selected tile footprints and metadata as a [`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html) |
| `bluertopo_download(aoi, path)` | Verified source-asset records as a data frame |
| `bluertopo(aoi)` | A [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html) or [`terra::SpatRasterCollection`](https://rspatial.github.io/terra/reference/SpatRaster-class.html) |

## Provenance workflow

``` r

result <- bluertopo(aoi, details = TRUE)

result$tiles
result$downloads
result$coverage
result$provenance
```

## Examples

The [Examples
tab](https://el-cordero.github.io/bluer-topo/articles/examples.md) uses
NOAA BlueTopo source tiles for New York Harbor. Normal package tests use
small synthetic fixtures so checks remain network-free. The mixed-grid
example uses a documented secondary AOI near Key West and Boca Chica
Channel because the current New York Harbor plan is one compatible 4 m
native grid.

- [Example
  gallery](https://el-cordero.github.io/bluer-topo/articles/examples.md)
- [Discover tiles and
  coverage](https://el-cordero.github.io/bluer-topo/articles/example-discover-tiles.md)
- [Download original
  assets](https://el-cordero.github.io/bluer-topo/articles/example-download-assets.md)
- [Extract elevation with
  terra](https://el-cordero.github.io/bluer-topo/articles/example-extract-elevation.md)
- [Compare resolution
  policies](https://el-cordero.github.io/bluer-topo/articles/example-resolution-policies.md)
- [Mixed grids and output
  grid](https://el-cordero.github.io/bluer-topo/articles/example-mixed-grids.md)
- [Layers and RAT
  metadata](https://el-cordero.github.io/bluer-topo/articles/example-layers-rat.md)
