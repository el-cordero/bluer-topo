# Discover Tiles and Coverage

This page uses real NOAA BlueTopo source tiles when rendered for the
public pkgdown site. This example uses actual NOAA BlueTopo source tiles
downloaded from the public NOAA National Bathymetric Source bucket
during the pkgdown build.

This page discovers the two real NOAA BlueTopo tiles selected for New
York Harbor, reports coverage diagnostics, and renders a locator map
with the AOI, tile footprints, and native-resolution labels.

BlueTopo is not for navigation. No vertical-datum conversion is
performed. Coverage is geometric tile-index coverage, not a statement
about navigational fitness, data quality, or NOAA endorsement.

## Real Example Setup

``` r

library(terra)
#> terra 1.9.34

real <- bt_real_example_setup()
real_aoi <- real$aoi
```

## Selected Tiles

``` r

tiles <- bluertopo_tiles(
  real_aoi,
  resolution = "native",
  coverage = "warn",
  quiet = TRUE
)
```

``` r

bt_display_table(bt_tile_table(tiles, include_urls = TRUE))
```

| tile_id | resolution_m | utm_zone | delivered_date | intersection_area_m2 | intersection_fraction | selection_rank | selection_reason | fallback | geotiff_url | rat_url |
|:---|---:|:---|:---|---:|---:|---:|:---|:---|:---|:---|
| BH4XC5FK | 4 | 18 | 2026-06-25 10:51:01 | 7508785 | 0.142 | 1 | native | FALSE | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XC5FK/BlueTopo_BH4XC5FK_20260624.tiff | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XC5FK/BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| BH4XD5FK | 4 | 18 | 2026-06-25 10:50:52 | 11263177 | 0.213 | 2 | native | FALSE | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XD5FK/BlueTopo_BH4XD5FK_20260624.tiff | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XD5FK/BlueTopo_BH4XD5FK_20260624.tiff.aux.xml |

## Coverage Diagnostics

``` r

coverage <- attr(tiles, "coverage")
bt_display_table(bt_coverage_table(coverage))
```

| published_coverage_fraction | selected_coverage_fraction | selected_aoi_fraction | target_coverage | target_met | coverage_type |
|---:|---:|---:|---:|:---|:---|
| 1 | 1 | 1 | 1 | TRUE | geometric tile-index coverage |

## AOI And Selected Footprints

``` r

bt_plot_locator_map(
  tiles,
  real_aoi,
  place_label = real$place,
  main = "New York Harbor AOI and NOAA BlueTopo tiles"
)
```

![Real BlueTopo tile footprints selected for the example
AOI.](example-discover-tiles_files/figure-html/footprint-figure-1.png)

Actual NOAA BlueTopo source tiles: AOI outline over selected tile
footprints colored by native resolution.

## Coverage Fractions

``` r

coverage_values <- unlist(coverage[c(
  "published_coverage_fraction",
  "selected_coverage_fraction",
  "selected_aoi_fraction",
  "target_coverage"
)])
barplot(
  coverage_values,
  ylim = c(0, 1),
  col = c("#8ecae6", "#90be6d", "#f9c74f", "#d00000"),
  las = 2,
  ylab = "fraction",
  main = "Coverage diagnostics"
)
abline(h = coverage$target_coverage, col = "#d00000", lwd = 2, lty = 2)
```

![Bar plot of published coverage, selected coverage, selected AOI
fraction, and target
coverage.](example-discover-tiles_files/figure-html/coverage-bars-1.png)

Actual NOAA BlueTopo source tiles: coverage fractions for the selected
AOI.

The selected tile table includes shortened NOAA GeoTIFF and RAT URLs so
users can see that discovery is using the live BlueTopo catalog records.
