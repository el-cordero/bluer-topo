test_that("terra plotting is available when bluertopo is attached", {
  expect_true("package:terra" %in% search())

  raster <- terra::rast(nrows = 2, ncols = 2, vals = 1:4)
  plot_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(plot_file)
  on.exit(grDevices::dev.off(), add = TRUE)

  expect_no_error(plot(raster))
})
