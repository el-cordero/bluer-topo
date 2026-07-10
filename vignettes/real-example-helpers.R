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
    stop("Install bluertopo or pkgload to render these examples from source.", call. = FALSE)
  }
  pkgload::load_all(root, quiet = TRUE)
  invisible(TRUE)
}

bt_load_bluertopo()

bt_real_examples_enabled <- function() {
  identical(tolower(Sys.getenv("BLUERTOPO_BUILD_REAL_EXAMPLES")), "true")
}

bt_real_example_label <- paste(
  "This example uses actual NOAA BlueTopo source tiles downloaded from the",
  "public NOAA National Bathymetric Source bucket during the pkgdown build."
)

bt_offline_note <- paste(
  "This page is configured to render real BlueTopo outputs on the package",
  "website. In CRAN or offline builds, live chunks are not evaluated."
)

bt_noaa_caveat <- paste(
  "BlueTopo is not for navigation. `bluertopo` is not affiliated with,",
  "endorsed by, or supported by NOAA, and it performs no vertical-datum",
  "conversion."
)

bt_real_example_aoi <- function() {
  c(xmin = -81.835, ymin = 24.815, xmax = -81.805, ymax = 24.845)
}

bt_real_example_aoi_id <- function() {
  "key-west-boca-chica-2026-07-10"
}

bt_real_example_cache_dir <- function() {
  path.expand(Sys.getenv(
    "BLUERTOPO_REAL_EXAMPLE_CACHE",
    "~/.cache/bluertopo-pkgdown-real-examples"
  ))
}

bt_real_example_size_cap <- function() {
  250 * 1024^2
}

bt_bbox_vect <- function(bbox) {
  coords <- cbind(
    c(bbox[["xmin"]], bbox[["xmax"]], bbox[["xmax"]], bbox[["xmin"]], bbox[["xmin"]]),
    c(bbox[["ymin"]], bbox[["ymin"]], bbox[["ymax"]], bbox[["ymax"]], bbox[["ymin"]])
  )
  terra::vect(coords, type = "polygons", crs = "EPSG:4326")
}

bt_require_real_examples <- function() {
  if (!bt_real_examples_enabled()) {
    stop(
      paste(
        "Real BlueTopo examples are disabled.",
        "Set BLUERTOPO_BUILD_REAL_EXAMPLES=true to query NOAA and render outputs."
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

bt_url_size <- function(url) {
  handle <- curl::new_handle(nobody = TRUE, useragent = "bluertopo-real-examples")
  response <- curl::curl_fetch_memory(url, handle = handle)
  if (response$status_code < 200L || response$status_code >= 300L) {
    stop(sprintf("HEAD request failed for %s with status %s.", url, response$status_code), call. = FALSE)
  }
  headers <- curl::parse_headers_list(response$headers)
  size <- suppressWarnings(as.numeric(headers[["content-length"]] %||% NA_real_))
  if (is.na(size) || !is.finite(size) || size <= 0) {
    stop(sprintf("NOAA object size is unavailable for %s.", url), call. = FALSE)
  }
  size
}

bt_real_example_plan_sizes <- function(tiles, rat = TRUE) {
  df <- as.data.frame(tiles)
  urls <- df$geotiff_url
  asset_type <- rep("geotiff", length(urls))
  tile_id <- df$tile_id
  if (isTRUE(rat)) {
    has_rat <- !is.na(df$rat_url) & nzchar(df$rat_url)
    urls <- c(urls, df$rat_url[has_rat])
    asset_type <- c(asset_type, rep("rat", sum(has_rat)))
    tile_id <- c(tile_id, df$tile_id[has_rat])
  }
  bytes <- vapply(urls, bt_url_size, numeric(1L))
  data.frame(
    tile_id = tile_id,
    asset_type = asset_type,
    source_basename = basename(vapply(urls, function(x) curl::curl_parse_url(x)$path, "")),
    source_url = urls,
    planned_bytes = bytes,
    stringsAsFactors = FALSE
  )
}

bt_real_example_setup <- function() {
  bt_require_real_examples()
  cache_dir <- bt_real_example_cache_dir()
  package_cache <- file.path(cache_dir, "package-cache")
  download_dir <- file.path(cache_dir, "downloads", bt_real_example_aoi_id())
  old <- options(bluertopo.cache_dir = package_cache)
  bbox <- bt_real_example_aoi()
  aoi <- bt_bbox_vect(bbox)
  tiles <- bluertopo_tiles(
    aoi,
    resolution = "native",
    coverage = "fill",
    refresh = "if_stale",
    quiet = TRUE
  )
  plan <- bt_real_example_plan_sizes(tiles, rat = TRUE)
  total_bytes <- sum(plan$planned_bytes, na.rm = TRUE)
  if (nrow(tiles) > 4L || total_bytes > bt_real_example_size_cap()) {
    options(old)
    stop(
      sprintf(
        "Real example plan selected %d tile(s) and %.1f MB; cap is %.1f MB.",
        nrow(tiles),
        total_bytes / 1024^2,
        bt_real_example_size_cap() / 1024^2
      ),
      call. = FALSE
    )
  }
  list(
    aoi = aoi,
    bbox = bbox,
    tiles = tiles,
    cache_dir = cache_dir,
    package_cache = package_cache,
    download_dir = download_dir,
    selected_policy = "native source resolution with coverage fill",
    example_label = bt_real_example_label,
    source_catalog = attr(tiles, "bluertopo_catalog"),
    planned_assets = plan,
    planned_bytes = total_bytes,
    restore = function() options(old)
  )
}

bt_real_example_cache_key_info <- function() {
  setup <- bt_real_example_setup()
  on.exit(setup$restore(), add = TRUE)
  catalog <- setup$source_catalog
  list(
    behavior_version = catalog$behavior_version %||% "unknown",
    aoi_id = bt_real_example_aoi_id(),
    catalog_checksum = substr(catalog$local_checksum %||% "unknown", 1L, 16L)
  )
}

bt_real_example_preflight <- function() {
  setup <- bt_real_example_setup()
  on.exit(setup$restore(), add = TRUE)
  message(sprintf("AOI: %s", bt_real_example_aoi_id()))
  message(sprintf("Tiles: %s", paste(as.data.frame(setup$tiles)$tile_id, collapse = ", ")))
  message(sprintf("Planned assets: %d", nrow(setup$planned_assets)))
  message(sprintf("Planned bytes: %d", setup$planned_bytes))
  invisible(setup)
}

bt_real_download_assets <- function(setup) {
  bluertopo_download(
    setup$aoi,
    path = setup$download_dir,
    resolution = "native",
    coverage = "fill",
    rat = TRUE,
    verify = "sha256",
    on_exists = "verify",
    progress = FALSE,
    quiet = TRUE
  )
}

bt_round <- function(x, digits = 3) {
  if (is.numeric(x)) round(x, digits) else x
}

bt_display_table <- function(x, digits = 3, ..., row_names = FALSE) {
  x[] <- lapply(x, bt_round, digits = digits)
  knitr::kable(x, ..., row.names = row_names)
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

bt_short_url <- function(x, keep = 4L) {
  vapply(x, function(url) {
    if (is.na(url) || !nzchar(url)) {
      return(NA_character_)
    }
    parsed <- curl::curl_parse_url(url)
    parts <- strsplit(parsed$path %||% "", "/", fixed = TRUE)[[1L]]
    parts <- parts[nzchar(parts)]
    paste(c(parsed$host %||% "", utils::tail(parts, keep)), collapse = "/")
  }, character(1L))
}

bt_short_sha <- function(x, n = 12L) {
  ifelse(is.na(x) | !nzchar(x), NA_character_, substr(x, 1L, n))
}

bt_bytes_mb <- function(x) {
  round(as.numeric(x) / 1024^2, 3)
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

bt_tile_table <- function(tiles, include_urls = FALSE) {
  df <- as.data.frame(tiles)
  if (isTRUE(include_urls)) {
    df$geotiff_url <- bt_short_url(df$geotiff_url)
    df$rat_url <- bt_short_url(df$rat_url)
  }
  keep <- c(
    "tile_id",
    "resolution_m",
    "utm_zone",
    "delivered_date",
    "intersection_area_m2",
    "intersection_fraction",
    "selection_rank",
    "selection_reason",
    "fallback",
    if (isTRUE(include_urls)) c("geotiff_url", "rat_url")
  )
  df[intersect(keep, names(df))]
}

bt_plot_tiles <- function(tiles, aoi, main = "Real NOAA BlueTopo tile footprints") {
  df <- as.data.frame(tiles)
  values <- sort(unique(df$resolution_m))
  palette <- c("#0a9396", "#94d2bd", "#ee9b00", "#ca6702", "#005f73")
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
  raster_names <- names(x)
  if (is.null(raster_names) || length(raster_names) != length(rasters)) {
    raster_names <- paste0("grid_", seq_along(rasters))
  }
  do.call(rbind, lapply(seq_along(rasters), function(i) {
    r <- rasters[[i]]
    crs_desc <- tryCatch(terra::crs(r, describe = TRUE), error = function(e) NULL)
    epsg <- if (!is.null(crs_desc)) crs_desc$code else NA_character_
    data.frame(
      group_name = raster_names[i],
      class = class(r)[1L],
      crs = paste0("EPSG:", epsg %||% "unknown"),
      resolution = paste(round(terra::res(r), 3), collapse = " x "),
      source_count = length(terra::sources(r)),
      layer_names = paste(names(r), collapse = ", "),
      stringsAsFactors = FALSE
    )
  }))
}

bt_plot_first_raster <- function(x, main, layer = 1L, categorical = FALSE) {
  r <- bt_rasters(x)[[1L]]
  if (terra::nlyr(r) >= layer) {
    r <- r[[layer]]
  }
  if (isTRUE(categorical)) {
    terra::plot(r, main = main, col = hcl.colors(12, "Dark 3"))
  } else {
    terra::plot(r, main = main)
  }
  invisible(r)
}

bt_sources_table <- function(x) {
  sources <- unique(unlist(lapply(bt_rasters(x), terra::sources), use.names = FALSE))
  data.frame(source = bt_short_path(sources, keep = 4L), stringsAsFactors = FALSE)
}

bt_manifest_table <- function(manifest) {
  df <- as.data.frame(manifest)
  df$actual_sha256 <- bt_short_sha(df$actual_sha256)
  df$downloaded_mb <- bt_bytes_mb(df$downloaded_bytes)
  df[c(
    "tile_id",
    "asset_type",
    "source_basename",
    "status",
    "verification_mode",
    "verified",
    "downloaded_mb",
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

bt_source_domain_summary <- function(manifest) {
  df <- as.data.frame(manifest)
  hosts <- vapply(df$source_url, function(url) curl::curl_parse_url(url)$host %||% NA_character_, "")
  out <- as.data.frame(table(domain = hosts, asset_type = df$asset_type), stringsAsFactors = FALSE)
  out[out$count > 0, , drop = FALSE]
}

bt_manifest_files_table <- function(download_dir) {
  manifest_files <- list.files(
    download_dir,
    pattern = "manifest\\.(csv|json)$|manifest-[A-Za-z0-9]+\\.(csv|json)$",
    recursive = TRUE,
    full.names = TRUE
  )
  data.frame(
    file = bt_short_path(manifest_files, keep = 4L),
    exists = file.exists(manifest_files),
    bytes = as.integer(file.info(manifest_files)$size),
    stringsAsFactors = FALSE
  )
}

bt_parse_rat <- function(paths, max_rows = 12L) {
  rows <- lapply(paths[file.exists(paths)], function(path) {
    doc <- xml2::read_xml(path)
    rat <- xml2::xml_find_first(doc, ".//GDALRasterAttributeTable")
    if (inherits(rat, "xml_missing")) {
      return(NULL)
    }
    fields <- xml2::xml_text(xml2::xml_find_all(rat, "./FieldDefn/Name"))
    values <- xml2::xml_find_all(rat, "./Row")
    if (!length(fields) || !length(values)) {
      return(NULL)
    }
    table_rows <- lapply(values, function(row) {
      vals <- xml2::xml_text(xml2::xml_find_all(row, "./F"))
      length(vals) <- length(fields)
      as.data.frame(as.list(stats::setNames(vals, fields)), stringsAsFactors = FALSE)
    })
    out <- do.call(rbind, table_rows)
    out$rat_source <- basename(path)
    out
  })
  out <- do.call(rbind, rows)
  if (is.null(out) || !nrow(out)) {
    return(data.frame())
  }
  if ("value" %in% names(out)) {
    names(out)[names(out) == "value"] <- "contributor_value"
  }
  keep <- c(
    "contributor_value",
    "source_survey_id",
    "source_institution",
    "license_name",
    "survey_date_start",
    "survey_date_end",
    "coverage",
    "bathy_coverage",
    "rat_source"
  )
  unique(utils::head(out[intersect(keep, names(out))], max_rows))
}

bt_catalog_table <- function(setup) {
  catalog <- setup$source_catalog
  data.frame(
    field = c(
      "catalog_name",
      "catalog_last_modified",
      "package_version",
      "not_for_navigation",
      "vertical_datum_conversion",
      "planned_download_mb"
    ),
    value = c(
      catalog$catalog_name %||% NA_character_,
      catalog$last_modified %||% NA_character_,
      catalog$package_version %||% NA_character_,
      "BlueTopo is not for navigation",
      "none performed by bluertopo",
      bt_bytes_mb(setup$planned_bytes)
    ),
    stringsAsFactors = FALSE
  )
}
