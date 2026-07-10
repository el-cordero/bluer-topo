# Download Original Assets

This page uses real NOAA BlueTopo source tiles when rendered for the
public pkgdown site. This example uses actual NOAA BlueTopo source tiles
downloaded from the public NOAA National Bathymetric Source bucket
during the pkgdown build.

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
| BH4SH55P | geotiff | BlueTopo_BH4SH55P_20241212.tiff | reused_verified | sha256 | TRUE | 2.914 | a49d92de8419 | 0 |
| BH4SH55P | rat | BlueTopo_BH4SH55P_20241212.tiff.aux.xml | reused_verified | sha256 | TRUE | 0.007 | f2a5a151b745 | 0 |
| BH4SJ55P | geotiff | BlueTopo_BH4SJ55P_20241004.tiff | reused_verified | sha256 | TRUE | 1.289 | ef8f39829788 | 0 |
| BH4SJ55P | rat | BlueTopo_BH4SJ55P_20241004.tiff.aux.xml | reused_verified | sha256 | TRUE | 0.004 | f3af3107d74d | 0 |
| BF2H62K7 | geotiff | BlueTopo_BF2H62K7_20241212.tiff | reused_verified | sha256 | TRUE | 0.986 | 8dcbdc1325c5 | 0 |
| BF2H62K7 | rat | BlueTopo_BF2H62K7_20241212.tiff.aux.xml | reused_verified | sha256 | TRUE | 0.005 | ea4bba3b305f | 0 |

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
| reused_verified |     6 |              6 |

## Manifest Files

``` r

bt_display_table(bt_manifest_files_table(real$download_dir))
```

| file | exists | bytes |
|:---|:---|---:|
| bluertopo-pkgdown-real-examples/downloads/key-west-boca-chica-2026-07-10/bluertopo-download-manifest.csv | TRUE | 3475 |
| bluertopo-pkgdown-real-examples/downloads/key-west-boca-chica-2026-07-10/bluertopo-download-manifest.json | TRUE | 8422 |
| downloads/key-west-boca-chica-2026-07-10/manifests/bluertopo-download-manifest-ac0668e7d63ec754.csv | TRUE | 3475 |
| downloads/key-west-boca-chica-2026-07-10/manifests/bluertopo-download-manifest-ac0668e7d63ec754.json | TRUE | 8422 |

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
