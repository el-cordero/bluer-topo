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
  })
})

test_that("downloader supports dry run, SHA-256 validation, RAT sidecars, and reuse", {
  with_bt_fixture({
    plan <- bluertopo_download(
      fixture$aoi,
      path = fixture$downloads,
      coverage = "fill",
      dry_run = TRUE,
      progress = FALSE
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

    reused <- bluertopo_download(
      fixture$aoi,
      path = fixture$downloads,
      coverage = "fill",
      progress = FALSE
    )
    expect_true(all(reused$status == "reused_verified"))
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

    all_layers <- bluertopo(
      fixture$aoi_left,
      layers = "all",
      cache_dir = fixture$cache,
      progress = FALSE
    )
    expect_equal(names(all_layers), c("elevation", "uncertainty", "contributor"))
  })
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
  })
})
