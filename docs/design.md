# bluertopo design contract

`bluertopo` has one product boundary: NOAA BlueTopo source asset discovery,
download, verification, and terra-backed extraction.

The public API is intentionally small:

* `bluertopo()`
* `bluertopo_download()`
* `bluertopo_tiles()`
* `bluertopo_resolution()`
* `bluertopo_cache_dir()`
* `bluertopo_cache_clear()`

`resolution` always means native source-tile selection. `output_resolution`
means explicit output-grid resampling. Native mixed grids are preserved by
returning `terra::SpatRasterCollection` objects unless a user supplies enough
target-grid information to create one output raster.

The package never rewrites NOAA source rasters merely to return an object. Raw
downloads preserve original basenames and sidecar files, and all routine tests
run without network access.
