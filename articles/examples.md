# Example Gallery

This page uses real NOAA BlueTopo source tiles when rendered for the
public pkgdown site. This example uses actual NOAA BlueTopo source tiles
downloaded from the public NOAA National Bathymetric Source bucket
during the pkgdown build.

This gallery downloads two real NOAA BlueTopo tiles for New York Harbor,
verifies the GeoTIFF and RAT checksums, opens the elevation band with
`terra`, and renders a hillshaded bathymetry map with contour lines.

BlueTopo is not for navigation. `bluertopo` performs no vertical-datum
conversion. The example downloads are intentionally small. Normal
package tests use synthetic fixtures; the public site uses real data.
`bluertopo` is not affiliated with, endorsed by, or supported by NOAA.

## What The Examples Show

``` r

gallery <- data.frame(
  Example = c(
    "Discover tiles and coverage",
    "Download original assets",
    "Extract elevation with terra",
    "Compare resolution policies",
    "Mixed grids and output grid",
    "Layers and RAT metadata"
  ),
  `Main function` = c(
    "bluertopo_tiles()",
    "bluertopo_download()",
    "bluertopo()",
    "bluertopo_tiles()",
    "bluertopo()",
    "bluertopo()"
  ),
  Shows = c(
    "AOI intersection, selected footprints, coverage diagnostics",
    "Verified NOAA GeoTIFF and RAT sidecar assets",
    "File-backed terra object and provenance",
    "Native source-resolution selection effects",
    "SpatRasterCollection versus explicit output grid",
    "Elevation, uncertainty, contributor IDs, and RAT metadata"
  ),
  `Output type` = c(
    "Tables and footprint figure",
    "Manifest tables and status figure",
    "terra summary tables and raster figure",
    "Policy comparison tables and maps",
    "Grid summary tables and raster figure",
    "Layer/RAT tables and raster figures"
  ),
  check.names = FALSE
)

bt_display_table(gallery)
```

| Example | Main function | Shows | Output type |
|:---|:---|:---|:---|
| Discover tiles and coverage | bluertopo_tiles() | AOI intersection, selected footprints, coverage diagnostics | Tables and footprint figure |
| Download original assets | bluertopo_download() | Verified NOAA GeoTIFF and RAT sidecar assets | Manifest tables and status figure |
| Extract elevation with terra | bluertopo() | File-backed terra object and provenance | terra summary tables and raster figure |
| Compare resolution policies | bluertopo_tiles() | Native source-resolution selection effects | Policy comparison tables and maps |
| Mixed grids and output grid | bluertopo() | SpatRasterCollection versus explicit output grid | Grid summary tables and raster figure |
| Layers and RAT metadata | bluertopo() | Elevation, uncertainty, contributor IDs, and RAT metadata | Layer/RAT tables and raster figures |

## Real Example Setup

``` r

library(terra)
#> terra 1.9.34

real <- bt_real_example_setup()
real_aoi <- real$aoi
real_tiles <- real$tiles
```

## Locator Map

``` r

bt_plot_locator_map(
  real_tiles,
  real_aoi,
  place_label = real$place,
  main = "New York Harbor real BlueTopo tile footprints"
)
```

![Real BlueTopo tile footprints colored by native source resolution with
the example AOI
outline.](examples_files/figure-html/tile-footprints-1.png)

Actual NOAA BlueTopo source tiles: AOI outline and selected tile
footprints by native source resolution.

``` r

bt_display_table(bt_tile_table(real_tiles, include_urls = TRUE))
```

| tile_id | resolution_m | utm_zone | delivered_date | intersection_area_m2 | intersection_fraction | selection_rank | selection_reason | fallback | geotiff_url | rat_url |
|:---|---:|:---|:---|---:|---:|---:|:---|:---|:---|:---|
| BH4XC5FK | 4 | 18 | 2026-06-25 10:51:01 | 7508785 | 0.142 | 1 | native | FALSE | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XC5FK/BlueTopo_BH4XC5FK_20260624.tiff | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XC5FK/BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| BH4XD5FK | 4 | 18 | 2026-06-25 10:50:52 | 11263177 | 0.213 | 2 | native | FALSE | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XD5FK/BlueTopo_BH4XD5FK_20260624.tiff | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XD5FK/BlueTopo_BH4XD5FK_20260624.tiff.aux.xml |

## Download Plan

``` r

planned <- real$planned_assets
planned$planned_mb <- bt_bytes_mb(planned$planned_bytes)
bt_display_table(planned[c("tile_id", "asset_type", "source_basename", "planned_mb")])
```

| tile_id  | asset_type | source_basename                         | planned_mb |
|:---------|:-----------|:----------------------------------------|-----------:|
| BH4XC5FK | geotiff    | BlueTopo_BH4XC5FK_20260624.tiff         |      5.393 |
| BH4XD5FK | geotiff    | BlueTopo_BH4XD5FK_20260624.tiff         |      4.093 |
| BH4XC5FK | rat        | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |      0.104 |
| BH4XD5FK | rat        | BlueTopo_BH4XD5FK_20260624.tiff.aux.xml |      0.067 |

## Terra Preview

``` r

preview <- bluertopo(
  real_aoi,
  layers = "elevation",
  resolution = "native",
  coverage = "fill",
  details = TRUE,
  progress = FALSE,
  quiet = TRUE
)

bt_plot_bathy_map(preview$data, real_aoi, main = "New York Harbor NOAA BlueTopo bathymetry")
```

![Hillshaded real NOAA BlueTopo elevation raster with contours for New
York Harbor.](examples_files/figure-html/terra-preview-1.png)

Actual NOAA BlueTopo source data: New York Harbor elevation with
hillshade, contours, and AOI outline.

`resolution` selects native source tiles. `output_resolution` is used
only when the user explicitly requests an output grid.
