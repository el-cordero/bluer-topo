# Download original NOAA BlueTopo assets for an AOI

Discovers selected BlueTopo tiles, downloads original GeoTIFF files and
optional RAT sidecars, verifies them, and writes download manifests.

## Usage

``` r
bluertopo_download(
  aoi,
  path,
  resolution = "native",
  coverage = "warn",
  min_coverage = 1,
  rat = TRUE,
  refresh = "if_stale",
  verify = "sha256",
  workers = NULL,
  on_exists = "verify",
  on_error = "stop",
  retries = 3,
  timeout = NULL,
  dry_run = FALSE,
  progress = interactive(),
  quiet = FALSE
)
```

## Arguments

- aoi:

  Area of interest.

- path:

  Destination directory for original source assets.

- resolution:

  Native source-resolution policy.

- coverage:

  Coverage policy.

- min_coverage:

  Target share of published tile coverage.

- rat:

  Download RAT sidecars when available.

- refresh:

  Catalog refresh policy.

- verify:

  Verification mode: `"sha256"`, `"size"`, or `"none"`.

- workers:

  Worker count. Only `NULL`/`1` is currently supported; higher values
  are rejected until bounded parallel downloads are implemented.

- on_exists:

  Existing-file policy: `"verify"`, `"skip"`, or `"replace"`.

- on_error:

  Error policy: `"stop"` or `"continue"`.

- retries:

  Number of download attempts for each asset.

- timeout:

  Optional curl timeout in seconds.

- dry_run:

  Return the plan without writing tile files.

- progress:

  Show routine progress messages.

- quiet:

  Suppress routine messages.

## Value

A `bluertopo_downloads` data frame.

## Examples

``` r
if (FALSE) { # \dontrun{
bluertopo_download(c(-66.2, 18.2, -66.1, 18.3), path = "data/bluetopo")
} # }
```
