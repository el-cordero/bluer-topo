# Mixed Grids and Output Grid

This page uses real NOAA BlueTopo source tiles when rendered for the
public pkgdown site. This example uses actual NOAA BlueTopo source tiles
downloaded from the public NOAA National Bathymetric Source bucket
during the pkgdown build.

BlueTopo is not for navigation. No vertical-datum conversion is
performed. Mixed native grids are preserved unless the user asks for a
single output grid. `combine = "single"` needs an explicit output grid
when native grids are incompatible. Resampled uncertainty values are not
original source cells, and contributor resampling must be
nearest-neighbor.

## Real Example Setup

``` r

library(terra)
#> terra 1.9.27

real <- bt_real_example_setup()
real_aoi <- real$aoi
```

## Native Mixed-Grid Extraction

``` r

native <- bluertopo(
  real_aoi,
  resolution = "native",
  coverage = "fill",
  combine = "auto",
  details = TRUE,
  progress = FALSE,
  quiet = TRUE
)

if (!inherits(native$data, "SpatRasterCollection")) {
  stop("The documented real AOI no longer produces mixed native grids.", call. = FALSE)
}
```

``` r

native_table <- bt_raster_summary(native$data)
native_table$output_object_class <- paste(class(native$data), collapse = ", ")
native_table <- native_table[c(
  "output_object_class",
  "group_name",
  "crs",
  "resolution",
  "source_count",
  "layer_names"
)]

bt_display_table(native_table)
```

| output_object_class | group_name | crs | resolution | source_count | layer_names |
|:---|:---|:---|:---|---:|:---|
| SpatRasterCollection | grid_01_epsg26917_4x4 | EPSG:26917 | 4 x 4 | 1 | elevation |
| SpatRasterCollection | grid_02_epsg26917_8x8 | EPSG:26917 | 8 x 8 | 1 | elevation |

## Native Grid Footprints

``` r

bt_plot_tiles(native$tiles, real_aoi, main = "Selected mixed native grids")
```

![Real BlueTopo tile footprints selected for mixed native
grids.](example-mixed-grids_files/figure-html/native-footprints-1.png)

Actual NOAA BlueTopo source tiles: native grid footprints selected for
mixed-grid extraction.

## Explicit Single Output Grid

``` r

single <- suppressWarnings(bluertopo(
  real_aoi,
  layers = "elevation",
  resolution = "native",
  coverage = "fill",
  output_crs = "EPSG:26917",
  output_resolution = 100,
  combine = "single",
  details = TRUE,
  progress = FALSE,
  quiet = TRUE
))
```

``` r

single_raster <- single$data
single_table <- data.frame(
  output_object_class = paste(class(single_raster), collapse = ", "),
  crs = paste0("EPSG:", terra::crs(single_raster, describe = TRUE)$code),
  resolution = paste(round(terra::res(single_raster), 3), collapse = " x "),
  extent = paste(round(as.vector(terra::ext(single_raster)), 1), collapse = ", "),
  resampled_flag = attr(single_raster, "bluertopo_resampled") %in% TRUE,
  stringsAsFactors = FALSE
)

bt_display_table(single_table)
```

| output_object_class | crs | resolution | extent | resampled_flag |
|:---|:---|:---|:---|:---|
| SpatRaster | EPSG:26917 | 100 x 100 | 415613, 418713, 2744703.3, 2748003.3 | TRUE |

``` r

terra::plot(single$data, main = "Explicit output grid elevation")
```

![Real BlueTopo elevation raster on one explicit output
grid.](example-mixed-grids_files/figure-html/output-raster-1.png)

Actual NOAA BlueTopo source data: elevation resampled onto an explicit
output grid.

The explicit grid is useful for workflows that require one raster, but
it is a resampling operation. Native source-resolution selection remains
separate from output-grid creation.
