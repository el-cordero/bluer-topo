# Mixed grids and output grid

This example uses BlueTopo source tiles from the NOAA National
Bathymetric Source catalog. The build verifies the downloaded assets and
records their source metadata.

New York Harbor is the primary public AOI for the examples, but its
current small plan is a compatible 4 m grid. This example uses BlueTopo
tiles covering Key West and Boca Chica Channel because the documented
secondary AOI currently intersects 4 m and 8 m source grids and
therefore demonstrates mixed native-grid behavior.

BlueTopo is not for navigation. No vertical-datum conversion is
performed. Mixed native grids are preserved unless the user asks for a
single output grid. `combine = "single"` needs an explicit output grid
when native grids are incompatible. Resampled uncertainty values are not
original source cells, and contributor resampling must be
nearest-neighbor.

## Example area

## Native mixed-grid extraction

``` r

native <- bluertopo(
  real_aoi,
  resolution = "native",
  coverage = "fill",
  combine = "auto",
  details = TRUE,
  progress = FALSE,
  quiet = TRUE
)

if (!inherits(native$data, "SpatRasterCollection")) {
  stop("The documented real AOI no longer produces mixed native grids.", call. = FALSE)
}
```

| Output object | Grid | CRS | Resolution | Source count | Layers |
|:---|:---|:---|:---|---:|:---|
| SpatRasterCollection | grid_01_epsg26917_4x4 | EPSG:26917 | 4 x 4 | 1 | elevation |
| SpatRasterCollection | grid_02_epsg26917_8x8 | EPSG:26917 | 8 x 8 | 1 | elevation |

## Native grid footprints

![BlueTopo tile footprints selected for mixed native grids near Key West
and Boca Chica
Channel.](example-mixed-grids_files/figure-html/native-footprints-1.png)

BlueTopo tile coverage selected for the Key West mixed-grid example
area.

## Explicit single output grid

``` r

single <- suppressWarnings(bluertopo(
  real_aoi,
  layers = "elevation",
  resolution = "native",
  coverage = "fill",
  output_crs = "EPSG:26917",
  output_resolution = 100,
  combine = "single",
  details = TRUE,
  progress = FALSE,
  quiet = TRUE
))
```

| Output object | CRS | Resolution | Extent | Resampled |
|:---|:---|:---|:---|:---|
| SpatRaster | EPSG:26917 | 100 x 100 | 415613, 418713, 2744703.3, 2748003.3 | Yes |

![Hillshaded BlueTopo elevation raster on one explicit output grid with
contours.](example-mixed-grids_files/figure-html/output-raster-1.png)

BlueTopo elevation resampled to the specified output grid.

The explicit grid is useful for workflows that require one raster, but
it is a resampling operation. Native source-resolution selection remains
separate from output-grid creation.
