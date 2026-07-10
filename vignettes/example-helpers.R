bt_fixture_label <- "Synthetic miniature BlueTopo fixture for package demonstration."

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

bt_load_bluertopo <- function() {
  if (requireNamespace("bluertopo", quietly = TRUE)) {
    suppressPackageStartupMessages(require("bluertopo", character.only = TRUE))
    return(invisible(TRUE))
  }
  root <- if (file.exists("DESCRIPTION")) {
    "."
  } else if (file.exists(file.path("..", "DESCRIPTION"))) {
    ".."
  } else {
    NA_character_
  }
  if (is.na(root) || !requireNamespace("pkgload", quietly = TRUE)) {
    stop("Install bluertopo or pkgload to render this example from the source tree.", call. = FALSE)
  }
  pkgload::load_all(root, quiet = TRUE)
  invisible(TRUE)
}

bt_load_bluertopo()

bt_example_setup <- function() {
  example <- bluertopo:::.bt_example_setup()
  message(bt_fixture_label)
  message("Fixture-only option: bluertopo.allow_test_hosts = TRUE enables local file URLs.")
  example
}

bt_round <- function(x, digits = 3) {
  if (is.numeric(x)) round(x, digits) else x
}

bt_display_table <- function(x, digits = 3, ...) {
  x[] <- lapply(x, bt_round, digits = digits)
  knitr::kable(x, ...)
}

bt_short_path <- function(x, keep = 2L) {
  vapply(x, function(path) {
    if (is.na(path) || !nzchar(path)) {
      return(NA_character_)
    }
    parts <- strsplit(path, .Platform$file.sep, fixed = TRUE)[[1L]]
    parts <- parts[nzchar(parts)]
    paste(utils::tail(parts, keep), collapse = .Platform$file.sep)
  }, character(1L))
}

bt_short_sha <- function(x, n = 12L) {
  ifelse(is.na(x) | !nzchar(x), NA_character_, substr(x, 1L, n))
}

bt_coverage_table <- function(coverage) {
  fields <- c(
    "published_coverage_fraction",
    "selected_coverage_fraction",
    "selected_aoi_fraction",
    "target_coverage",
    "target_met",
    "coverage_type"
  )
  as.data.frame(coverage[fields], stringsAsFactors = FALSE)
}

bt_tile_table <- function(tiles) {
  df <- as.data.frame(tiles)
  keep <- c(
    "tile_id",
    "resolution_m",
    "utm_zone",
    "delivered_date",
    "intersection_area_m2",
    "intersection_fraction",
    "selection_rank",
    "selection_reason",
    "fallback"
  )
  df[intersect(keep, names(df))]
}

bt_plot_tiles <- function(tiles, aoi, main = "Synthetic BlueTopo fixture tiles") {
  df <- as.data.frame(tiles)
  values <- sort(unique(df$resolution_m))
  palette <- c("#8ecae6", "#90be6d", "#f9c74f", "#f8961e", "#577590")
  colors <- stats::setNames(palette[seq_along(values)], values)
  tile_cols <- grDevices::adjustcolor(colors[as.character(df$resolution_m)], alpha.f = 0.45)
  terra::plot(tiles, col = tile_cols, border = "#2b2d42", lwd = 1.2, main = main)
  terra::plot(aoi, add = TRUE, border = "#d00000", lwd = 2.5)
  legend(
    "topright",
    legend = c(paste(values, "m native source resolution"), "AOI"),
    fill = c(grDevices::adjustcolor(colors[as.character(values)], alpha.f = 0.45), NA),
    border = c(rep("#2b2d42", length(values)), "#d00000"),
    bty = "n",
    cex = 0.8
  )
}

bt_rasters <- function(x) {
  if (inherits(x, "SpatRasterCollection")) {
    as.list(x)
  } else {
    list(x)
  }
}

bt_raster_summary <- function(x) {
  rasters <- bt_rasters(x)
  names <- names(x)
  if (is.null(names) || length(names) != length(rasters)) {
    names <- paste0("grid_", seq_along(rasters))
  }
  do.call(rbind, lapply(seq_along(rasters), function(i) {
    r <- rasters[[i]]
    crs_desc <- tryCatch(terra::crs(r, describe = TRUE), error = function(e) NULL)
    epsg <- if (!is.null(crs_desc)) crs_desc$code else NA_character_
    data.frame(
      group_name = names[i],
      class = class(r)[1L],
      crs = paste0("EPSG:", epsg %||% "unknown"),
      resolution = paste(round(terra::res(r), 3), collapse = " x "),
      source_count = length(terra::sources(r)),
      layer_names = paste(names(r), collapse = ", "),
      stringsAsFactors = FALSE
    )
  }))
}

bt_plot_first_raster <- function(x, main, layer = 1L) {
  r <- bt_rasters(x)[[1L]]
  if (terra::nlyr(r) >= layer) {
    r <- r[[layer]]
  }
  terra::plot(r, main = main)
  invisible(r)
}

bt_sources_table <- function(x) {
  sources <- unique(unlist(lapply(bt_rasters(x), terra::sources), use.names = FALSE))
  data.frame(source = bt_short_path(sources, keep = 4L), stringsAsFactors = FALSE)
}

bt_manifest_table <- function(manifest) {
  df <- as.data.frame(manifest)
  df$actual_sha256 <- bt_short_sha(df$actual_sha256)
  df$downloaded_bytes <- as.integer(df$downloaded_bytes)
  df[c(
    "tile_id",
    "asset_type",
    "source_basename",
    "status",
    "verification_mode",
    "verified",
    "downloaded_bytes",
    "actual_sha256",
    "attempts"
  )]
}

bt_status_counts <- function(manifest) {
  df <- as.data.frame(manifest)
  counts <- as.data.frame(table(status = df$status), stringsAsFactors = FALSE)
  names(counts) <- c("status", "count")
  counts
}

bt_parse_rat <- function(paths) {
  rows <- lapply(paths[file.exists(paths)], function(path) {
    doc <- xml2::read_xml(path)
    nodes <- xml2::xml_find_all(doc, ".//Contributor")
    if (!length(nodes)) {
      return(NULL)
    }
    data.frame(
      contributor_id = as.integer(xml2::xml_attr(nodes, "id")),
      source_survey_id = xml2::xml_attr(nodes, "source_survey_id"),
      source_institution = xml2::xml_attr(nodes, "source_institution"),
      source_type = xml2::xml_attr(nodes, "source_type"),
      stringsAsFactors = FALSE
    )
  })
  unique(do.call(rbind, rows))
}
