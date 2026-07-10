test_that("AOI normalization accepts bbox and rejects unsafe character URLs", {
  aoi <- .bt_normalize_aoi(c(0, 0, 1, 1))
  expect_type(aoi$hash, "character")
  expect_error(.bt_normalize_aoi(c(1, 0, 0, 1)), class = "bluertopo_error_aoi")
  expect_error(.bt_normalize_aoi("https://example.com/aoi.geojson"), class = "bluertopo_error_aoi")
})

test_that("AOI normalization accepts WKT and GeoJSON strings", {
  wkt <- "POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))"
  expect_s4_class(.bt_normalize_aoi(wkt)$vector, "SpatVector")
  geojson <- "{\"type\":\"Polygon\",\"coordinates\":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}"
  expect_s4_class(.bt_normalize_aoi(geojson)$vector, "SpatVector")
})
