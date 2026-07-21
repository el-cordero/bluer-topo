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
  expect_setequal(
    unname(vapply(rats, .bt_sha256_file, character(1L))),
    catalog$RAT_SHA256_Checksum
  )
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

test_that("public API exports and download cache control remain available", {
  expect_setequal(
    getNamespaceExports("bluertopo"),
    c(
      "bluertopo",
      "bluertopo_download",
      "bluertopo_tile_polygons",
      "bluertopo_tiles",
      "bluertopo_resolution",
      "bluertopo_cache_dir",
      "bluertopo_cache_clear"
    )
  )
  expect_true("cache_dir" %in% names(formals(bluertopo_download)))
  expect_false("aoi" %in% names(formals(bluertopo_tile_polygons)))
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
  expect_error(env$bt_real_example_setup(), "Website data examples are disabled")
})

test_that("public examples are network-gated, concise, and not fixture-rendered", {
  example_vignettes <- public_example_vignettes()
  skip_if(!length(example_vignettes), "vignette sources are not available in this test context")
  text <- lapply(example_vignettes, readLines, warn = FALSE)
  names(text) <- basename(example_vignettes)
  forbidden_promotional_language <- paste(c(
    "Real NOAA Proof", "homepage proof", "Actual NOAA", "real NOAA",
    "real BlueTopo", "real data", "public site uses real", "live BlueTopo",
    "Real Example Setup", "without synthetic rasters"
  ), collapse = "|")

  for (content in text) {
    collapsed <- paste(content, collapse = "\n")
    expect_match(collapsed, "eval=bt_real_examples_enabled\\(\\)")
    expect_false(grepl("Synthetic miniature BlueTopo", collapsed, fixed = TRUE))
    expect_false(grepl(
      "not for navigation|vertical-datum|not affiliated|intentionally small",
      collapsed,
      ignore.case = TRUE
    ))
    expect_match(collapsed, "BlueTopo (source )?tiles|BlueTopo tiles")
    expect_false(grepl(forbidden_promotional_language, collapsed, ignore.case = TRUE))
  }
})

test_that("real example AOI metadata is documented", {
  vignette_dir <- example_vignette_dir()
  skip_if(is.na(vignette_dir), "vignette sources are not available in this test context")
  metadata <- file.path(vignette_dir, "real-example-aoi.md")
  expect_true(file.exists(metadata))
  text <- paste(readLines(metadata, warn = FALSE), collapse = "\n")
  expect_match(text, "new-york-harbor-upper-bay-2026-07-10", fixed = TRUE)
  expect_match(text, "New York Harbor", fixed = TRUE)
  expect_match(text, "xmin = -74.045", fixed = TRUE)
  expect_match(text, "Expected primary total download size", fixed = TRUE)
  expect_match(text, "key-west-boca-chica-mixed-grid-2026-07-10", fixed = TRUE)
  expect_match(text, "Expected secondary total download size", fixed = TRUE)
  expect_match(text, "Date last verified: 2026-07-10", fixed = TRUE)
})

test_that("README and pkgdown config describe public examples", {
  readme_path <- project_file("README.Rmd")
  config_path <- project_file("_pkgdown.yml")
  index_path <- project_file("index.Rmd")
  skip_if(
    is.na(readme_path) || is.na(config_path) || is.na(index_path),
    "source README/pkgdown config/index are not available in this installed test context"
  )

  readme <- paste(readLines(readme_path, warn = FALSE), collapse = "\n")
  expect_false(grepl("Examples tab uses synthetic", readme, fixed = TRUE))
  expect_match(readme, "uses BlueTopo source tiles for New\\s+York Harbor")
  expect_match(readme, "New\\s+York Harbor")
  expect_match(readme, "Normal\\s+package tests use\\s+small synthetic fixtures")
  expect_match(readme, "bathy <- bluertopo\\(aoi\\)")
  expect_false(grepl("library(terra)", readme, fixed = TRUE))
  expect_match(readme, "aoi_sf <- sf::st_read", fixed = TRUE)
  expect_match(readme, "terra::SpatRasterCollection", fixed = TRUE)
  expect_match(readme, "c\\(xmin, ymin, xmax, ymax\\)")
  expect_match(readme, "https://nauticalcharts.noaa.gov/data/bluetopo_specs.html", fixed = TRUE)

  index <- paste(readLines(index_path, warn = FALSE), collapse = "\n")
  expect_match(index, "National Oceanic and\\s+Atmospheric Administration \\(NOAA\\)")
  expect_false(grepl("library(terra)", index, fixed = TRUE))
  expect_match(index, "bt_plot_bathy_map\\(real_bathy\\$data")
  expect_match(index, "This example demonstrates tile discovery, verified asset retrieval")

  public_text <- c(
    index,
    readme,
    vapply(public_example_vignettes(), function(path) {
      paste(readLines(path, warn = FALSE), collapse = "\n")
    }, character(1L))
  )
  caveat_counts <- lengths(regmatches(
    tolower(public_text),
    gregexpr("blue ?topo is not for navigation", tolower(public_text), perl = TRUE)
  ))
  expect_equal(sum(caveat_counts), 1L)

  config <- paste(readLines(config_path, warn = FALSE), collapse = "\n")
  expect_match(config, "left: \\[intro, reference, examples, articles, news\\]")
  expect_match(config, "text: Examples", fixed = TRUE)
  expect_match(config, "href: articles/examples.html", fixed = TRUE)
  expect_match(config, "div.sourceCode pre", fixed = TRUE)
})

test_that("public function examples use the current concise AOI", {
  source_paths <- c(
    project_file("R", "bluertopo.R"),
    project_file("R", "tiles.R"),
    project_file("R", "download.R")
  )
  skip_if(any(is.na(source_paths)), "API source files are not available in this installed test context")
  content <- paste(unlist(lapply(source_paths, readLines, warn = FALSE)), collapse = "\n")

  expect_false(grepl("-66.2", content, fixed = TRUE))
  expect_match(content, "xmin = -74.045")
  expect_match(content, "\\\\dontshow\\{")
  expect_match(content, "curl::nslookup")
  expect_false(grepl("Network-backed example skipped", content, fixed = TRUE))
})

test_that("public markdown chunks do not start with blank lines", {
  source_files <- c(
    project_file("README.Rmd"),
    project_file("index.Rmd"),
    public_example_vignettes()
  )
  source_files <- source_files[!is.na(source_files) & file.exists(source_files)]
  skip_if(!length(source_files), "source markdown files are not available in this test context")

  for (path in source_files) {
    lines <- readLines(path, warn = FALSE)
    starts <- grep("^```\\{r", lines)
    for (start in starts) {
      if (start < length(lines)) {
        expect_false(
          identical(lines[start + 1L], ""),
          info = sprintf("%s has a blank line immediately after chunk header line %d", basename(path), start)
        )
      }
    }
  }
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
  expect_identical(setup$place, "New York Harbor")

  manifest <- env$bt_real_download_assets(setup)
  expect_s3_class(manifest, "bluertopo_downloads")
  expect_true(all(manifest$verified))
  expect_true(any(manifest$asset_type == "rat"))

  geotiff <- manifest$local_path[manifest$asset_type == "geotiff"][1L]
  expect_true(file.exists(geotiff))
  expect_gte(terra::nlyr(terra::rast(geotiff)), 3L)

  mixed_setup <- env$bt_mixed_example_setup()
  withr::defer(mixed_setup$restore())
  expect_lte(mixed_setup$planned_bytes, env$bt_real_example_size_cap())
  expect_lte(nrow(mixed_setup$tiles), 4L)
  expect_true(length(unique(as.data.frame(mixed_setup$tiles)$resolution_m)) > 1L)
})
