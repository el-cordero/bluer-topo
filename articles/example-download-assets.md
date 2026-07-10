# Download Original Assets

This page uses real NOAA BlueTopo source tiles when rendered for the
public pkgdown site. This example uses actual NOAA BlueTopo source tiles
downloaded from the public NOAA National Bathymetric Source bucket
during the pkgdown build.

This page downloads the real New York Harbor NOAA BlueTopo GeoTIFFs and
RAT sidecars, verifies SHA-256 checksums, shows the manifest, and
demonstrates reuse of already verified local files.

BlueTopo is not for navigation. No vertical-datum conversion is
performed. Example downloads are intentionally small and are cached
during website builds, but they still access NOAA public data.

## Real Example Setup

``` r

real <- bt_real_example_setup()
```

## First Download

``` r

manifest <- bt_real_download_assets(real)
```

``` r

bt_display_table(bt_manifest_table(manifest))
```

| tile_id | asset_type | source_basename | status | verification_mode | verified | downloaded_mb | actual_sha256 | attempts |
|:---|:---|:---|:---|:---|:---|---:|:---|---:|
| BH4XC5FK | geotiff | BlueTopo_BH4XC5FK_20260624.tiff | reused_verified | sha256 | TRUE | 5.393 | 878be33a85f5 | 0 |
| BH4XC5FK | rat | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml | reused_verified | sha256 | TRUE | 0.104 | 21405b45e162 | 0 |
| BH4XD5FK | geotiff | BlueTopo_BH4XD5FK_20260624.tiff | reused_verified | sha256 | TRUE | 4.093 | 35174b851869 | 0 |
| BH4XD5FK | rat | BlueTopo_BH4XD5FK_20260624.tiff.aux.xml | reused_verified | sha256 | TRUE | 0.067 | 59814a3e330c | 0 |

## Reuse Existing Verified Files

``` r

reused <- bt_real_download_assets(real)

reuse_df <- as.data.frame(reused)
reuse_summary <- aggregate(
  verified ~ status,
  data = reuse_df,
  FUN = function(x) sum(x %in% TRUE)
)
names(reuse_summary) <- c("status", "verified_count")
reuse_summary$count <- as.integer(table(reuse_df$status)[reuse_summary$status])
reuse_summary <- reuse_summary[c("status", "count", "verified_count")]

bt_display_table(reuse_summary)
```

| status          | count | verified_count |
|:----------------|------:|---------------:|
| reused_verified |     4 |              4 |

## Manifest Files

``` r

bt_display_table(bt_manifest_files_table(real$download_dir))
```

| file | exists | bytes |
|:---|:---|---:|
| bluertopo-pkgdown-real-examples/downloads/new-york-harbor-upper-bay-2026-07-10/bluertopo-download-manifest.csv | TRUE | 2441 |
| bluertopo-pkgdown-real-examples/downloads/new-york-harbor-upper-bay-2026-07-10/bluertopo-download-manifest.json | TRUE | 6655 |
| downloads/new-york-harbor-upper-bay-2026-07-10/manifests/bluertopo-download-manifest-9d8d15e960090e3c.csv | TRUE | 2441 |
| downloads/new-york-harbor-upper-bay-2026-07-10/manifests/bluertopo-download-manifest-9d8d15e960090e3c.json | TRUE | 6655 |

## Source Domain Summary

``` r

bt_display_table(bt_source_domain_summary(manifest))
```

| domain | asset_type | Freq |
|--------|------------|------|

## Download Status Counts

``` r

status_counts <- bt_status_counts(manifest)
barplot(
  stats::setNames(status_counts$count, status_counts$status),
  col = "#005f73",
  ylab = "asset count",
  main = "First-call download statuses"
)
```

![Bar plot of downloaded and reused real BlueTopo asset
statuses.](example-download-assets_files/figure-html/status-bars-1.png)

Actual NOAA BlueTopo source assets: SHA-256 verified download status
counts.

The second call reports `reused_verified` for files that already exist
and still match NOAA SHA-256 checksums. RAT sidecars are downloaded and
verified with the GeoTIFF assets.
