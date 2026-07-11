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

bt_real_example_place <- function() {
  "New York Harbor"
}

bt_real_example_description <- function() {
  paste(
    "New York Harbor, centered on Lower Manhattan, the Upper Bay,",
    "Governors Island, and the East River mouth"
  )
}

bt_real_example_label <- paste(
  "This example uses BlueTopo source tiles from the NOAA National Bathymetric",
  "Source catalog. The build verifies the downloaded assets and records their",
  "source metadata."
)

bt_offline_note <- paste(
  "In CRAN or offline builds, network-dependent chunks are not evaluated."
)

bt_noaa_caveat <- paste(
  "BlueTopo is not for navigation. `bluertopo` is not affiliated with,",
  "endorsed by, or supported by NOAA, and it performs no vertical-datum",
  "conversion."
)

bt_real_example_aoi <- function() {
  c(xmin = -74.045, ymin = 40.675, xmax = -73.995, ymax = 40.715)
}

bt_real_example_aoi_id <- function() {
  "new-york-harbor-upper-bay-2026-07-10"
}

bt_mixed_example_place <- function() {
  "Key West and Boca Chica Channel"
}

bt_mixed_example_description <- function() {
  paste(
    "a small Florida Keys AOI near Key West and Boca Chica Channel that",
    "currently intersects real 4 m and 8 m BlueTopo source grids"
  )
}

bt_mixed_example_aoi <- function() {
  c(xmin = -81.835, ymin = 24.815, xmax = -81.805, ymax = 24.845)
}

bt_mixed_example_aoi_id <- function() {
  "key-west-boca-chica-mixed-grid-2026-07-10"
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
        "Website data examples are disabled.",
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

bt_example_spec <- function(kind = c("primary", "mixed")) {
  kind <- match.arg(kind)
  if (identical(kind, "mixed")) {
    return(list(
      kind = "mixed",
      aoi = bt_mixed_example_aoi(),
      aoi_id = bt_mixed_example_aoi_id(),
      place = bt_mixed_example_place(),
      description = bt_mixed_example_description(),
      selected_policy = "native source resolution with coverage fill"
    ))
  }
  list(
    kind = "primary",
    aoi = bt_real_example_aoi(),
    aoi_id = bt_real_example_aoi_id(),
    place = bt_real_example_place(),
    description = bt_real_example_description(),
    selected_policy = "native source resolution with coverage fill"
  )
}

bt_real_example_setup <- function(kind = c("primary", "mixed")) {
  bt_require_real_examples()
  spec <- bt_example_spec(kind)
  cache_dir <- bt_real_example_cache_dir()
  package_cache <- file.path(cache_dir, "package-cache")
  download_dir <- file.path(cache_dir, "downloads", spec$aoi_id)
  old <- options(bluertopo.cache_dir = package_cache)
  bbox <- spec$aoi
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
    kind = spec$kind,
    aoi_id = spec$aoi_id,
    place = spec$place,
    description = spec$description,
    cache_dir = cache_dir,
    package_cache = package_cache,
    download_dir = download_dir,
    selected_policy = spec$selected_policy,
    example_label = bt_real_example_label,
    source_catalog = attr(tiles, "bluertopo_catalog"),
    planned_assets = plan,
    planned_bytes = total_bytes,
    restore = function() options(old)
  )
}

bt_mixed_example_setup <- function() {
  bt_real_example_setup("mixed")
}

bt_real_example_cache_key_info <- function() {
  setup <- bt_real_example_setup()
  mixed_setup <- bt_mixed_example_setup()
  on.exit(mixed_setup$restore(), add = TRUE)
  on.exit(setup$restore(), add = TRUE)
  catalog <- setup$source_catalog
  list(
    behavior_version = catalog$behavior_version %||% "unknown",
    aoi_id = paste(bt_real_example_aoi_id(), bt_mixed_example_aoi_id(), sep = "__"),
    catalog_checksum = substr(catalog$local_checksum %||% "unknown", 1L, 16L)
  )
}

bt_real_example_preflight <- function() {
  setup <- bt_real_example_setup()
  on.exit(setup$restore(), add = TRUE)
  mixed_setup <- bt_mixed_example_setup()
  on.exit(mixed_setup$restore(), add = TRUE)
  message(sprintf("Primary AOI: %s", setup$aoi_id))
  message(sprintf("Primary place: %s", setup$place))
  message(sprintf("Tiles: %s", paste(as.data.frame(setup$tiles)$tile_id, collapse = ", ")))
  message(sprintf("Planned assets: %d", nrow(setup$planned_assets)))
  message(sprintf("Planned bytes: %d", setup$planned_bytes))
  message(sprintf("Mixed-grid AOI: %s", mixed_setup$aoi_id))
  message(sprintf("Mixed-grid place: %s", mixed_setup$place))
  message(sprintf("Mixed-grid tiles: %s", paste(as.data.frame(mixed_setup$tiles)$tile_id, collapse = ", ")))
  message(sprintf("Mixed-grid planned assets: %d", nrow(mixed_setup$planned_assets)))
  message(sprintf("Mixed-grid planned bytes: %d", mixed_setup$planned_bytes))
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

bt_display_names <- c(
  tile_id = "Tile ID",
  resolution_m = "Resolution (m)",
  utm_zone = "UTM zone",
  delivered_date = "Delivery date",
  intersection_area_m2 = "Intersection area (m²)",
  intersection_fraction = "Tile intersected (%)",
  selection_rank = "Selection rank",
  selection_reason = "Selection",
  fallback = "Coverage fallback",
  asset_type = "Asset",
  geotiff_url = "GeoTIFF URL",
  rat_url = "RAT URL",
  source_basename = "Source file",
  local_path = "Local path",
  source = "Source file",
  file = "Manifest file",
  verification_mode = "Verification",
  verified = "Verified",
  downloaded_mb = "Size (MB)",
  actual_sha256 = "SHA-256",
  planned_mb = "Planned size (MB)",
  status = "Status",
  attempts = "Attempts",
  target_met = "Target met",
  coverage_type = "Coverage type",
  published_coverage_fraction = "Published coverage (%)",
  selected_coverage_fraction = "Selected coverage (%)",
  selected_aoi_fraction = "AOI intersected (%)",
  target_coverage = "Target coverage (%)",
  output_object_class = "Output object",
  group_name = "Grid",
  crs = "CRS",
  resolution = "Resolution",
  source_count = "Source count",
  layer_names = "Layers",
  extent = "Extent",
  resampled_flag = "Resampled",
  field = "Field",
  value = "Value",
  exists = "Exists",
  bytes = "Bytes"
)

bt_display_values <- c(
  geotiff = "GeoTIFF",
  rat = "RAT",
  reused_verified = "Reused and verified",
  downloaded = "Downloaded",
  coverage_fallback = "Coverage fallback",
  coverage_fill = "Coverage fill",
  native = "Native"
)

bt_format_display <- function(x, digits = 3) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  x[] <- lapply(x, function(value) {
    if (is.logical(value)) {
      return(ifelse(is.na(value), NA_character_, ifelse(value, "Yes", "No")))
    }
    value <- bt_round(value, digits = digits)
    if (is.character(value)) {
      mapped <- unname(bt_display_values[value])
      value[!is.na(mapped)] <- mapped[!is.na(mapped)]
    }
    value
  })
  matched <- unname(bt_display_names[names(x)])
  names(x) <- ifelse(is.na(matched), names(x), matched)
  x
}

bt_display_table <- function(x, digits = 3, ..., row_names = FALSE) {
  knitr::kable(bt_format_display(x, digits = digits), ..., row.names = row_names)
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
  out <- as.data.frame(coverage[fields], stringsAsFactors = FALSE)
  fraction_fields <- intersect(
    c(
      "published_coverage_fraction",
      "selected_coverage_fraction",
      "selected_aoi_fraction",
      "target_coverage"
    ),
    names(out)
  )
  out[fraction_fields] <- lapply(out[fraction_fields], function(x) 100 * x)
  out
}

bt_tile_table <- function(tiles, include_urls = FALSE) {
  df <- as.data.frame(tiles)
  if (isTRUE(include_urls)) {
    df$geotiff_url <- bt_short_url(df$geotiff_url)
    df$rat_url <- bt_short_url(df$rat_url)
  }
  if ("intersection_fraction" %in% names(df)) {
    df$intersection_fraction <- 100 * df$intersection_fraction
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

bt_plot_tiles <- function(
  tiles,
  aoi,
  main = "BlueTopo tile footprints",
  place_label = NULL,
  label_resolutions = FALSE
) {
  df <- as.data.frame(tiles)
  values <- sort(unique(df$resolution_m))
  palette <- c("#0a9396", "#94d2bd", "#ee9b00", "#ca6702", "#005f73")
  colors <- stats::setNames(palette[seq_along(values)], values)
  tile_cols <- grDevices::adjustcolor(colors[as.character(df$resolution_m)], alpha.f = 0.45)
  terra::plot(tiles, col = tile_cols, border = "#2b2d42", lwd = 1.2, main = main)
  aoi_plot <- terra::project(aoi, terra::crs(tiles))
  terra::plot(aoi_plot, add = TRUE, border = "#d00000", lwd = 2.5)
  if (isTRUE(label_resolutions)) {
    centers <- terra::centroids(tiles)
    xy <- terra::crds(centers)
    graphics::text(
      xy[, 1],
      xy[, 2],
      labels = paste0(df$resolution_m, " m"),
      cex = 0.78,
      col = "#001219"
    )
  }
  if (!is.null(place_label) && nzchar(place_label)) {
    center <- terra::crds(terra::centroids(aoi_plot))[1L, ]
    graphics::text(
      center[1],
      center[2],
      labels = place_label,
      pos = 3,
      cex = 0.92,
      font = 2,
      col = "#d00000"
    )
  }
  legend(
    "topright",
    legend = c(paste(values, "m native source resolution"), "AOI"),
    fill = c(grDevices::adjustcolor(colors[as.character(values)], alpha.f = 0.45), NA),
    border = c(rep("#2b2d42", length(values)), "#d00000"),
    bty = "n",
    cex = 0.8
  )
}

bt_plot_locator_map <- function(
  tiles,
  aoi,
  place_label = bt_real_example_place(),
  main = "BlueTopo locator"
) {
  bt_plot_tiles(
    tiles,
    aoi,
    main = main,
    place_label = place_label,
    label_resolutions = TRUE
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

bt_first_raster <- function(x, layer = 1L) {
  r <- bt_rasters(x)[[1L]]
  if (is.character(layer) && layer %in% names(r)) {
    r <- r[[layer]]
  } else if (is.numeric(layer) && terra::nlyr(r) >= layer) {
    r <- r[[layer]]
  }
  r
}

bt_plot_first_raster <- function(x, main, layer = 1L, categorical = FALSE) {
  r <- bt_first_raster(x, layer = layer)
  if (isTRUE(categorical)) {
    terra::plot(r, main = main, col = hcl.colors(12, "Dark 3"))
  } else {
    terra::plot(r, main = main)
  }
  invisible(r)
}

bt_plot_bathy_map <- function(elev, aoi = NULL, main = "BlueTopo bathymetry") {
  r <- bt_first_raster(elev, layer = 1L)
  rng <- suppressWarnings(as.numeric(terra::global(r, range, na.rm = TRUE)[1L, ]))
  if (length(rng) != 2L || any(!is.finite(rng)) || diff(rng) <= 0) {
    terra::plot(r, main = main, col = grDevices::hcl.colors(80, "Blues 3", rev = TRUE))
    if (!is.null(aoi)) {
      terra::plot(terra::project(aoi, terra::crs(r)), add = TRUE, border = "#d00000", lwd = 2)
    }
    return(invisible(r))
  }

  shade <- tryCatch({
    slope <- terra::terrain(r, v = "slope", unit = "radians")
    aspect <- terra::terrain(r, v = "aspect", unit = "radians")
    terra::shade(slope, aspect, angle = 35, direction = 315)
  }, error = function(e) NULL)

  if (is.null(shade)) {
    terra::plot(r, main = main, col = grDevices::hcl.colors(80, "Blues 3", rev = TRUE))
  } else {
    terra::plot(
      shade,
      col = gray.colors(80, start = 0.15, end = 0.85),
      legend = FALSE,
      main = main
    )
    terra::plot(
      r,
      add = TRUE,
      alpha = 0.68,
      col = grDevices::hcl.colors(80, "Blues 3", rev = TRUE)
    )
  }

  contour_levels <- pretty(rng, n = 10)
  contour_levels <- contour_levels[contour_levels >= rng[1L] & contour_levels <= rng[2L]]
  if (length(contour_levels) >= 2L) {
    contours <- tryCatch(terra::as.contour(r, levels = contour_levels), error = function(e) NULL)
    if (!is.null(contours)) {
      terra::plot(contours, add = TRUE, col = "black", lwd = 0.45)
    }
  }
  if (!is.null(aoi)) {
    terra::plot(terra::project(aoi, terra::crs(r)), add = TRUE, border = "#d00000", lwd = 2)
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
      "Catalog",
      "Catalog last modified",
      "Package version",
      "Navigation status",
      "Vertical-datum conversion",
      "Planned download (MB)"
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
