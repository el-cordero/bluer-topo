# Layers, contributor values, and RAT metadata

BlueTopo source GeoTIFFs currently include elevation, vertical
uncertainty, and contributor/source identifier bands. `bluertopo`
exposes those as canonical layer names.

## Elevation only

``` r

elevation <- bluertopo(
  aoi,
  layers = "elevation"
)
```

## All canonical layers

``` r

all_layers <- bluertopo(
  aoi,
  layers = "all",
  details = TRUE
)

names(all_layers$data)
```

The contributor band contains numeric identifiers. Interpret those
identifiers with the NOAA RAT sidecar metadata and source documentation.
`bluertopo` can download RAT sidecars with the original assets, but it
does not currently normalize contributor tables into a package-level
lookup.

NOAA’s BlueTopo product page is the package’s primary external
reference: <https://nauticalcharts.noaa.gov/data/bluetopo.html>.

``` r

assets <- bluertopo_download(
  aoi,
  path = file.path(tempdir(), "bluertopo-downloads"),
  rat = TRUE
)

subset(assets, asset_type == "rat")
```

## Vertical-reference metadata

`bluertopo(details = TRUE)` includes vertical-reference text discovered
by `terra`/GDAL metadata inspection when available.

``` r

result <- bluertopo(aoi, details = TRUE)
result$provenance$vertical_reference_text
```
