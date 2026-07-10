test_that("newest catalog selection uses LastModified before filename stamp", {
  objects <- list(
    list(
      key = "BlueTopo/_BlueTopo_Tile_Scheme/BlueTopo_Tile_Scheme_20250101_000000.gpkg",
      url = "https://example.test/old.gpkg",
      last_modified = "2026-01-01T00:00:00.000Z",
      etag = "old",
      content_length = 1
    ),
    list(
      key = "BlueTopo/_BlueTopo_Tile_Scheme/BlueTopo_Tile_Scheme_20240101_000000.gpkg",
      url = "https://example.test/new.gpkg",
      last_modified = "2026-02-01T00:00:00.000Z",
      etag = "new",
      content_length = 1
    ),
    list(
      key = "BlueTopo/unrelated.txt",
      url = "https://example.test/unrelated.txt",
      last_modified = "2026-03-01T00:00:00.000Z",
      etag = "skip",
      content_length = 1
    )
  )
  newest <- .bt_select_newest_catalog(objects)
  expect_match(newest$key, "20240101")
})

test_that("fixture catalog normalizes the current NOAA schema names", {
  with_bt_fixture({
    catalog <- .bt_get_catalog(refresh = "never")
    v <- .bt_read_catalog_vector(catalog)
    expect_true(all(c("tile_id", "resolution_m", "geotiff_url", "geotiff_sha256") %in% names(v)))
    expect_equal(sort(stats::na.omit(unique(as.data.frame(v)$resolution_m))), c(2, 4, 8, 16))
  })
})
