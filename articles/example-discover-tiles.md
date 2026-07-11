# Discover tiles and coverage

This example uses BlueTopo source tiles from the NOAA National
Bathymetric Source catalog. The build verifies the downloaded assets and
records their source metadata.

This example uses BlueTopo tiles covering New York Harbor. The workflow
demonstrates tile discovery, checksum-verified asset retrieval, and
file-backed raster access with `terra`.

BlueTopo is not for navigation. No vertical-datum conversion is
performed. Coverage is geometric tile-index coverage, not a statement
about navigational fitness, data quality, or NOAA endorsement.

## Example area

## Selected tiles

``` r

tiles <- bluertopo_tiles(
  real_aoi,
  resolution = "native",
  coverage = "warn",
  quiet = TRUE
)
```

| Tile ID | Resolution (m) | UTM zone | Delivery date | Intersection area (m²) | Tile intersected (%) | Selection rank | Selection | Coverage fallback | GeoTIFF URL | RAT URL |
|:---|---:|:---|:---|---:|---:|---:|:---|:---|:---|:---|
| BH4XC5FK | 4 | 18 | 2026-06-25 10:51:01 | 7508785 | 14.221 | 1 | Native | No | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XC5FK/BlueTopo_BH4XC5FK_20260624.tiff | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XC5FK/BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| BH4XD5FK | 4 | 18 | 2026-06-25 10:50:52 | 11263177 | 21.331 | 2 | Native | No | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XD5FK/BlueTopo_BH4XD5FK_20260624.tiff | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XD5FK/BlueTopo_BH4XD5FK_20260624.tiff.aux.xml |

## Coverage diagnostics

| Published coverage (%) | Selected coverage (%) | AOI intersected (%) | Target coverage (%) | Target met | Coverage type |
|---:|---:|---:|---:|:---|:---|
| 100 | 100 | 100 | 100 | Yes | geometric tile-index coverage |

## AOI and selected footprints

![BlueTopo tile footprints selected for the New York Harbor example
area.](example-discover-tiles_files/figure-html/footprint-figure-1.png)

BlueTopo tile coverage for the New York Harbor example area.

## Coverage fractions

![Bar plot of published coverage, selected coverage, selected AOI
fraction, and target
coverage.](example-discover-tiles_files/figure-html/coverage-bars-1.png)

Coverage fractions for the selected New York Harbor tiles.

The selected tile table includes shortened GeoTIFF and RAT URLs from the
current catalog records.
