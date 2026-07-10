test_that("live catalog discovery can read the current NOAA schema", {
  skip_if_not(
    identical(Sys.getenv("BLUERTOPO_RUN_NETWORK_TESTS"), "true"),
    "Set BLUERTOPO_RUN_NETWORK_TESTS=true to run live NOAA catalog tests."
  )
  cache <- tempfile("bluertopo-live-cache-")
  withr::local_options(bluertopo.cache_dir = cache)
  catalog <- .bt_get_catalog(cache_dir = cache, refresh = "always", quiet = TRUE)
  v <- .bt_read_catalog_vector(catalog)
  expect_true(all(.bt_expected_catalog_fields %in% names(v)))
  expect_true(nrow(v) > 0)
})
