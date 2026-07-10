# Example Gallery

``` r

library(terra)
#> terra 1.9.27

example <- bt_example_setup()
#> Synthetic miniature BlueTopo fixture for package demonstration.
#> Fixture-only option: bluertopo.allow_test_hosts = TRUE enables local file URLs.
example_root <- example$root
example_catalog <- example$catalog
example_aoi <- example$aoi
```

Every rendered output on this page uses: **Synthetic miniature BlueTopo
fixture for package demonstration.**

BlueTopo is not for navigation. `bluertopo` performs no vertical-datum
conversion. `resolution` selects native source tiles;
`output_resolution` resamples onto an explicit output grid.

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
    "Verified original GeoTIFF and RAT sidecar assets",
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
| Download original assets | bluertopo_download() | Verified original GeoTIFF and RAT sidecar assets | Manifest tables and status figure |
| Extract elevation with terra | bluertopo() | File-backed terra object and provenance | terra summary tables and raster figure |
| Compare resolution policies | bluertopo_tiles() | Native source-resolution selection effects | Policy comparison tables and maps |
| Mixed grids and output grid | bluertopo() | SpatRasterCollection versus explicit output grid | Grid summary tables and raster figure |
| Layers and RAT metadata | bluertopo() | Elevation, uncertainty, contributor IDs, and RAT metadata | Layer/RAT tables and raster figures |

## Fixture Tile Footprints

``` r

tiles <- bluertopo_tiles(example_aoi, coverage = "fill", quiet = TRUE)
bt_plot_tiles(tiles, example_aoi, main = "Synthetic fixture tile footprints")
```

![Synthetic fixture AOI outline over three BlueTopo-style tile
footprints colored by native source
resolution.](examples_files/figure-html/tile-footprints-1.png)

Synthetic miniature BlueTopo fixture for package demonstration: AOI
outline and tile footprints by native source resolution.

``` r

tiles_df <- as.data.frame(tiles)
bt_display_table(
  tiles_df[c("tile_id", "resolution_m", "utm_zone", "selection_reason", "fallback")]
)
```

| tile_id       | resolution_m | utm_zone | selection_reason | fallback |
|:--------------|-------------:|:---------|:-----------------|:---------|
| TILE_FINE_A   |            4 | 18       | native           | FALSE    |
| TILE_COARSE_B |            8 | 18       | native           | FALSE    |
| TILE_UTM_C    |           16 | 19       | native           | FALSE    |

## Terra Preview

``` r

preview <- bluertopo(
  example_aoi,
  layers = "elevation",
  resolution = 4,
  coverage = "ignore",
  details = TRUE,
  progress = FALSE
)

terra::plot(preview$data, main = "Synthetic fixture elevation")
```

![Small synthetic elevation raster preview from the packaged
fixture.](examples_files/figure-html/terra-preview-1.png)

Synthetic miniature BlueTopo fixture for package demonstration:
elevation raster preview from one source tile.

The preview is intentionally small and local. It proves the package
workflow without downloading NOAA data during documentation builds.
