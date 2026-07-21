# Discover BlueTopo tiles intersecting an AOI

Returns selected NOAA BlueTopo tile footprints and standardized metadata
without downloading raster assets.

## Usage

``` r
bluertopo_tiles(
  aoi,
  resolution = "native",
  coverage = "warn",
  min_coverage = 1,
  cache_dir = bluertopo_cache_dir(),
  refresh = "if_stale",
  quiet = FALSE
)
```

## Arguments

- aoi:

  A polygonal area of interest in one of the formats listed in **AOI
  inputs** below.

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

- cache_dir:

  A non-empty character path for the package cache. The
  session-temporary default avoids writing to the user's home directory.
  Set an explicit path to reuse catalogs, source files, and VRTs across
  sessions.

- refresh:

  A character scalar controlling catalog access: `"if_stale"`,
  `"never"`, or `"always"`. `"never"` requires an existing cached
  catalog and performs no catalog request.

- quiet:

  A length-one logical suppressing routine informational messages.

## Value

A
[`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
with selected tile metadata. Coverage diagnostics are attached as the
`"coverage"` attribute and the normalized native-resolution policy as
`"resolution_spec"`. Important fields include tile ID, native
resolution, UTM zone, delivery date, intersection area and fraction,
source URLs, expected SHA-256 checksums, selection rank/reason, and
whether the tile was added as a coverage fallback.

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
tiles <- bluertopo_tiles(aoi)
# }
```
