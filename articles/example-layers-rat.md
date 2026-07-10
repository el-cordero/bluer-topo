# Layers and RAT Metadata

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

The contributor band contains IDs, not continuous values. Contributor
IDs must not be averaged. RAT sidecars carry contributor metadata, and
`bluertopo` preserves original RAT files.

## All Layers

``` r

all_layers <- bluertopo(
  example_aoi,
  layers = "all",
  coverage = "fill",
  details = TRUE,
  progress = FALSE
)
```

``` r

layer_table <- data.frame(
  layer = c("elevation", "uncertainty", "contributor"),
  `source band` = c(1L, 2L, 3L),
  meaning = c(
    "source elevation values",
    "source vertical uncertainty values",
    "categorical contributor/source IDs"
  ),
  `resampling rule` = c(
    "bilinear only when an explicit output grid is requested",
    "bilinear only when an explicit output grid is requested; values are then resampled",
    "nearest-neighbor only; never average contributor IDs"
  ),
  check.names = FALSE
)

bt_display_table(layer_table)
```

| layer | source band | meaning | resampling rule |
|:---|---:|:---|:---|
| elevation | 1 | source elevation values | bilinear only when an explicit output grid is requested |
| uncertainty | 2 | source vertical uncertainty values | bilinear only when an explicit output grid is requested; values are then resampled |
| contributor | 3 | categorical contributor/source IDs | nearest-neighbor only; never average contributor IDs |

## RAT Sidecar Manifest

``` r

rat_manifest <- as.data.frame(all_layers$downloads)
rat_manifest <- rat_manifest[rat_manifest$asset_type == "rat", , drop = FALSE]
rat_table <- data.frame(
  tile_id = rat_manifest$tile_id,
  source_basename = rat_manifest$source_basename,
  local_path = bt_short_path(rat_manifest$local_path, keep = 4L),
  verified = rat_manifest$verified,
  actual_sha256 = bt_short_sha(rat_manifest$actual_sha256),
  stringsAsFactors = FALSE
)

bt_display_table(rat_table)
```

|  | tile_id | source_basename | local_path | verified | actual_sha256 |
|:---|:---|:---|:---|:---|:---|
| /private/var/folders/7j/dr505g_j3zd9z6m9qdykzc4w0000gn/T/RtmptFBf17/bluertopo-example-cache/tiles/TILE_FINE_A/BlueTopo_TILE_FINE_A.tiff.aux.xml | TILE_FINE_A | BlueTopo_TILE_FINE_A.tiff.aux.xml | bluertopo-example-cache/tiles/TILE_FINE_A/BlueTopo_TILE_FINE_A.tiff.aux.xml | TRUE | 18905bdd9e1b |
| /private/var/folders/7j/dr505g_j3zd9z6m9qdykzc4w0000gn/T/RtmptFBf17/bluertopo-example-cache/tiles/TILE_COARSE_B/BlueTopo_TILE_COARSE_B.tiff.aux.xml | TILE_COARSE_B | BlueTopo_TILE_COARSE_B.tiff.aux.xml | bluertopo-example-cache/tiles/TILE_COARSE_B/BlueTopo_TILE_COARSE_B.tiff.aux.xml | TRUE | d60feb25cf39 |
| /private/var/folders/7j/dr505g_j3zd9z6m9qdykzc4w0000gn/T/RtmptFBf17/bluertopo-example-cache/tiles/TILE_UTM_C/BlueTopo_TILE_UTM_C.tiff.aux.xml | TILE_UTM_C | BlueTopo_TILE_UTM_C.tiff.aux.xml | bluertopo-example-cache/tiles/TILE_UTM_C/BlueTopo_TILE_UTM_C.tiff.aux.xml | TRUE | 7fe027d87e35 |

## Contributor Lookup

``` r

contributor_lookup <- bt_parse_rat(rat_manifest$local_path)
bt_display_table(contributor_lookup)
```

| contributor_id | source_survey_id | source_institution | source_type |
|---:|:---|:---|:---|
| 101 | SYN_FINE_A_2024_A | Synthetic Coastal Survey Office | synthetic multibeam |
| 102 | SYN_FINE_A_2024_B | Synthetic University Lab | synthetic lidar |
| 201 | SYN_COARSE_B_2023_A | Synthetic NOAA Partner | synthetic chart compilation |
| 202 | SYN_COARSE_B_2023_B | Synthetic Coastal Survey Office | synthetic multibeam |
| 301 | SYN_UTM_C_2022_A | Synthetic Hydrographic Branch | synthetic multibeam |
| 302 | SYN_UTM_C_2022_B | Synthetic Academic Partner | synthetic backscatter classification |

## Elevation

``` r

first_grid <- bt_rasters(all_layers$data)[[1L]]
terra::plot(first_grid[["elevation"]], main = "Elevation")
```

![Synthetic fixture elevation
raster.](example-layers-rat_files/figure-html/elevation-plot-1.png)

Synthetic miniature BlueTopo fixture for package demonstration:
elevation layer.

## Uncertainty

``` r

terra::plot(first_grid[["uncertainty"]], main = "Uncertainty")
```

![Synthetic fixture uncertainty
raster.](example-layers-rat_files/figure-html/uncertainty-plot-1.png)

Synthetic miniature BlueTopo fixture for package demonstration:
uncertainty layer.

## Contributor IDs

``` r

terra::plot(first_grid[["contributor"]], main = "Contributor IDs")
```

![Synthetic fixture contributor ID
raster.](example-layers-rat_files/figure-html/contributor-plot-1.png)

Synthetic miniature BlueTopo fixture for package demonstration:
contributor ID layer.

These sidecars are synthetic and compact, but they demonstrate the
package boundary: original RAT files are verified and preserved, while
interpretation of contributor IDs remains a metadata step.
