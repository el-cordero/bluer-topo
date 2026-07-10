# Layers and RAT Metadata

This page uses real NOAA BlueTopo source tiles when rendered for the
public pkgdown site. This example uses actual NOAA BlueTopo source tiles
downloaded from the public NOAA National Bathymetric Source bucket
during the pkgdown build.

This page opens real New York Harbor NOAA BlueTopo elevation,
uncertainty, and contributor layers from verified source GeoTIFFs, then
reads real RAT sidecars for contributor metadata. Elevation is shown
with hillshade and contours; uncertainty and contributor IDs are plotted
as their own source layers.

BlueTopo is not for navigation. No vertical-datum conversion is
performed. The contributor band contains IDs, not continuous values.
Contributor IDs must not be averaged. RAT sidecars carry contributor
metadata, and `bluertopo` preserves original RAT files.

## Real Example Setup

``` r

library(terra)
#> terra 1.9.34

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
| BH4XC5FK | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml | package-cache/tiles/BH4XC5FK/BlueTopo_BH4XC5FK_20260624.tiff.aux.xml | TRUE | 21405b45e162 |
| BH4XD5FK | BlueTopo_BH4XD5FK_20260624.tiff.aux.xml | package-cache/tiles/BH4XD5FK/BlueTopo_BH4XD5FK_20260624.tiff.aux.xml | TRUE | 59814a3e330c |

## Contributor Lookup

``` r

contributor_lookup <- bt_parse_rat(rat_manifest$local_path)
bt_display_table(contributor_lookup)
```

| contributor_value | source_survey_id | source_institution | license_name | survey_date_start | survey_date_end | coverage | bathy_coverage | rat_source |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 0 | NBS Generalization | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 1807-02-10 | 1807-02-10 | 0 | 0 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 104981 | H11395_Xof2.combined | DOC/NOAA/NOS/OCS – Office of Coast Survey | CC0-1.0 | 2005-03-17 | 2006-03-20 | 0 | 0 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 43868 | H05609 | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 1934-01-01 | 1934-01-01 | 1 | 1 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 38388 | F00463 | DOC/NOAA/NOS/OCS – Office of Coast Survey | cc0-1.0 | 2000-01-01 | 2000-01-01 | 1 | 1 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 104992 | F00630_MB_50cm_MLLW_1of1.interpolated | DOC/NOAA/NOS/OCS – Office of Coast Survey | CC0-1.0 | 2013-04-17 | 2013-04-29 | 1 | 0 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 104997 | H11395_VB_2m_MLLW_1of2 | DOC/NOAA/NOS/OCS – Office of Coast Survey | CC0-1.0 | 2005-03-17 | 2006-03-20 | 1 | 1 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 8987 | NY_02_ANC_20220104_CS_5127_45 | DOD/USACE – US Army Corps of Engineers New York District | cc0-1.0 | 2022-01-04 | 2022-01-04 | 1 | 1 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 56695 | NY_02_ANC_20140806_CS_4158_45X.interpolated | DOD/USACE – US Army Corps of Engineers New York District | cc0-1.0 | 2014-08-06 | 2014-08-06 | 0 | 0 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 105004 | F00623_VB_4m_MLLW_3of3 | DOC/NOAA/NOS/OCS – Office of Coast Survey | CC0-1.0 | 2012-11-01 | 2012-11-06 | 1 | 1 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 1540179 | HD_01_HUD_20211025_CS_5106_45 | DOD/USACE – US Army Corps of Engineers New York District | cc0-1.0 | 2021-10-25 | 2021-10-25 | 1 | 1 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 1542117 | NJ_06_KVK_20211108_CS_5110_30 | DOD/USACE – US Army Corps of Engineers New York District | cc0-1.0 | 2021-11-08 | 2021-11-08 | 1 | 1 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| 56712 | NJ_06_KVK_20211108_CS_5110_30.interpolated | DOD/USACE – US Army Corps of Engineers New York District | cc0-1.0 | 2021-11-08 | 2021-11-08 | 0 | 0 | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |

## Elevation

``` r

first_grid <- bt_rasters(all_layers$data)[[1L]]
bt_plot_bathy_map(first_grid[["elevation"]], real_aoi, main = "New York Harbor elevation")
```

![Hillshaded real BlueTopo elevation layer with
contours.](example-layers-rat_files/figure-html/elevation-plot-1.png)

Actual NOAA BlueTopo source data: New York Harbor elevation layer with
hillshade and contours.

## Uncertainty

``` r

terra::plot(first_grid[["uncertainty"]], main = "Uncertainty", col = grDevices::hcl.colors(80, "BluYl"))
terra::plot(terra::project(real_aoi, terra::crs(first_grid)), add = TRUE, border = "#d00000", lwd = 2)
```

![Real BlueTopo uncertainty
raster.](example-layers-rat_files/figure-html/uncertainty-plot-1.png)

Actual NOAA BlueTopo source data: uncertainty layer.

## Contributor IDs

``` r

terra::plot(first_grid[["contributor"]], main = "Contributor IDs", col = hcl.colors(12, "Dark 3"))
terra::plot(terra::project(real_aoi, terra::crs(first_grid)), add = TRUE, border = "#d00000", lwd = 2)
```

![Real BlueTopo contributor ID raster using categorical
colors.](example-layers-rat_files/figure-html/contributor-plot-1.png)

Actual NOAA BlueTopo source data: contributor ID layer shown with
categorical colors.

Contributor values are identifiers that point into RAT metadata. They
are not continuous terrain values.
