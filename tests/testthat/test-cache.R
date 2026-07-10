test_that("cache initialization writes and validates an ownership marker", {
  cache <- file.path(tempdir(), paste0("bluertopo-cache-", .bt_hash_object(stats::runif(1L))))
  withr::local_options(bluertopo.cache_dir = cache)
  expect_false(dir.exists(cache))

  initialized <- .bt_init_cache(cache)
  expect_true(dir.exists(initialized))
  expect_true(file.exists(.bt_cache_marker_path(initialized)))

  marker <- .bt_read_cache_marker(initialized)
  expect_identical(marker$package, "bluertopo")
  expect_identical(as.integer(marker$cache_format_version), 1L)
})

test_that("cache clear refuses unmarked, mismatched, and suspicious paths", {
  root <- file.path(tempdir(), paste0("bluertopo-cache-test-", .bt_hash_object(stats::runif(1L))))
  cache <- file.path(root, "cache")
  other <- file.path(root, "other")
  dir.create(cache, recursive = TRUE)
  dir.create(other, recursive = TRUE)
  withr::local_options(bluertopo.cache_dir = cache)

  expect_error(bluertopo_cache_clear(other, confirm = TRUE), class = "bluertopo_error_filesystem")
  expect_error(bluertopo_cache_clear(confirm = TRUE), class = "bluertopo_error_filesystem")
  expect_error(bluertopo_cache_clear(getwd(), confirm = TRUE), class = "bluertopo_error_filesystem")

  writeLines("{\"package\":\"someone-else\",\"cache_format_version\":1}", .bt_cache_marker_path(cache))
  expect_error(bluertopo_cache_clear(confirm = TRUE), class = "bluertopo_error_filesystem")
})

test_that("cache clear removes only package-owned children and preserves the marker", {
  cache <- file.path(tempdir(), paste0("bluertopo-cache-owned-", .bt_hash_object(stats::runif(1L))))
  withr::local_options(bluertopo.cache_dir = cache)
  .bt_init_cache(cache)
  tile_file <- file.path(cache, "tiles", "example.tif")
  catalog_file <- file.path(cache, "catalog", "current.gpkg")
  dir.create(dirname(tile_file), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(catalog_file), recursive = TRUE, showWarnings = FALSE)
  writeLines("tile", tile_file)
  writeLines("catalog", catalog_file)

  cleared <- bluertopo_cache_clear(confirm = TRUE)
  expect_s3_class(cleared, "bluertopo_cache_clear")
  expect_equal(cleared$removed_files, 2L)
  expect_false(file.exists(tile_file))
  expect_false(file.exists(catalog_file))
  expect_true(file.exists(.bt_cache_marker_path(cache)))
  expect_length(cleared$failed_paths[[1]], 0L)
})

test_that("transactional file installs restore the previous destination on failure", {
  root <- file.path(tempdir(), paste0("bluertopo-transaction-", .bt_hash_object(stats::runif(1L))))
  dir.create(root, recursive = TRUE)
  dest <- file.path(root, "dest.txt")
  tmp <- file.path(root, "tmp.txt")
  writeLines("old", dest)
  writeLines("new", tmp)

  withr::local_options(bluertopo.test_install_fail_after_backup = TRUE)
  expect_error(.bt_install_file_transactionally(tmp, dest), class = "bluertopo_error_filesystem")
  expect_equal(readLines(dest), "old")
  expect_true(file.exists(tmp))
})
