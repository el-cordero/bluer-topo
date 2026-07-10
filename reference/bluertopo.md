# Download and extract NOAA BlueTopo bathymetry

`bluertopo()` is the main extraction workflow. It discovers BlueTopo
tiles for an AOI, downloads verified original source assets by default,
and opens selected bands as lazy, file-backed `terra` objects.

## Usage

``` r
bluertopo(
  aoi,
  layers = "elevation",
  resolution = "native",
  coverage = "warn",
  min_coverage = 1,
  access = "download",
  cache_dir = bluertopo_cache_dir(),
  refresh = "if_stale",
  crop = TRUE,
  mask = FALSE,
  combine = "auto",
  output_crs = NULL,
  output_resolution = NULL,
  resampling = NULL,
  verify = "sha256",
  workers = NULL,
  progress = interactive(),
  quiet = FALSE,
  details = FALSE
)
```

## Arguments

- aoi:

  Area of interest.

- layers:

  `"elevation"`, `"uncertainty"`, `"contributor"`, `"all"`, or a
  character vector of canonical layer names.

- resolution:

  Native source-resolution policy.

- coverage:

  Coverage policy.

- min_coverage:

  Target share of published tile coverage.

- access:

  `"download"` or opt-in `"stream"`.

- cache_dir:

  Package cache directory.

- refresh:

  Catalog refresh policy.

- crop:

  Crop each result to the AOI extent.

- mask:

  Mask each result to the AOI polygon. Implies `crop = TRUE`.

- combine:

  `"auto"`, `"collection"`, or `"single"`.

- output_crs:

  Optional explicit output CRS.

- output_resolution:

  Optional explicit output-grid resolution in target CRS units.

- resampling:

  Optional named resampling methods by layer.

- verify:

  Download verification mode.

- workers:

  Worker count. Only `NULL`/`1` is currently supported; higher values
  are rejected until bounded parallel downloads are implemented.

- progress:

  Show routine progress messages.

- quiet:

  Suppress routine messages.

- details:

  Return a `bluertopo_result` instead of only the terra object.

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html),
[`terra::SpatRasterCollection`](https://rspatial.github.io/terra/reference/SpatRaster-class.html),
or `bluertopo_result` when `details = TRUE`.

## Examples

``` r
if (FALSE) { # \dontrun{
bathy <- bluertopo(c(-66.2, 18.2, -66.1, 18.3))
} # }
```
