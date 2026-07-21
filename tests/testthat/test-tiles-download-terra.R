test_that("tile discovery applies resolution and coverage policies", {
  with_bt_fixture({
    expect_warning(
      finest <- bluertopo_tiles(fixture$aoi, resolution = "finest", coverage = "warn", min_coverage = 1),
      class = "bluertopo_warning_partial_coverage"
    )
    expect_equal(as.data.frame(finest)$resolution_m, 4)
    filled <- bluertopo_tiles(fixture$aoi, resolution = "finest", coverage = "fill", min_coverage = 1)
    expect_equal(sort(as.data.frame(filled)$resolution_m), c(4, 8))
    expect_true(any(as.data.frame(filled)$fallback))
    coverage <- attr(filled, "coverage")
    expect_true(coverage$target_met)

    coverage_policy <- bluertopo_resolution("coverage", prefer = "finest", min_coverage = 0.5)
    policy_tiles <- bluertopo_tiles(fixture$aoi, resolution = coverage_policy, coverage = "error", min_coverage = 1)
    policy_coverage <- attr(policy_tiles, "coverage")
    expect_equal(policy_coverage$target_coverage, 0.5)
    expect_equal(policy_coverage$target_source, "resolution")

    expect_error(
      bluertopo_tiles(fixture$aoi, resolution = "finest", coverage = "error", min_coverage = 1),
      class = "bluertopo_error_no_coverage"
    )
    ignored <- bluertopo_tiles(fixture$aoi, resolution = "finest", coverage = "ignore", min_coverage = 1)
    expect_equal(as.data.frame(ignored)$resolution_m, 4)
  })
})

test_that("all tile polygons can be retrieved without an AOI", {
  with_bt_fixture({
    tiles <- bluertopo_tile_polygons()

    expect_s4_class(tiles, "SpatVector")
    expect_equal(nrow(tiles), 4L)
    expect_setequal(
      as.data.frame(tiles)$tile_id,
      c("TILE_4M_A", "TILE_8M_B", "TILE_2M_C", "TILE_16M_D")
    )
    expect_true(all(c("geotiff_url", "resolution_m", "geotiff_sha256") %in% names(tiles)))
    expect_false("aoi" %in% names(formals(bluertopo_tile_polygons)))
    expect_identical(
      attr(tiles, "bluertopo_catalog")$catalog_name,
      basename(fixture$catalog)
    )
  })
})

test_that("downloader supports dry run, SHA-256 validation, RAT sidecars, and reuse", {
  with_bt_fixture({
    plan <- bluertopo_download(
      fixture$aoi,
      path = fixture$downloads,
      coverage = "fill",
      dry_run = TRUE,
      progress = FALSE,
      cache_dir = fixture$cache
    )
    expect_s3_class(plan, "bluertopo_downloads")
    expect_true(all(plan$status == "planned"))
    expect_false(dir.exists(fixture$downloads))

    manifest <- bluertopo_download(
      fixture$aoi,
      path = fixture$downloads,
      coverage = "fill",
      progress = FALSE
    )
    expect_true(all(manifest$status == "downloaded"))
    expect_true(all(manifest$verified))
    expect_true(any(manifest$asset_type == "rat"))
    expect_true(file.exists(file.path(fixture$downloads, "bluertopo-download-manifest.csv")))
    query_manifests <- list.files(
      file.path(fixture$downloads, "manifests"),
      pattern = "bluertopo-download-manifest-",
      full.names = TRUE
    )
    expect_true(any(grepl("\\.csv$", query_manifests)))
    expect_true(any(grepl("\\.json$", query_manifests)))

    reused <- bluertopo_download(
      fixture$aoi,
      path = fixture$downloads,
      coverage = "fill",
      progress = FALSE
    )
    expect_true(all(reused$status == "reused_verified"))

    expect_error(
      bluertopo_download(
        fixture$aoi,
        path = file.path(fixture$root, "workers"),
        coverage = "fill",
        workers = 2,
        progress = FALSE
      ),
      class = "bluertopo_error_download"
    )
    expect_error(
      bluertopo_download(
        fixture$aoi,
        path = file.path(fixture$root, "invalid-retries"),
        retries = 1.5,
        progress = FALSE
      ),
      class = "bluertopo_error_argument"
    )
    expect_error(
      bluertopo_download(
        fixture$aoi,
        path = file.path(fixture$root, "size-verify"),
        coverage = "fill",
        verify = "size",
        progress = FALSE
      ),
      class = "bluertopo_error_download"
    )
  })
})

test_that("bluertopo returns lazy terra outputs and detailed provenance", {
  with_bt_fixture({
    result <- bluertopo(
      fixture$aoi,
      coverage = "fill",
      cache_dir = fixture$cache,
      progress = FALSE,
      details = TRUE
    )
    expect_s3_class(result, "bluertopo_result")
    expect_s4_class(result$data, "SpatRaster")
    expect_equal(names(result$data), "elevation")
    expect_true(result$coverage$target_met)
    expect_true(result$provenance$no_vertical_datum_conversion_performed)
    expect_equal(result$query$requested_layers, "elevation")
    expect_equal(result$query$access, "download")
    expect_type(result$query$query_hash, "character")
    expect_identical(result$provenance$query_hash, result$query$query_hash)

    all_layers <- bluertopo(
      fixture$aoi_left,
      layers = "all",
      cache_dir = fixture$cache,
      progress = FALSE
    )
    expect_equal(names(all_layers), c("elevation", "uncertainty", "contributor"))
  })
})

test_that("compound BlueTopo CRS cropping does not require remote PROJ grids", {
  horizontal <- terra::crs("EPSG:26918")
  vertical <- paste0(
    "VERTCRS[\"NAVD88 height\",",
    "VDATUM[\"North American Vertical Datum 1988\"],",
    "CS[vertical,1],",
    "AXIS[\"gravity-related height (H)\",up,LENGTHUNIT[\"metre\",1]]]"
  )
  compound <- paste0(
    "COMPOUNDCRS[\"NAD83 / UTM zone 18N + NAVD88 height\",",
    horizontal,
    ",",
    vertical,
    "]"
  )
  r <- terra::rast(
    nrows = 100,
    ncols = 100,
    xmin = 575000,
    xmax = 585000,
    ymin = 4494000,
    ymax = 4506000,
    crs = compound
  )
  terra::values(r) <- 1
  aoi <- .bt_normalize_aoi(c(-74.05, 40.65, -74.00, 40.70))

  projected <- .bt_project_aoi_to_raster(aoi, r)
  expect_true(all(is.finite(as.vector(terra::ext(projected)))))
  expect_equal(terra::crs(projected), terra::crs(r))

  cropped <- .bt_crop_mask_raster(r, aoi, crop = TRUE, mask = FALSE)
  expect_s4_class(cropped, "SpatRaster")
  expect_gt(terra::ncell(cropped), 0)
})

test_that("explicit output grid produces one raster and rejects geographic target resolution", {
  with_bt_fixture({
    expect_warning(
      x <- bluertopo(
        fixture$aoi,
        coverage = "fill",
        cache_dir = fixture$cache,
        output_crs = "EPSG:3857",
        output_resolution = 50000,
        combine = "single",
        progress = FALSE
      ),
      class = "bluertopo_warning_resampled"
    )
    expect_s4_class(x, "SpatRaster")
    expect_error(
      bluertopo(
        fixture$aoi,
        coverage = "fill",
        cache_dir = fixture$cache,
        output_crs = "EPSG:4326",
        output_resolution = 0.1,
        combine = "single",
        progress = FALSE
      ),
      class = "bluertopo_error_mixed_grid"
    )
    expect_error(
      bluertopo(
        fixture$aoi,
        cache_dir = fixture$cache,
        output_crs = 26918,
        output_resolution = 10,
        progress = FALSE
      ),
      class = "bluertopo_error_argument"
    )
  })
})
