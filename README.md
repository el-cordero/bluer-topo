# bluertopo

Download and extract NOAA BlueTopo bathymetry with terra.

```r
library(bluertopo)
library(terra)

aoi <- vect("my_area.gpkg")
bathy <- bluertopo(aoi)
```

```r
# Original files only
files <- bluertopo_download(
  aoi,
  path = "data/bluetopo"
)

# Exact native resolution
bathy_8m <- bluertopo(
  aoi,
  resolution = 8
)

# Highest native detail, with lower-resolution fallback for coverage
bathy_best <- bluertopo(
  aoi,
  resolution = "finest",
  coverage = "fill"
)

# Lowest native detail
bathy_low <- bluertopo(
  aoi,
  resolution = "coarsest"
)

# Closest available native resolution to 10 m
bathy_near <- bluertopo(
  aoi,
  resolution = bluertopo_resolution(
    "nearest",
    value = 10,
    tie = "finer"
  )
)

# Keep source tiles from 4 through 16 m
bathy_range <- bluertopo(
  aoi,
  resolution = bluertopo_resolution(
    "between",
    min_m = 4,
    max_m = 16
  )
)

# Explicit output grid; this is resampling
bathy_10m <- bluertopo(
  aoi,
  resolution = "native",
  output_crs = "EPSG:26918",
  output_resolution = 10,
  combine = "single"
)
```

`resolution` filters NOAA BlueTopo source tiles by their native cell size.
Smaller meter values mean finer native source detail. `output_resolution`
requests an explicit output grid and therefore resamples the output.

Native BlueTopo tiles can span multiple UTM zones, resolutions, or grid
alignments. When the selected source files are not compatible, `bluertopo()`
returns a `terra::SpatRasterCollection` unless the user explicitly requests an
output grid.

`bluertopo_download()` writes the original NOAA GeoTIFF and RAT sidecar assets
without cropping, reprojection, recompression, or metadata rewriting. The
package verifies files with NOAA-provided SHA-256 checksums by default.

BlueTopo is not for navigation. This package performs no vertical-datum
conversion and is not affiliated with, endorsed by, or supported by NOAA.
