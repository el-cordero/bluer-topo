.bt_example_setup <- function(cache_dir = file.path(tempdir(), "bluertopo-example-cache")) {
  example_root <- system.file("extdata/examples", package = "bluertopo")
  if (!nzchar(example_root) || !dir.exists(example_root)) {
    .bt_abort(
      "The packaged bluertopo example fixtures are not installed.",
      class = "bluertopo_error_filesystem"
    )
  }
  example_catalog <- file.path(
    example_root,
    "catalog",
    "BlueTopo_Tile_Scheme_example.gpkg"
  )
  example_aoi_path <- file.path(example_root, "aoi.gpkg")
  if (!file.exists(example_catalog) || !file.exists(example_aoi_path)) {
    .bt_abort(
      "The packaged bluertopo example catalog or AOI is missing.",
      class = "bluertopo_error_filesystem"
    )
  }
  old <- options(
    bluertopo.catalog.path = example_catalog,
    bluertopo.allow_test_hosts = TRUE,
    bluertopo.cache_dir = cache_dir
  )
  list(
    root = example_root,
    catalog = example_catalog,
    aoi_path = example_aoi_path,
    aoi = terra::vect(example_aoi_path),
    cache_dir = cache_dir,
    download_dir = file.path(tempdir(), "bluertopo-example-downloads"),
    restore = function() options(old)
  )
}
