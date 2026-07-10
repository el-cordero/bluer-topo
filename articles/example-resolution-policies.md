# Compare Resolution Policies

This page uses real NOAA BlueTopo source tiles when rendered for the
public pkgdown site. This example uses actual NOAA BlueTopo source tiles
downloaded from the public NOAA National Bathymetric Source bucket
during the pkgdown build.

This page applies native source-resolution policies to the real New York
Harbor AOI, reports selected tile coverage, and renders policy
footprints. The current New York Harbor example is a compact 4 m
native-resolution plan, so policy differences mainly demonstrate
selection rules rather than a dramatic visual change.

BlueTopo is not for navigation. No vertical-datum conversion is
performed. Smaller meter values mean finer native source resolution.
`resolution` selects source tiles; it does not resample.
`coverage = "fill"` can add fallback source tiles. `output_resolution`
is the argument that changes the output grid.

## Real Example Setup

``` r

library(terra)
#> terra 1.9.34

real <- bt_real_example_setup()
real_aoi <- real$aoi
available_resolution <- sort(unique(as.data.frame(real$tiles)$resolution_m))
exact_available <- max(available_resolution)
```

## Policies

``` r

policies <- list(
  native = list(resolution = "native", coverage = "warn"),
  finest = list(resolution = "finest", coverage = "ignore"),
  `finest + coverage fill` = list(resolution = "finest", coverage = "fill"),
  coarsest = list(resolution = "coarsest", coverage = "ignore"),
  `exact available native resolution` = list(resolution = exact_available, coverage = "ignore"),
  `nearest 6 m` = list(resolution = bluertopo_resolution("nearest", value = 6), coverage = "ignore")
)

policy_tiles <- lapply(policies, function(policy) {
  bluertopo_tiles(
    real_aoi,
    resolution = policy$resolution,
    coverage = policy$coverage,
    quiet = TRUE
  )
})

policy_summary <- do.call(rbind, lapply(names(policy_tiles), function(name) {
  tiles <- policy_tiles[[name]]
  df <- as.data.frame(tiles)
  coverage <- attr(tiles, "coverage")
  data.frame(
    policy = name,
    selected_tile_count = nrow(df),
    selected_resolutions = paste(sort(unique(df$resolution_m)), collapse = ", "),
    selected_coverage_fraction = coverage$selected_coverage_fraction,
    selected_aoi_fraction = coverage$selected_aoi_fraction,
    target_met = coverage$target_met,
    stringsAsFactors = FALSE
  )
}))

bt_display_table(policy_summary)
```

| policy | selected_tile_count | selected_resolutions | selected_coverage_fraction | selected_aoi_fraction | target_met |
|:---|---:|:---|---:|---:|:---|
| native | 2 | 4 | 1 | 1 | TRUE |
| finest | 2 | 4 | 1 | 1 | TRUE |
| finest + coverage fill | 2 | 4 | 1 | 1 | TRUE |
| coarsest | 2 | 4 | 1 | 1 | TRUE |
| exact available native resolution | 2 | 4 | 1 | 1 | TRUE |
| nearest 6 m | 2 | 4 | 1 | 1 | TRUE |

## Tile Selection Maps

``` r

old_par <- par(mfrow = c(2, 3), mar = c(2, 2, 3, 1))
for (name in names(policy_tiles)) {
  bt_plot_tiles(
    policy_tiles[[name]],
    real_aoi,
    main = name,
    place_label = real$place,
    label_resolutions = TRUE
  )
}
```

![Six maps showing real BlueTopo tile selections for native, finest,
coverage fill, coarsest, exact, and nearest
policies.](example-resolution-policies_files/figure-html/policy-maps-1.png)

Actual NOAA BlueTopo source tiles: selected footprints under different
native source-resolution policies.

``` r

par(old_par)
```

## Coverage By Policy

``` r

barplot(
  stats::setNames(policy_summary$selected_coverage_fraction, policy_summary$policy),
  ylim = c(0, 1),
  las = 2,
  col = "#005f73",
  ylab = "selected coverage fraction",
  main = "Coverage by resolution policy"
)
abline(h = 1, col = "#d00000", lwd = 2, lty = 2)
```

![Bar plot comparing selected coverage fractions by native
source-resolution
policy.](example-resolution-policies_files/figure-html/policy-coverage-bars-1.png)

Actual NOAA BlueTopo source tiles: selected coverage fraction by
resolution policy.

Use an explicit output grid only when resampling is intended.

## Elevation Context

``` r

policy_elevation <- bluertopo(
  real_aoi,
  layers = "elevation",
  resolution = "native",
  coverage = "fill",
  details = TRUE,
  progress = FALSE,
  quiet = TRUE
)

bt_plot_bathy_map(policy_elevation$data, real_aoi, main = "New York Harbor native policy context")
```

![Hillshaded New York Harbor BlueTopo bathymetry map with
contours.](example-resolution-policies_files/figure-html/policy-bathy-map-1.png)

Actual NOAA BlueTopo source data: New York Harbor elevation context for
the native-resolution policy example.
