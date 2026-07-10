test_that("resolution constructor validates meter semantics", {
  x <- bluertopo_resolution("nearest", value = "10 m", tie = "finer")
  expect_s3_class(x, "bluertopo_resolution")
  expect_equal(x$value, 10)
  expect_error(bluertopo_resolution("exact", values = 0), class = "bluertopo_error_resolution")
  expect_error(bluertopo_resolution("between", min_m = 16, max_m = 4), class = "bluertopo_error_resolution")
  expect_error(bluertopo_resolution("rank", n = 1.5), class = "bluertopo_error_resolution")
  expect_error(bluertopo_resolution("finest", scope = "local"), class = "bluertopo_error_resolution")
})

test_that("resolution plans cover shortcuts and are deterministic", {
  available <- c(8, 4, 16, 2)
  expect_equal(.bt_resolution_plan(.bt_resolution_spec("highest"), available)$initial, 2)
  expect_equal(.bt_resolution_plan(.bt_resolution_spec("lowest"), available)$initial, 16)
  expect_equal(.bt_resolution_plan(.bt_resolution_spec("best_available"), available)$initial, c(2, 4, 8, 16))
  expect_equal(.bt_resolution_plan(.bt_resolution_spec("coarsest_available"), available)$initial, c(2, 4, 8, 16))
  expect_equal(.bt_resolution_plan(.bt_resolution_spec(c(4, 8)), sample(available))$initial, c(4, 8))
  nearest <- bluertopo_resolution("nearest", value = 10, tie = "finer")
  expect_equal(.bt_resolution_plan(nearest, available)$initial, 8)
  nearest_coarse <- bluertopo_resolution("nearest", value = 10, tie = "coarser")
  expect_equal(.bt_resolution_plan(nearest_coarse, available)$initial, 8)
  between <- bluertopo_resolution("between", min_m = 4, max_m = 16)
  expect_equal(.bt_resolution_plan(between, sample(available))$initial, c(4, 8, 16))
  expect_equal(.bt_resolution_plan(bluertopo_resolution("rank", n = 2), available)$initial, 4)
  expect_equal(.bt_resolution_plan(bluertopo_resolution("coarsest_n", n = 2), available)$initial, c(8, 16))
  expect_equal(.bt_resolution_plan(bluertopo_resolution("finer_or_equal", value = 8), available)$initial, c(2, 4, 8))
  expect_equal(.bt_resolution_plan(bluertopo_resolution("coarser_or_equal", value = 8), available)$initial, c(8, 16))
  expect_error(
    .bt_resolution_plan(bluertopo_resolution("exact", values = 32), available),
    class = "bluertopo_error_resolution"
  )
})
