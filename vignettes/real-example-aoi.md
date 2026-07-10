# Real BlueTopo Example AOIs

Date last verified: 2026-07-10

## Primary Public AOI

AOI identifier: `new-york-harbor-upper-bay-2026-07-10`

Place: New York Harbor, centered on Lower Manhattan, the Upper Bay, Governors
Island, and the East River mouth.

Bbox, EPSG:4326:

```text
xmin = -74.045
ymin = 40.675
xmax = -73.995
ymax = 40.715
```

Why this AOI was chosen:

- It is a recognizable harbor-scale geography.
- It intersects current NOAA BlueTopo coverage.
- It is small enough for public pkgdown builds.
- It selects two real BlueTopo tiles.
- It keeps the planned GeoTIFF plus RAT transfer below 10 MiB on 2026-07-10.
- It includes real GeoTIFF and RAT sidecar URLs with SHA-256 checksums.

Expected primary tiles on 2026-07-10:

| tile_id | native_resolution_m | UTM zone | GeoTIFF bytes | RAT bytes |
|---|---:|---:|---:|---:|
| BH4XC5FK | 4 | 18 | 5654644 | 108606 |
| BH4XD5FK | 4 | 18 | 4292048 | 70680 |

Expected primary total download size: 10,125,978 bytes, about 9.66 MiB.

## Secondary Mixed-Grid AOI

AOI identifier: `key-west-boca-chica-mixed-grid-2026-07-10`

Place: a small Florida Keys AOI near Key West and Boca Chica Channel.

Bbox, EPSG:4326:

```text
xmin = -81.835
ymin = 24.815
xmax = -81.805
ymax = 24.845
```

Why this secondary AOI exists:

- The primary New York Harbor AOI currently selects compatible 4 m native grids.
- The mixed-grid example needs a real AOI that demonstrates incompatible native
  source grids without using synthetic rasters.
- This AOI currently selects real 4 m and 8 m BlueTopo tiles.
- It returns mixed native grids as a `terra::SpatRasterCollection`.
- It can also be resampled to a single explicit output grid for comparison.
- It remains small enough for public pkgdown builds.

Expected secondary tiles on 2026-07-10:

| tile_id | native_resolution_m | UTM zone | GeoTIFF bytes | RAT bytes |
|---|---:|---:|---:|---:|
| BH4SH55P | 4 | 17 | 3055209 | 7294 |
| BH4SJ55P | 4 | 17 | 1351603 | 4276 |
| BF2H62K7 | 8 | 17 | 1034177 | 5267 |

Expected secondary total download size: 5,457,826 bytes, about 5.21 MiB.

## Size Policy

Fail before download if a real-example plan selects more than four tiles or if
the planned GeoTIFF plus RAT assets exceed 250 MiB.

Do not silently switch AOIs during rendering. If the live NOAA catalog changes
enough that either documented AOI no longer meets its purpose, update this file
and the helper deliberately.
