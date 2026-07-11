# Mixed UTM zones and terra collections

BlueTopo is published as source tiles. Adjacent tiles can differ in CRS,
native cell size, origin, alignment, or delivery date. `bluertopo`
treats those differences as source facts rather than hiding them with
automatic resampling.

## Native output

``` r

native <- bluertopo(
  aoi,
  resolution = "native",
  coverage = "fill",
  combine = "auto"
)
```

When selected rasters share a compatible grid, the result is a single
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).
When grids differ, the result is a
[`terra::SpatRasterCollection`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
with stable collection names derived from grid metadata.

``` r

class(native)
```

## Requesting a collection

Use `combine = "collection"` when downstream code should always receive
a collection, even for a single compatible grid.

``` r

collection <- bluertopo(
  aoi,
  resolution = "native",
  combine = "collection"
)
```

## Requesting one output grid

Use `combine = "single"` together with `output_crs` and
`output_resolution` when your analysis requires one grid. This is
explicit resampling and is reported by a warning.

``` r

single <- bluertopo(
  aoi,
  resolution = "native",
  output_crs = "EPSG:26918",
  output_resolution = 10,
  combine = "single",
  resampling = c(
    elevation = "bilinear",
    uncertainty = "bilinear",
    contributor = "near"
  )
)
```

Geographic target resolutions are rejected in this release because
degree-based cell sizes are ambiguous for bathymetric analysis. Use a
projected CRS for explicit output grids.
