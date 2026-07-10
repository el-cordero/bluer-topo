example_vignette_dir <- function() {
  vignette_dirs <- c(
    file.path(getwd(), "vignettes"),
    testthat::test_path("..", "..", "vignettes")
  )
  vignette_dirs[dir.exists(vignette_dirs)][1L]
}

public_example_vignettes <- function() {
  vignette_dir <- example_vignette_dir()
  if (is.na(vignette_dir)) {
    return(character())
  }
  file.path(
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
}

real_example_helper_path <- function() {
  file.path(example_vignette_dir(), "real-example-helpers.R")
}

project_file <- function(...) {
  candidates <- c(
    file.path(getwd(), ...),
    testthat::test_path("..", "..", ...)
  )
  candidates[file.exists(candidates)][1L]
}

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
  withr::local_envvar(c(BLUERTOPO_BUILD_REAL_EXAMPLES = "false"))
  example_vignettes <- public_example_vignettes()
  skip_if(!length(example_vignettes), "vignette sources are not available in this test context")
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

test_that("real example setup is opt-in", {
  helper <- real_example_helper_path()
  skip_if(!file.exists(helper), "real example helper is not available in this test context")
  withr::local_envvar(c(BLUERTOPO_BUILD_REAL_EXAMPLES = "false"))
  env <- new.env(parent = globalenv())
  source(helper, local = env)
  expect_false(env$bt_real_examples_enabled())
  expect_error(env$bt_real_example_setup(), "Real BlueTopo examples are disabled")
})

test_that("public examples are real-data gated and not fixture-rendered", {
  example_vignettes <- public_example_vignettes()
  skip_if(!length(example_vignettes), "vignette sources are not available in this test context")
  text <- lapply(example_vignettes, readLines, warn = FALSE)
  names(text) <- basename(example_vignettes)

  for (content in text) {
    collapsed <- paste(content, collapse = "\n")
    expect_match(collapsed, "eval=bt_real_examples_enabled\\(\\)")
    expect_false(grepl("Synthetic miniature BlueTopo", collapsed, fixed = TRUE))
    expect_match(tolower(collapsed), "not for navigation")
    expect_match(tolower(collapsed), "vertical-datum")
    expect_match(collapsed, "actual NOAA BlueTopo|real NOAA BlueTopo")
  }
})

test_that("real example AOI metadata is documented", {
  vignette_dir <- example_vignette_dir()
  skip_if(is.na(vignette_dir), "vignette sources are not available in this test context")
  metadata <- file.path(vignette_dir, "real-example-aoi.md")
  expect_true(file.exists(metadata))
  text <- paste(readLines(metadata, warn = FALSE), collapse = "\n")
  expect_match(text, "key-west-boca-chica-2026-07-10", fixed = TRUE)
  expect_match(text, "xmin = -81.835", fixed = TRUE)
  expect_match(text, "Expected total download size", fixed = TRUE)
  expect_match(text, "Date last verified: 2026-07-10", fixed = TRUE)
})

test_that("README and pkgdown config describe real public examples", {
  readme_path <- project_file("README.Rmd")
  config_path <- project_file("_pkgdown.yml")
  skip_if(
    is.na(readme_path) || is.na(config_path),
    "source README/pkgdown config are not available in this installed test context"
  )

  readme <- paste(readLines(readme_path, warn = FALSE), collapse = "\n")
  expect_false(grepl("Examples tab uses synthetic", readme, fixed = TRUE))
  expect_match(readme, "rendered from actual NOAA BlueTopo source tiles", fixed = TRUE)
  expect_match(readme, "Normal\\s+package tests use small synthetic fixtures")

  config <- paste(readLines(config_path, warn = FALSE), collapse = "\n")
  expect_match(config, "left: \\[intro, reference, examples, articles, news\\]")
  expect_match(config, "text: Examples", fixed = TRUE)
  expect_match(config, "href: articles/examples.html", fixed = TRUE)
})

test_that("real example live workflow works when explicitly enabled", {
  skip_if_not(
    identical(Sys.getenv("BLUERTOPO_RUN_REAL_EXAMPLE_TESTS"), "true"),
    "Set BLUERTOPO_RUN_REAL_EXAMPLE_TESTS=true to run live real-example tests."
  )
  helper <- real_example_helper_path()
  skip_if(!file.exists(helper), "real example helper is not available in this test context")
  withr::local_envvar(c(
    BLUERTOPO_BUILD_REAL_EXAMPLES = "true",
    BLUERTOPO_REAL_EXAMPLE_CACHE = tempfile("bluertopo-real-example-cache-")
  ))
  env <- new.env(parent = globalenv())
  source(helper, local = env)
  setup <- env$bt_real_example_setup()
  withr::defer(setup$restore())

  expect_lte(setup$planned_bytes, env$bt_real_example_size_cap())
  expect_lte(nrow(setup$tiles), 4L)
  expect_gte(nrow(setup$tiles), 1L)

  manifest <- env$bt_real_download_assets(setup)
  expect_s3_class(manifest, "bluertopo_downloads")
  expect_true(all(manifest$verified))
  expect_true(any(manifest$asset_type == "rat"))

  geotiff <- manifest$local_path[manifest$asset_type == "geotiff"][1L]
  expect_true(file.exists(geotiff))
  expect_gte(terra::nlyr(terra::rast(geotiff)), 3L)
})
