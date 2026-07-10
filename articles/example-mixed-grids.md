# Mixed Grids and Output Grid

``` r

library(terra)
#> terra 1.9.27

example <- bt_example_setup()
#> Synthetic miniature BlueTopo fixture for package demonstration.
#> Fixture-only option: bluertopo.allow_test_hosts = TRUE enables local file URLs.
example_aoi <- example$aoi
```

Every rendered output on this page uses: **Synthetic miniature BlueTopo
fixture for package demonstration.**

Mixed native grids are preserved unless the user asks for a single
output grid. `combine = "single"` needs an explicit output grid when
native grids are incompatible. Resampled uncertainty values are not
original source cells, and contributor resampling must be
nearest-neighbor.

## Native Mixed-Grid Extraction

``` r

native <- bluertopo(
  example_aoi,
  resolution = "native",
  coverage = "fill",
  combine = "auto",
  details = TRUE,
  progress = FALSE
)
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
| SpatRasterCollection | grid_01_epsg4326_0_25x0_25 | EPSG:4326 | 0.25 x 0.25 | 1 | elevation |
| SpatRasterCollection | grid_02_epsg4326_0_5x0_5 | EPSG:4326 | 0.5 x 0.5 | 1 | elevation |
| SpatRasterCollection | grid_03_epsg3857_33395_85x33397_46 | EPSG:3857 | 33395.847 x 33397.462 | 1 | elevation |

## Native Grid Footprints

``` r

native_tiles <- native$tiles
bt_plot_tiles(native_tiles, example_aoi, main = "Selected mixed native grids")
```

![Synthetic fixture tile footprints selected for mixed native
grids.](example-mixed-grids_files/figure-html/native-footprints-1.png)

Synthetic miniature BlueTopo fixture for package demonstration: native
grid footprints selected for the mixed-grid extraction.

## Explicit Single Output Grid

``` r

single <- suppressWarnings(bluertopo(
  example_aoi,
  resolution = "native",
  coverage = "fill",
  output_crs = "EPSG:3857",
  output_resolution = 50000,
  combine = "single",
  details = TRUE,
  progress = FALSE
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
| SpatRaster | EPSG:3857 | 50000 x 50000 | 27829.9, 177829.9, 16697.9, 116697.9 | TRUE |

``` r

terra::plot(single$data, main = "Explicit output grid elevation")
```

![Synthetic fixture elevation raster on one explicit output
grid.](example-mixed-grids_files/figure-html/output-raster-1.png)

Synthetic miniature BlueTopo fixture for package demonstration:
elevation resampled onto an explicit output grid.

The explicit grid is useful for workflows that require one raster, but
it is a resampling operation. Native source-resolution selection remains
separate from output-grid creation.
