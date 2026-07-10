# Download Original Assets

``` r


example <- bt_example_setup()
#> Synthetic miniature BlueTopo fixture for package demonstration.
#> Fixture-only option: bluertopo.allow_test_hosts = TRUE enables local file URLs.
example_aoi <- example$aoi
example_download_dir <- file.path(tempdir(), "bluertopo-example-download-assets")
unlink(example_download_dir, recursive = TRUE, force = TRUE)
```

Every rendered output on this page uses: **Synthetic miniature BlueTopo
fixture for package demonstration.**

[`bluertopo_download()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo_download.md)
preserves original GeoTIFF and RAT sidecar files and verifies them with
SHA-256 checksums. This page uses local fixture files, not live NOAA
downloads.

## First Download

``` r

manifest <- bluertopo_download(
  example_aoi,
  path = example_download_dir,
  coverage = "fill",
  rat = TRUE,
  verify = "sha256",
  progress = FALSE
)
```

``` r

bt_display_table(bt_manifest_table(manifest))
```

| tile_id | asset_type | source_basename | status | verification_mode | verified | downloaded_bytes | actual_sha256 | attempts |
|:---|:---|:---|:---|:---|:---|---:|:---|---:|
| TILE_FINE_A | geotiff | BlueTopo_TILE_FINE_A.tiff | downloaded | sha256 | TRUE | 2196 | 7e81b29b0dec | 1 |
| TILE_FINE_A | rat | BlueTopo_TILE_FINE_A.tiff.aux.xml | downloaded | sha256 | TRUE | 1326 | 18905bdd9e1b | 1 |
| TILE_COARSE_B | geotiff | BlueTopo_TILE_COARSE_B.tiff | downloaded | sha256 | TRUE | 2113 | ed1ee11911be | 1 |
| TILE_COARSE_B | rat | BlueTopo_TILE_COARSE_B.tiff.aux.xml | downloaded | sha256 | TRUE | 1356 | d60feb25cf39 | 1 |
| TILE_UTM_C | geotiff | BlueTopo_TILE_UTM_C.tiff | downloaded | sha256 | TRUE | 2156 | 20650649e253 | 1 |
| TILE_UTM_C | rat | BlueTopo_TILE_UTM_C.tiff.aux.xml | downloaded | sha256 | TRUE | 1363 | 7fe027d87e35 | 1 |

## Reuse Existing Verified Files

``` r

reused <- bluertopo_download(
  example_aoi,
  path = example_download_dir,
  coverage = "fill",
  rat = TRUE,
  verify = "sha256",
  progress = FALSE
)

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

manifest_files <- list.files(
  example_download_dir,
  pattern = "manifest\\.(csv|json)$|manifest-[A-Za-z0-9]+\\.(csv|json)$",
  recursive = TRUE,
  full.names = TRUE
)
manifest_file_table <- data.frame(
  file = bt_short_path(manifest_files, keep = 3L),
  exists = file.exists(manifest_files),
  bytes = as.integer(file.info(manifest_files)$size),
  stringsAsFactors = FALSE
)

bt_display_table(manifest_file_table)
```

|  | file | exists | bytes |
|:---|:---|:---|---:|
| /var/folders/7j/dr505g_j3zd9z6m9qdykzc4w0000gn/T//Rtmpkqq2un/bluertopo-example-download-assets/bluertopo-download-manifest.csv | Rtmpkqq2un/bluertopo-example-download-assets/bluertopo-download-manifest.csv | TRUE | 3856 |
| /var/folders/7j/dr505g_j3zd9z6m9qdykzc4w0000gn/T//Rtmpkqq2un/bluertopo-example-download-assets/bluertopo-download-manifest.json | Rtmpkqq2un/bluertopo-example-download-assets/bluertopo-download-manifest.json | TRUE | 8728 |
| /var/folders/7j/dr505g_j3zd9z6m9qdykzc4w0000gn/T//Rtmpkqq2un/bluertopo-example-download-assets/manifests/bluertopo-download-manifest-6861bed88d07c0b7.csv | bluertopo-example-download-assets/manifests/bluertopo-download-manifest-6861bed88d07c0b7.csv | TRUE | 3856 |
| /var/folders/7j/dr505g_j3zd9z6m9qdykzc4w0000gn/T//Rtmpkqq2un/bluertopo-example-download-assets/manifests/bluertopo-download-manifest-6861bed88d07c0b7.json | bluertopo-example-download-assets/manifests/bluertopo-download-manifest-6861bed88d07c0b7.json | TRUE | 8728 |

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

![Bar plot of downloaded asset status counts from the synthetic
fixture.](example-download-assets_files/figure-html/status-bars-1.png)

Synthetic miniature BlueTopo fixture for package demonstration: verified
download status counts.

The second call reports `reused_verified` for files that already exist
and still match the expected SHA-256 checksums.
