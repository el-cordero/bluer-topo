# Layers and RAT metadata

This example uses BlueTopo source tiles from the National Bathymetric
Source catalog. The build verifies the downloaded assets and records
their source metadata.

This example uses BlueTopo tiles covering New York Harbor. The workflow
demonstrates tile discovery, checksum-verified asset retrieval, and
file-backed raster access with `terra`. It opens elevation, uncertainty,
and contributor layers, then reads Raster Attribute Table (RAT) sidecars
for contributor metadata. Elevation is shown with hillshade and
contours; uncertainty and contributor IDs are plotted as their own
source layers.

The contributor band contains IDs, not continuous values. Contributor
IDs must not be averaged. RAT sidecars carry contributor metadata, and
`bluertopo` preserves original RAT files.

## Example area

## All layers

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

| layer | source band | meaning | default resampling rule |
|:---|---:|:---|:---|
| elevation | 1 | source elevation values | bilinear only when an explicit output grid is requested |
| uncertainty | 2 | source vertical uncertainty values | bilinear only when an explicit output grid is requested; values are then resampled |
| contributor | 3 | categorical contributor/source IDs | nearest-neighbor only; never average contributor IDs |

## RAT sidecar manifest

| Tile ID | Source file | Local path | Verified | SHA-256 |
|:---|:---|:---|:---|:---|
| BH4XC5FK | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml | package-cache/tiles/BH4XC5FK/BlueTopo_BH4XC5FK_20260624.tiff.aux.xml | Yes | 21405b45e162 |
| BH4XD5FK | BlueTopo_BH4XD5FK_20260624.tiff.aux.xml | package-cache/tiles/BH4XD5FK/BlueTopo_BH4XD5FK_20260624.tiff.aux.xml | Yes | 59814a3e330c |

## Contributor lookup

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

![BlueTopo bathymetry for New York Harbor with hillshade, contours, and
the example-area
boundary.](example-layers-rat_files/figure-html/elevation-plot-1.png)

BlueTopo bathymetry for New York Harbor, displayed with hillshade,
contours, and the example-area boundary.

## Uncertainty

![BlueTopo uncertainty raster for the selected New York Harbor
tiles.](example-layers-rat_files/figure-html/uncertainty-plot-1.png)

BlueTopo uncertainty for the selected New York Harbor tiles.

## Contributor IDs

![BlueTopo contributor identifier raster shown with categorical
colors.](example-layers-rat_files/figure-html/contributor-plot-1.png)

Contributor identifiers for the selected New York Harbor tiles.

Contributor values are identifiers that point into RAT metadata. They
are not continuous terrain values.
