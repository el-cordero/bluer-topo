# Extract Elevation with terra

This page uses real NOAA BlueTopo source tiles when rendered for the
public pkgdown site. This example uses actual NOAA BlueTopo source tiles
downloaded from the public NOAA National Bathymetric Source bucket
during the pkgdown build.

This page downloads two real NOAA BlueTopo tiles for New York Harbor,
verifies the GeoTIFF and RAT checksums, opens the elevation band with
`terra`, and renders a hillshaded bathymetry map with contour lines.

BlueTopo is not for navigation. No vertical-datum conversion is
performed.
[`bluertopo()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo.md)
returns terra objects and, with `details = TRUE`, exposes selected
tiles, downloads, query metadata, provenance, and coverage diagnostics.
Normal native extraction does not intentionally resample.

## Real Example Setup

``` r

library(terra)
#> terra 1.9.34

real <- bt_real_example_setup()
real_aoi <- real$aoi
```

## Extract Elevation

``` r

result <- bluertopo(
  real_aoi,
  layers = "elevation",
  resolution = "native",
  coverage = "fill",
  details = TRUE,
  progress = FALSE,
  quiet = TRUE
)
```

## Object Summary

``` r

rasters <- bt_rasters(result$data)
object_summary <- data.frame(
  element = c(
    "object type",
    "result$data class",
    "number of layers",
    "layer names",
    "CRS summary",
    "resolution",
    "source count"
  ),
  value = c(
    if (inherits(result$data, "SpatRasterCollection")) "SpatRasterCollection" else "SpatRaster",
    paste(class(result$data), collapse = ", "),
    sum(vapply(rasters, terra::nlyr, numeric(1L))),
    paste(unique(unlist(lapply(rasters, names), use.names = FALSE)), collapse = ", "),
    paste(unique(vapply(rasters, function(r) {
      paste0("EPSG:", terra::crs(r, describe = TRUE)$code)
    }, "")), collapse = ", "),
    paste(unique(vapply(rasters, function(r) paste(round(terra::res(r), 3), collapse = " x "), "")), collapse = "; "),
    length(unique(unlist(lapply(rasters, terra::sources), use.names = FALSE)))
  ),
  stringsAsFactors = FALSE
)

bt_display_table(object_summary)
```

| element            | value      |
|:-------------------|:-----------|
| object type        | SpatRaster |
| result\$data class | SpatRaster |
| number of layers   | 1          |
| layer names        | elevation  |
| CRS summary        | EPSG:26918 |
| resolution         | 4 x 4      |
| source count       | 1          |

## File-Backed Sources

``` r

bt_display_table(bt_sources_table(result$data))
```

| source |
|:-------|
| NA     |

## Coverage

``` r

bt_display_table(bt_coverage_table(result$coverage))
```

| published_coverage_fraction | selected_coverage_fraction | selected_aoi_fraction | target_coverage | target_met | coverage_type |
|---:|---:|---:|---:|:---|:---|
| 1 | 1 | 1 | 1 | TRUE | geometric tile-index coverage |

## Provenance

``` r

bt_display_table(bt_catalog_table(real))
```

| field                     | value                                     |
|:--------------------------|:------------------------------------------|
| catalog_name              | BlueTopo_Tile_Scheme_20260626_132625.gpkg |
| catalog_last_modified     | 2026-06-26T17:35:52.000Z                  |
| package_version           | 0.0.1                                     |
| not_for_navigation        | BlueTopo is not for navigation            |
| vertical_datum_conversion | none performed by bluertopo               |
| planned_download_mb       | 9.657                                     |

## Elevation Preview

``` r

bt_plot_bathy_map(result$data, real_aoi, main = "New York Harbor NOAA BlueTopo bathymetry")
```

![Hillshaded real BlueTopo elevation raster with contours and AOI
outline for New York
Harbor.](example-extract-elevation_files/figure-html/elevation-figure-1.png)

Actual NOAA BlueTopo source data: New York Harbor elevation with
hillshade, contours, and AOI outline.

When native source grids differ, the result can be a
`SpatRasterCollection`. Each member can still be file-backed by verified
original assets.
