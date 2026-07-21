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

test_that("AOI normalization accepts terra spatial extents and rasters", {
  extent <- terra::ext(-74.1, -73.9, 40.6, 40.8)
  expect_s4_class(.bt_normalize_aoi(extent)$vector, "SpatVector")

  raster <- terra::rast(ext = extent, resolution = 0.1, crs = "EPSG:4326")
  expect_s4_class(.bt_normalize_aoi(raster)$vector, "SpatVector")

  polygon <- terra::as.polygons(extent, crs = "EPSG:4326")
  expect_s4_class(.bt_normalize_aoi(polygon)$vector, "SpatVector")
})

test_that("AOI normalization accepts sf and sfc polygons directly", {
  skip_if_not_installed("sf")
  geometry <- sf::st_as_sfc(
    "POLYGON ((-74.1 40.6, -73.9 40.6, -73.9 40.8, -74.1 40.8, -74.1 40.6))",
    crs = 4326
  )
  sf_aoi <- sf::st_sf(name = "example", geometry = geometry)

  expect_s4_class(.bt_normalize_aoi(sf_aoi)$vector, "SpatVector")
  expect_s4_class(.bt_normalize_aoi(geometry)$vector, "SpatVector")
  expect_identical(.bt_normalize_aoi(sf_aoi)$source_type, "sf")
})

test_that("AOI normalization rejects non-polygon geometry and missing CRS", {
  point <- terra::vect(cbind(-74, 40.7), type = "points", crs = "EPSG:4326")
  line <- terra::vect(cbind(c(-74.1, -73.9), c(40.6, 40.8)), type = "lines", crs = "EPSG:4326")
  no_crs <- terra::as.polygons(terra::ext(0, 1, 0, 1))

  expect_error(.bt_normalize_aoi(point), class = "bluertopo_error_aoi")
  expect_error(.bt_normalize_aoi(line), class = "bluertopo_error_aoi")
  expect_error(.bt_normalize_aoi(no_crs), class = "bluertopo_error_aoi")
})
