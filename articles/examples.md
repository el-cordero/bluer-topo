# Example gallery

This example uses BlueTopo source tiles from the National Bathymetric
Source catalog. The build verifies the downloaded assets and records
their source metadata.

This example uses BlueTopo tiles covering New York Harbor. The workflow
demonstrates tile discovery, checksum-verified asset retrieval, and
file-backed raster access with `terra`. Raster Attribute Table (RAT)
sidecars are retained with the source GeoTIFF assets.

## What the examples show

| Example | Main function | Shows | Output type |
|:---|:---|:---|:---|
| Discover tiles and coverage | bluertopo_tiles() | AOI intersection, selected footprints, coverage diagnostics | Tables and footprint figure |
| Download original assets | bluertopo_download() | Verified NOAA GeoTIFF and RAT sidecar assets | Manifest tables and status figure |
| Extract elevation with terra | bluertopo() | File-backed terra object and provenance | terra summary tables and raster figure |
| Compare resolution policies | bluertopo_tiles() | Native source-resolution selection effects | Policy comparison tables and maps |
| Mixed grids and output grid | bluertopo() | SpatRasterCollection versus explicit output grid | Grid summary tables and raster figure |
| Layers and RAT metadata | bluertopo() | Elevation, uncertainty, contributor IDs, and RAT metadata | Layer/RAT tables and raster figures |

## Example area

## Locator map

![BlueTopo tile footprints colored by native source resolution with the
New York Harbor example area
boundary.](examples_files/figure-html/tile-footprints-1.png)

BlueTopo tile coverage for the New York Harbor example area.

| Tile ID | Resolution (m) | UTM zone | Delivery date | Intersection area (m²) | Tile intersected (%) | Selection rank | Selection | Coverage fallback | GeoTIFF URL | RAT URL |
|:---|---:|:---|:---|---:|---:|---:|:---|:---|:---|:---|
| BH4XC5FK | 4 | 18 | 2026-06-25 10:51:01 | 7508785 | 14.221 | 1 | Native | No | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XC5FK/BlueTopo_BH4XC5FK_20260624.tiff | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XC5FK/BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |
| BH4XD5FK | 4 | 18 | 2026-06-25 10:50:52 | 11263177 | 21.331 | 2 | Native | No | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XD5FK/BlueTopo_BH4XD5FK_20260624.tiff | noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com/BlueTopo/BH4XD5FK/BlueTopo_BH4XD5FK_20260624.tiff.aux.xml |

## Download plan

| Tile ID  | Asset   | Source file                             | Planned size (MB) |
|:---------|:--------|:----------------------------------------|------------------:|
| BH4XC5FK | GeoTIFF | BlueTopo_BH4XC5FK_20260624.tiff         |             5.393 |
| BH4XD5FK | GeoTIFF | BlueTopo_BH4XD5FK_20260624.tiff         |             4.093 |
| BH4XC5FK | RAT     | BlueTopo_BH4XC5FK_20260624.tiff.aux.xml |             0.104 |
| BH4XD5FK | RAT     | BlueTopo_BH4XD5FK_20260624.tiff.aux.xml |             0.067 |

## Terra preview

![BlueTopo bathymetry for New York Harbor with hillshade, contours, and
the example-area
boundary.](examples_files/figure-html/terra-preview-1.png)

BlueTopo bathymetry for New York Harbor, displayed with hillshade,
contours, and the example-area boundary.

`resolution` selects native source tiles. `output_resolution` is used
only when the user explicitly requests an output grid.
