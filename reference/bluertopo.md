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

  A polygonal area of interest in one of the formats listed in **AOI
  inputs** below.

- layers:

  A character vector containing `"elevation"`, `"uncertainty"`, or
  `"contributor"`; use `"all"` for all three source bands. Elevation and
  uncertainty are continuous values. Contributor identifiers are
  categorical.

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

- access:

  A character scalar. `"download"` stores and SHA-256 verifies source
  files before opening them; `"stream"` uses GDAL `/vsicurl/` access
  without local checksum verification.

- cache_dir:

  A non-empty character path for the package cache. The
  session-temporary default avoids writing to the user's home directory.
  Set an explicit path to reuse catalogs, source files, and VRTs across
  sessions.

- refresh:

  A character scalar controlling catalog access: `"if_stale"`,
  `"never"`, or `"always"`. `"never"` requires an existing cached
  catalog and performs no catalog request.

- crop:

  A length-one logical. If `TRUE`, crop each output to the AOI bounding
  extent.

- mask:

  A length-one logical. If `TRUE`, mask cells outside the AOI polygon
  and also enable cropping.

- combine:

  A character scalar controlling multiple native grids: `"auto"` returns
  one raster when compatible and a collection otherwise; `"collection"`
  always returns a collection; `"single"` requires compatible grids or
  an explicit output grid.

- output_crs:

  `NULL` or a non-empty character projected CRS accepted by `terra`,
  such as `"EPSG:26918"` or WKT. Supply it together with
  `output_resolution` to request one resampled output grid.

- output_resolution:

  `NULL` or one positive numeric cell size in `output_crs` units. It
  must be supplied together with `output_crs`.

- resampling:

  `NULL`, a named character vector, or a named list keyed by layer.
  Allowed methods are `"near"`, `"bilinear"`, `"cubic"`,
  `"cubicspline"`, `"lanczos"`, `"average"`, and `"mode"`. Defaults are
  bilinear for elevation/uncertainty and nearest-neighbor for
  contributor; contributor cannot use a non-nearest method.

- verify:

  A character scalar download-verification mode: `"sha256"` (default),
  `"size"`, or `"none"`. `"none"` is explicitly unverified.

- workers:

  `NULL` or the number `1`. Higher worker counts are rejected in this
  release.

- progress:

  A length-one logical controlling routine download progress.

- quiet:

  A length-one logical suppressing routine informational messages.

- details:

  A length-one logical. If `TRUE`, return data plus tile, download,
  query, coverage, and provenance records.

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html),
[`terra::SpatRasterCollection`](https://rspatial.github.io/terra/reference/SpatRaster-class.html),
or a `bluertopo_result` list as described in **Output behavior**.

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

## Output behavior

Native source grids are preserved unless both `output_crs` and
`output_resolution` are supplied. With `details = FALSE`, the function
returns a
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
for one compatible grid or a
[`terra::SpatRasterCollection`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
for multiple incompatible native grids. With `details = TRUE`, it
returns a `bluertopo_result` list containing:

- `data`: the raster or raster collection;

- `tiles`: selected tile footprints and catalog metadata;

- `downloads`: one record per source asset;

- `query`: normalized request settings and query hash;

- `coverage`: geometric coverage diagnostics; and

- `provenance`: catalog, checksum, source, and vertical-reference
  records.

## Examples

``` r
aoi <- c(xmin = -74.045, ymin = 40.675, xmax = -73.995, ymax = 40.715)

# sf and sfc polygons with a known CRS can be passed directly:
# aoi <- sf::st_read("my_area.gpkg")

# \donttest{
bathy <- bluertopo(aoi)
#> Downloading BlueTopo tile scheme `BlueTopo_Tile_Scheme_20260626_132625.gpkg`.
# }
```
