test_that("packaged example fixtures are installed and readable", {
  example_root <- system.file("extdata/examples", package = "bluertopo")
  expect_true(nzchar(example_root))
  expect_true(dir.exists(example_root))

  aoi_path <- file.path(example_root, "aoi.gpkg")
  catalog_path <- file.path(example_root, "catalog", "BlueTopo_Tile_Scheme_example.gpkg")
  expect_true(file.exists(aoi_path))
  expect_true(file.exists(catalog_path))
  expect_s4_class(terra::vect(aoi_path), "SpatVector")

  catalog <- terra::vect(catalog_path)
  expect_s4_class(catalog, "SpatVector")
  required <- c(
    "tile",
    "Delivered_Date",
    "UTM",
    "Resolution",
    "GeoTIFF_Link",
    "GeoTIFF_SHA256_Checksum",
    "RAT_Link",
    "RAT_SHA256_Checksum"
  )
  expect_true(all(required %in% names(catalog)))

  geotiffs <- list.files(example_root, pattern = "\\.tiff$", recursive = TRUE, full.names = TRUE)
  rats <- list.files(example_root, pattern = "\\.tiff\\.aux\\.xml$", recursive = TRUE, full.names = TRUE)
  expect_gte(length(geotiffs), 3L)
  expect_gte(length(rats), 3L)
  expect_true(all(vapply(geotiffs, function(path) terra::nlyr(terra::rast(path)) >= 3L, logical(1L))))
  expect_true(all(file.exists(rats)))
})

test_that("example fixtures work through public package workflows", {
  example <- .bt_example_setup(cache_dir = file.path(tempdir(), "bluertopo-test-example-cache"))
  withr::defer(example$restore())

  tiles <- bluertopo_tiles(example$aoi, coverage = "fill", quiet = TRUE)
  expect_s4_class(tiles, "SpatVector")
  expect_gte(nrow(tiles), 3L)

  downloads <- bluertopo_download(
    example$aoi,
    path = tempfile("bluertopo-example-download-"),
    coverage = "fill",
    rat = TRUE,
    verify = "sha256",
    progress = FALSE
  )
  expect_s3_class(downloads, "bluertopo_downloads")
  expect_true(all(downloads$verified))
  expect_true(any(downloads$asset_type == "rat"))

  result <- bluertopo(
    example$aoi,
    layers = "elevation",
    resolution = "native",
    coverage = "fill",
    details = TRUE,
    progress = FALSE
  )
  expect_s3_class(result, "bluertopo_result")
  expect_true(inherits(result$data, "SpatRaster") || inherits(result$data, "SpatRasterCollection"))
})

test_that("public API remains unchanged", {
  expect_setequal(
    getNamespaceExports("bluertopo"),
    c(
      "bluertopo",
      "bluertopo_download",
      "bluertopo_tiles",
      "bluertopo_resolution",
      "bluertopo_cache_dir",
      "bluertopo_cache_clear"
    )
  )
})

test_that("example vignettes render without live NOAA network access", {
  skip_if_not_installed("rmarkdown")
  vignette_dirs <- c(
    file.path(getwd(), "vignettes"),
    testthat::test_path("..", "..", "vignettes")
  )
  vignette_dir <- vignette_dirs[dir.exists(vignette_dirs)][1L]
  skip_if(is.na(vignette_dir), "vignette sources are not available in this test context")

  example_vignettes <- file.path(
    vignette_dir,
    c(
      "examples.Rmd",
      "example-discover-tiles.Rmd",
      "example-download-assets.Rmd",
      "example-extract-elevation.Rmd",
      "example-resolution-policies.Rmd",
      "example-mixed-grids.Rmd",
      "example-layers-rat.Rmd"
    )
  )
  expect_true(all(file.exists(example_vignettes)))

  output_dir <- file.path(tempdir(), "bluertopo-rendered-example-vignettes")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  for (vignette in example_vignettes) {
    expect_no_error(rmarkdown::render(
      vignette,
      output_dir = output_dir,
      quiet = TRUE,
      clean = TRUE,
      envir = new.env(parent = globalenv())
    ))
  }
})
