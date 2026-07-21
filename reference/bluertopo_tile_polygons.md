# Retrieve all BlueTopo tile polygons

Downloads or reuses the current NOAA BlueTopo tile-scheme catalog and
returns every published tile footprint. This function does not require
an area of interest and does not download any bathymetry rasters.

## Usage

``` r
bluertopo_tile_polygons(
  cache_dir = bluertopo_cache_dir(),
  refresh = "if_stale",
  quiet = FALSE
)
```

## Arguments

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
containing all current BlueTopo tile polygons and their standardized
catalog metadata, including tile ID, native resolution, UTM zone, source
URLs, and expected SHA-256 checksums.

## Examples

``` r
# \donttest{
tile_polygons <- bluertopo_tile_polygons()
# }
```
