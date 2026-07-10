# Layers and RAT Metadata

This page uses real NOAA BlueTopo source tiles when rendered for the
public pkgdown site. This example uses actual NOAA BlueTopo source tiles
downloaded from the public NOAA National Bathymetric Source bucket
during the pkgdown build.

BlueTopo is not for navigation. No vertical-datum conversion is
performed. The contributor band contains IDs, not continuous values.
Contributor IDs must not be averaged. RAT sidecars carry contributor
metadata, and `bluertopo` preserves original RAT files.

## Real Example Setup

``` r

library(terra)
#> terra 1.9.27

real <- bt_real_example_setup()
real_aoi <- real$aoi
```

## All Layers

``` r

all_layers <- bluertopo(
  real_aoi,
  layers = "all",
  coverage = "fill",
  details = TRUE,
  progress = FALSE,
  quiet = TRUE
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
  `default resampling rule` = c(
    "bilinear only when an explicit output grid is requested",
    "bilinear only when an explicit output grid is requested; values are then resampled",
    "nearest-neighbor only; never average contributor IDs"
  ),
  check.names = FALSE
)

bt_display_table(layer_table)
```

| layer | source band | meaning | default resampling rule |
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

| tile_id | source_basename | local_path | verified | actual_sha256 |
|:---|:---|:---|:---|:---|
| BH4SH55P | BlueTopo_BH4SH55P_20241212.tiff.aux.xml | package-cache/tiles/BH4SH55P/BlueTopo_BH4SH55P_20241212.tiff.aux.xml | TRUE | f2a5a151b745 |
| BH4SJ55P | BlueTopo_BH4SJ55P_20241004.tiff.aux.xml | package-cache/tiles/BH4SJ55P/BlueTopo_BH4SJ55P_20241004.tiff.aux.xml | TRUE | f3af3107d74d |
| BF2H62K7 | BlueTopo_BF2H62K7_20241212.tiff.aux.xml | package-cache/tiles/BF2H62K7/BlueTopo_BF2H62K7_20241212.tiff.aux.xml | TRUE | ea4bba3b305f |

## Contributor Lookup

``` r

contributor_lookup <- bt_parse_rat(rat_manifest$local_path)
bt_display_table(contributor_lookup)
```

| contributor_value | source_survey_id | source_institution | license_name | survey_date_start | survey_date_end | coverage | bathy_coverage | rat_source |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 49550 | H08626 | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 1961-01-01 | 1961-01-01 | 1 | 1 | BlueTopo_BH4SH55P_20241212.tiff.aux.xml |
| 51975 | H08626.interpolated | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 1961-01-01 | 1961-01-01 | 0 | 0 | BlueTopo_BH4SH55P_20241212.tiff.aux.xml |
| 29777 | H12193_4m_MLLW_Xof9.combined | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 2010-07-09 | 2010-08-24 | 1 | 0 | BlueTopo_BH4SH55P_20241212.tiff.aux.xml |
| 201512 | H12193_VB_4m_MLLW_1of9 | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 2010-07-09 | 2010-08-24 | 1 | 1 | BlueTopo_BH4SH55P_20241212.tiff.aux.xml |
| 201594 | W00406_MB_2m_MLLW_1of4 | DOC/NOAA/NOS/ONMS – Office of National Marine Sanctuaries | cc0-1.0 | 2015-06-07 | 2015-06-12 | 1 | 1 | BlueTopo_BH4SH55P_20241212.tiff.aux.xml |
| 201508 | H12193_MB_50cm_MLLW_6of9 | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 2010-07-09 | 2010-08-24 | 1 | 1 | BlueTopo_BH4SH55P_20241212.tiff.aux.xml |
| 29819 | H12193_MB_50cm_MLLW_7of9 | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 2010-07-09 | 2010-08-24 | 1 | 1 | BlueTopo_BH4SH55P_20241212.tiff.aux.xml |
| 29782 | H12193_MB_2m_MLLW_2of9 | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 2010-07-09 | 2010-08-24 | 1 | 1 | BlueTopo_BH4SH55P_20241212.tiff.aux.xml |
| 201507 | H12193_MB_50cm_MLLW_5of9 | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 2010-07-09 | 2010-08-24 | 1 | 1 | BlueTopo_BH4SH55P_20241212.tiff.aux.xml |
| 201594 | W00406_MB_2m_MLLW_1of4 | DOC/NOAA/NOS/ONMS – Office of National Marine Sanctuaries | cc0-1.0 | 2015-06-07 | 2015-06-12 | 1 | 1 | BlueTopo_BH4SJ55P_20241004.tiff.aux.xml |
| 49550 | H08626 | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 1961-01-01 | 1961-01-01 | 1 | 1 | BlueTopo_BH4SJ55P_20241004.tiff.aux.xml |
| 51975 | H08626.interpolated | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 1961-01-01 | 1961-01-01 | 0 | 0 | BlueTopo_BH4SJ55P_20241004.tiff.aux.xml |

## Elevation

``` r

first_grid <- bt_rasters(all_layers$data)[[1L]]
terra::plot(first_grid[["elevation"]], main = "Elevation")
```

![Real BlueTopo elevation
raster.](example-layers-rat_files/figure-html/elevation-plot-1.png)

Actual NOAA BlueTopo source data: elevation layer.

## Uncertainty

``` r

terra::plot(first_grid[["uncertainty"]], main = "Uncertainty")
```

![Real BlueTopo uncertainty
raster.](example-layers-rat_files/figure-html/uncertainty-plot-1.png)

Actual NOAA BlueTopo source data: uncertainty layer.

## Contributor IDs

``` r

terra::plot(first_grid[["contributor"]], main = "Contributor IDs", col = hcl.colors(12, "Dark 3"))
```

![Real BlueTopo contributor ID raster using categorical
colors.](example-layers-rat_files/figure-html/contributor-plot-1.png)

Actual NOAA BlueTopo source data: contributor ID layer shown with
categorical colors.

Contributor values are identifiers that point into RAT metadata. They
are not continuous terrain values.
