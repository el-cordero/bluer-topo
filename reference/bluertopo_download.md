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
  quiet = FALSE,
  cache_dir = bluertopo_cache_dir()
)
```

## Arguments

- aoi:

  A polygonal area of interest in one of the formats listed in **AOI
  inputs** below.

- path:

  A non-empty character path to the destination directory for the
  original source assets and generated CSV/JSON manifests. The argument
  is required; there is no default write location.

- resolution:

  A native source-tile selection policy. Supply a shortcut such as
  `"native"`, `"finest"`, `"coarsest"`, `"best_available"`,
  `"coarsest_available"`, or `"dominant"`; a positive numeric meter
  value for an exact match; or a
  [`bluertopo_resolution()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo_resolution.md)
  object.

- coverage:

  A character scalar controlling incomplete selected coverage:
  `"ignore"`, `"warn"`, `"error"`, or `"fill"`. `"fill"` adds fallback
  native resolutions in policy order until the target is met when
  possible.

- min_coverage:

  A numeric value from 0 through 1 giving the target share of published
  tile-index coverage. This is geometric catalog coverage, not a
  data-quality measure.

- rat:

  A length-one logical. If `TRUE`, download Raster Attribute Table (RAT)
  XML sidecars when the catalog provides them.

- refresh:

  A character scalar controlling catalog access: `"if_stale"`,
  `"never"`, or `"always"`. `"never"` requires an existing cached
  catalog and performs no catalog request.

- verify:

  A character scalar download-verification mode: `"sha256"` (default),
  `"size"`, or `"none"`. `"none"` is explicitly unverified.

- workers:

  `NULL` or the number `1`. Higher worker counts are rejected in this
  release.

- on_exists:

  A character scalar: `"verify"` reuses only files that pass
  verification, `"skip"` leaves existing files untouched, and
  `"replace"` downloads them again.

- on_error:

  A character scalar: `"stop"` aborts after an asset failure;
  `"continue"` records the failure and processes the remaining assets.

- retries:

  A positive whole number giving the maximum attempts per asset.

- timeout:

  `NULL` or a positive numeric timeout in seconds for each HTTP request.

- dry_run:

  A length-one logical. If `TRUE`, return the planned assets without
  downloading source files.

- progress:

  A length-one logical controlling routine download progress.

- quiet:

  A length-one logical suppressing routine informational messages.

- cache_dir:

  A non-empty character path for the package cache. The
  session-temporary default avoids writing to the user's home directory.
  Set an explicit path to reuse catalogs, source files, and VRTs across
  sessions.

## Value

A `bluertopo_downloads` data frame with one row per planned asset.
Important columns include `tile_id`, `asset_type`, `source_url`,
`local_path`, `status`, `verification_mode`, `verified`, byte counts,
checksums, attempts, and any recorded error. CSV and JSON copies are
written below `path` unless `dry_run = TRUE`.

## AOI inputs

`aoi` must resolve to polygon or multipolygon geometry with a known
coordinate reference system (CRS). Accepted inputs are:

- a
  [`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html);

- an [`sf::sf`](https://r-spatial.github.io/sf/reference/sf.html) data
  frame or
  [`sf::sfc`](https://r-spatial.github.io/sf/reference/sfc.html)
  geometry vector;

- a
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html),
  whose extent and CRS define the AOI;

- a
  [`terra::SpatExtent`](https://rspatial.github.io/terra/reference/SpatExtent-class.html),
  interpreted as longitude/latitude in EPSG:4326;

- a numeric `c(xmin, ymin, xmax, ymax)` bounding box in EPSG:4326;

- a local vector-file path readable by
  [`terra::vect()`](https://rspatial.github.io/terra/reference/vect.html);
  or

- a WKT or GeoJSON character string, interpreted as EPSG:4326.

Remote AOI URLs are refused. Numeric bounding boxes must be ordered and
fall within valid longitude/latitude bounds. Point and line geometries
are not accepted as areas of interest.

## Examples

``` r
aoi <- c(xmin = -74.045, ymin = 40.675, xmax = -73.995, ymax = 40.715)

# \donttest{
files <- bluertopo_download(
  aoi,
  path = file.path(tempdir(), "bluertopo-downloads")
)
#> Downloading BlueTopo tile scheme `BlueTopo_Tile_Scheme_20260626_132625.gpkg`.
# }
```
