# Download original assets

This example uses BlueTopo source tiles from the National Bathymetric
Source catalog. The build verifies the downloaded assets and records
their source metadata.

This example uses BlueTopo tiles covering New York Harbor. The workflow
demonstrates tile discovery, checksum-verified asset retrieval, and
file-backed raster access with `terra`. Raster Attribute Table (RAT)
sidecars are retained with the source GeoTIFF assets.

## Example area

## First download

``` r

manifest <- bluertopo_download(
  real_aoi,
  path = real$download_dir,
  resolution = "native",
  coverage = "fill",
  rat = TRUE,
  verify = "sha256",
  on_exists = "verify",
  progress = FALSE,
  quiet = TRUE
)
```

| Tile ID | Asset | Source file | Status | Verification | Verified | Size (MB) | SHA-256 | Attempts |
|:---|:---|:---|:---|:---|:---|---:|:---|---:|
| BH4XC5FK | GeoTIFF | BlueTopo_BH4XC5FK_20260624.tiff | Reused and verified | sha256 | Yes | 5.393 | 878be33a85f5 | 0 |
| BH4XC5FK | RAT | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml | Reused and verified | sha256 | Yes | 0.104 | 21405b45e162 | 0 |
| BH4XD5FK | GeoTIFF | BlueTopo_BH4XD5FK_20260624.tiff | Reused and verified | sha256 | Yes | 4.093 | 35174b851869 | 0 |
| BH4XD5FK | RAT | BlueTopo_BH4XD5FK_20260624.tiff.aux.xml | Reused and verified | sha256 | Yes | 0.067 | 59814a3e330c | 0 |

## Reuse existing verified files

| Status              | count | verified_count |
|:--------------------|------:|---------------:|
| Reused and verified |     4 |              4 |

## Manifest files

| Manifest file | Exists | Bytes |
|:---|:---|---:|
| bluertopo-pkgdown-real-examples/downloads/new-york-harbor-upper-bay-2026-07-10/bluertopo-download-manifest.csv | Yes | 2441 |
| bluertopo-pkgdown-real-examples/downloads/new-york-harbor-upper-bay-2026-07-10/bluertopo-download-manifest.json | Yes | 6655 |
| downloads/new-york-harbor-upper-bay-2026-07-10/manifests/bluertopo-download-manifest-9d8d15e960090e3c.csv | Yes | 2441 |
| downloads/new-york-harbor-upper-bay-2026-07-10/manifests/bluertopo-download-manifest-9d8d15e960090e3c.json | Yes | 6655 |

## Source domain summary

| domain | Asset | Freq |
|--------|-------|------|

## Download status counts

![Bar plot of downloaded and reused BlueTopo asset
statuses.](example-download-assets_files/figure-html/status-bars-1.png)

SHA-256 verified download status counts for the selected BlueTopo
assets.

The second call reports `reused_verified` for files that already exist
and still match NOAA SHA-256 checksums. RAT sidecars are downloaded and
verified with the GeoTIFF assets.
