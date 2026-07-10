.bt_area_m2 <- function(v) {
  if (is.null(v) || nrow(v) == 0L) {
    return(numeric())
  }
  as.numeric(terra::expanse(v, unit = "m", transform = TRUE))
}

.bt_union_area_m2 <- function(v) {
  if (is.null(v) || nrow(v) == 0L) {
    return(0)
  }
  u <- tryCatch(terra::aggregate(v), error = function(e) NULL)
  if (is.null(u)) {
    return(sum(.bt_area_m2(v), na.rm = TRUE))
  }
  sum(.bt_area_m2(u), na.rm = TRUE)
}

.bt_coverage_diagnostics <- function(aoi, published_intersections, selected_intersections, min_coverage) {
  aoi_area <- .bt_union_area_m2(aoi)
  published_area <- .bt_union_area_m2(published_intersections)
  selected_area <- .bt_union_area_m2(selected_intersections)
  published_fraction <- if (aoi_area > 0) published_area / aoi_area else 0
  selected_coverage <- if (published_area > 0) selected_area / published_area else 0
  selected_aoi <- if (aoi_area > 0) selected_area / aoi_area else 0
  list(
    published_coverage_fraction = min(1, published_fraction),
    selected_coverage_fraction = min(1, selected_coverage),
    selected_aoi_fraction = min(1, selected_aoi),
    target_coverage = min_coverage,
    target_met = isTRUE(selected_coverage + sqrt(.Machine$double.eps) >= min_coverage),
    aoi_area_m2 = aoi_area,
    published_area_m2 = published_area,
    selected_area_m2 = selected_area,
    coverage_type = "geometric tile-index coverage"
  )
}

.bt_enforce_coverage <- function(coverage, diagnostics) {
  if (identical(coverage, "ignore") || isTRUE(diagnostics$target_met)) {
    return(invisible(TRUE))
  }
  msg <- sprintf(
    "Selected BlueTopo tile coverage is %.1f%% of published coverage; target is %.1f%%.",
    100 * diagnostics$selected_coverage_fraction,
    100 * diagnostics$target_coverage
  )
  if (identical(coverage, "warn")) {
    .bt_warn(c(
      msg,
      "i" = "Use `coverage = \"fill\"` to add fallback native resolutions or lower `min_coverage`."
    ), class = "bluertopo_warning_partial_coverage")
  } else if (identical(coverage, "error")) {
    .bt_abort(c(
      msg,
      "i" = "Use `coverage = \"fill\"` to add fallback native resolutions or lower `min_coverage`."
    ), class = "bluertopo_error_no_coverage")
  }
  invisible(TRUE)
}

.bt_apply_resolution_selection <- function(candidates, intersections, aoi, resolution, coverage, min_coverage) {
  coverage <- .bt_match_arg(coverage, c("ignore", "warn", "error", "fill"), "coverage")
  min_coverage <- .bt_validate_number(min_coverage, "min_coverage", positive = FALSE)
  if (min_coverage < 0 || min_coverage > 1) {
    .bt_abort("`min_coverage` must be between 0 and 1.", class = "bluertopo_error_resolution")
  }
  spec <- .bt_resolution_spec(resolution)
  effective_min_coverage <- if (identical(spec$strategy, "coverage")) spec$min_coverage else min_coverage
  df <- as.data.frame(candidates)
  area_named <- stats::setNames(df$intersection_area_m2, df$resolution_m)
  plan <- .bt_resolution_plan(spec, df$resolution_m, area = area_named)
  plan$effective_min_coverage <- effective_min_coverage
  initial_values <- plan$initial
  selected_values <- initial_values
  valid_ids <- as.character(df$tile_id)
  selected_ids <- valid_ids[df$resolution_m %in% selected_values]
  inter_df <- as.data.frame(intersections)
  published_intersections <- intersections[inter_df$tile_id %in% valid_ids, ]
  selected_intersections <- intersections[inter_df$tile_id %in% selected_ids, ]
  diagnostics <- .bt_coverage_diagnostics(aoi, published_intersections, selected_intersections, effective_min_coverage)
  diagnostics$target_source <- if (identical(spec$strategy, "coverage")) {
    "resolution"
  } else {
    "min_coverage"
  }
  fallback_steps <- list()

  if (identical(coverage, "fill") && !isTRUE(diagnostics$target_met)) {
    for (value in plan$fallback) {
      if (value %in% selected_values) {
        next
      }
      selected_values <- sort(unique(c(selected_values, value)))
      selected_ids <- valid_ids[df$resolution_m %in% selected_values]
      selected_intersections <- intersections[inter_df$tile_id %in% selected_ids, ]
      diagnostics <- .bt_coverage_diagnostics(
        aoi,
        published_intersections,
        selected_intersections,
        effective_min_coverage
      )
      diagnostics$target_source <- if (identical(spec$strategy, "coverage")) {
        "resolution"
      } else {
        "min_coverage"
      }
      fallback_steps[[length(fallback_steps) + 1L]] <- list(
        added_resolution_m = value,
        selected_coverage_fraction = diagnostics$selected_coverage_fraction,
        target_met = diagnostics$target_met
      )
      if (isTRUE(diagnostics$target_met)) {
        break
      }
    }
  }

  selected <- df$resolution_m %in% selected_values
  if (!any(selected)) {
    .bt_abort("No BlueTopo tiles were selected after applying the resolution policy.",
      class = "bluertopo_error_no_coverage"
    )
  }
  candidates$selected <- selected
  candidates$fallback <- selected & !(df$resolution_m %in% initial_values)
  candidates$selection_reason <- ifelse(candidates$fallback, "coverage_fallback", spec$strategy)

  selected_df <- as.data.frame(candidates)[selected, , drop = FALSE]
  selected_order <- .bt_selection_order(selected_df, plan$preference)
  selected_indices <- which(selected)[selected_order]
  rank <- seq_along(selected_indices)
  candidates$selection_rank <- NA_integer_
  candidates$overlap_priority <- NA_integer_
  candidates$selection_rank[selected_indices] <- rank
  candidates$overlap_priority[selected_indices] <- rank

  selected_tiles <- candidates[selected_indices, ]
  attr(selected_tiles, "coverage") <- diagnostics
  attr(selected_tiles, "resolution_spec") <- spec
  attr(selected_tiles, "resolution_plan") <- plan
  attr(selected_tiles, "fallback_steps") <- fallback_steps
  .bt_enforce_coverage(if (identical(coverage, "fill")) "warn" else coverage, diagnostics)
  selected_tiles
}

.bt_selection_order <- function(df, preference) {
  pref_rank <- match(df$resolution_m, preference)
  pref_rank[is.na(pref_rank)] <- length(preference) + 1L
  delivered <- df$delivered_date
  if (!inherits(delivered, "POSIXt")) {
    delivered <- .bt_parse_datetime(delivered)
  }
  delivered_num <- as.numeric(delivered)
  delivered_num[is.na(delivered_num)] <- -Inf
  complete <- nzchar(df$geotiff_url %||% "") & nzchar(df$geotiff_sha256 %||% "")
  order(pref_rank, -delivered_num, -as.integer(complete), df$tile_id)
}
