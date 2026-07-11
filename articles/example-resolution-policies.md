# Compare resolution policies

This example uses BlueTopo source tiles from the NOAA National
Bathymetric Source catalog. The build verifies the downloaded assets and
records their source metadata.

This example uses BlueTopo tiles covering New York Harbor. The workflow
demonstrates tile discovery, checksum-verified asset retrieval, and
file-backed raster access with `terra`. It applies native
source-resolution policies to the AOI, reports selected tile coverage,
and renders policy footprints. The current New York Harbor example is a
compact 4 m native-resolution plan, so policy differences mainly
demonstrate selection rules rather than a dramatic visual change.

BlueTopo is not for navigation. No vertical-datum conversion is
performed. Smaller meter values mean finer native source resolution.
`resolution` selects source tiles; it does not resample.
`coverage = "fill"` can add fallback source tiles. `output_resolution`
is the argument that changes the output grid.

## Example area

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
```

| policy | selected_tile_count | selected_resolutions | Selected coverage (%) | AOI intersected (%) | Target met |
|:---|---:|:---|---:|---:|:---|
| Native | 2 | 4 | 1 | 1 | Yes |
| finest | 2 | 4 | 1 | 1 | Yes |
| finest + coverage fill | 2 | 4 | 1 | 1 | Yes |
| coarsest | 2 | 4 | 1 | 1 | Yes |
| exact available native resolution | 2 | 4 | 1 | 1 | Yes |
| nearest 6 m | 2 | 4 | 1 | 1 | Yes |

## Tile selection maps

![Six maps showing BlueTopo tile selections for native, finest, coverage
fill, coarsest, exact, and nearest
policies.](example-resolution-policies_files/figure-html/policy-maps-1.png)

BlueTopo tile coverage selected under different native source-resolution
policies.

## Coverage by policy

![Bar plot comparing selected coverage fractions by native
source-resolution
policy.](example-resolution-policies_files/figure-html/policy-coverage-bars-1.png)

Coverage fractions selected under different native source-resolution
policies.

Use an explicit output grid only when resampling is intended.

## Elevation context

![BlueTopo bathymetry for New York Harbor with hillshade, contours, and
the example-area
boundary.](example-resolution-policies_files/figure-html/policy-bathy-map-1.png)

BlueTopo bathymetry for New York Harbor, displayed with hillshade,
contours, and the example-area boundary.
