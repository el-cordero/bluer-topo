# Real BlueTopo Example AOI

Date last verified: 2026-07-10

AOI identifier: `key-west-boca-chica-2026-07-10`

Bbox, EPSG:4326:

```text
xmin = -81.835
ymin = 24.815
xmax = -81.805
ymax = 24.845
```

Location description: a small area near Boca Chica and Key West, Florida.

Why this AOI was chosen:

- It intersects current NOAA BlueTopo coverage.
- It is small enough for public pkgdown builds.
- It selects three real BlueTopo tiles.
- It includes two native source resolutions, 4 m and 8 m.
- It returns mixed native grids as a `terra::SpatRasterCollection`.
- It can also be resampled to a single explicit output grid for comparison.
- It includes real GeoTIFF and RAT sidecar URLs with SHA-256 checksums.

Expected tiles on 2026-07-10:

| tile_id | native_resolution_m | UTM zone | GeoTIFF bytes | RAT bytes |
|---|---:|---:|---:|---:|
| BH4SH55P | 4 | 17 | 3055209 | 7294 |
| BH4SJ55P | 4 | 17 | 1351603 | 4276 |
| BF2H62K7 | 8 | 17 | 1034177 | 5267 |

Expected total download size: 5,457,826 bytes, about 5.21 MiB.

Size policy: fail before download if the planned GeoTIFF plus RAT assets exceed
250 MiB or if more than four tiles are selected.

If the live NOAA catalog changes enough that this AOI no longer selects a small,
mixed-resolution plan, update this file and the helper deliberately rather than
silently switching locations during rendering.
