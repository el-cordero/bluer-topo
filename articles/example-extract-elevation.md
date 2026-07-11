# Extract elevation with terra

This example uses BlueTopo source tiles from the NOAA National
Bathymetric Source catalog. The build verifies the downloaded assets and
records their source metadata.

This example uses BlueTopo tiles covering New York Harbor. The workflow
demonstrates tile discovery, checksum-verified asset retrieval, and
file-backed raster access with `terra`. Raster Attribute Table (RAT)
sidecars are retained with the source GeoTIFF assets.

BlueTopo is not for navigation. No vertical-datum conversion is
performed.
[`bluertopo()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo.md)
returns terra objects and, with `details = TRUE`, exposes selected
tiles, downloads, query metadata, provenance, and coverage diagnostics.
Normal native extraction does not intentionally resample.

## Example area

## Extract elevation

``` r

result <- bluertopo(
  real_aoi,
  layers = "elevation",
  resolution = "native",
  coverage = "fill",
  details = TRUE,
  progress = FALSE,
  quiet = TRUE
)
```

## Object summary

| element            | Value      |
|:-------------------|:-----------|
| object type        | SpatRaster |
| result\$data class | SpatRaster |
| number of layers   | 1          |
| layer names        | elevation  |
| CRS summary        | EPSG:26918 |
| resolution         | 4 x 4      |
| source count       | 1          |

## File-backed sources

| Source file |
|:------------|
| NA          |

## Coverage

| Published coverage (%) | Selected coverage (%) | AOI intersected (%) | Target coverage (%) | Target met | Coverage type |
|---:|---:|---:|---:|:---|:---|
| 100 | 100 | 100 | 100 | Yes | geometric tile-index coverage |

## Provenance

| Field                     | Value                                     |
|:--------------------------|:------------------------------------------|
| Catalog                   | BlueTopo_Tile_Scheme_20260626_132625.gpkg |
| Catalog last modified     | 2026-06-26T17:35:52.000Z                  |
| Package version           | 0.0.1                                     |
| Navigation status         | BlueTopo is not for navigation            |
| Vertical-datum conversion | none performed by bluertopo               |
| Planned download (MB)     | 9.657                                     |

## Elevation preview

![BlueTopo bathymetry for New York Harbor with hillshade, contours, and
the example-area
boundary.](example-extract-elevation_files/figure-html/elevation-figure-1.png)

BlueTopo bathymetry for New York Harbor, displayed with hillshade,
contours, and the example-area boundary.

When native source grids differ, the result can be a
`SpatRasterCollection`. Each member can still be file-backed by verified
original assets.
