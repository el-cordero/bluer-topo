# Discover Tiles and Coverage

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

This example shows how an AOI intersects BlueTopo-style tile footprints
and how coverage diagnostics are reported. The fixture-only
`bluertopo.allow_test_hosts = TRUE` option enables local `file://`
assets; it is not part of normal live NOAA workflows.

## Selected Tiles

``` r

tiles <- bluertopo_tiles(
  example_aoi,
  resolution = "native",
  coverage = "warn",
  quiet = TRUE
)
```

``` r

bt_display_table(bt_tile_table(tiles))
```

| tile_id | resolution_m | utm_zone | delivered_date | intersection_area_m2 | intersection_fraction | selection_rank | selection_reason | fallback |
|:---|---:|:---|:---|---:|---:|---:|:---|:---|
| TILE_FINE_A | 4 | 18 | 2026-01-15 | 6923621557 | 0.562 | 1 | native | FALSE |
| TILE_COARSE_B | 8 | 18 | 2025-07-15 | 9231598597 | 0.750 | 2 | native | FALSE |
| TILE_UTM_C | 16 | 19 | 2024-10-15 | 5538868590 | 0.556 | 3 | native | FALSE |

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

bt_plot_tiles(tiles, example_aoi, main = "AOI intersection with selected tiles")
```

![AOI outline over selected synthetic BlueTopo tile
footprints.](example-discover-tiles_files/figure-html/footprint-figure-1.png)

Synthetic miniature BlueTopo fixture for package demonstration: AOI and
selected tile footprints.

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

Synthetic miniature BlueTopo fixture for package demonstration: coverage
fractions.

Coverage is geometric tile-index coverage. It is not a statement about
data quality, navigational fitness, or vertical-datum compatibility.
