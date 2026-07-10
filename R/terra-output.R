.bt_normalize_layers <- function(layers) {
  if (!is.character(layers) || !length(layers)) {
    .bt_abort("`layers` must be a character vector.", class = "bluertopo_error_argument")
  }
  layers <- unique(tolower(layers))
  if (identical(layers, "all")) {
    return(.bt_layer_names)
  }
  invalid <- setdiff(layers, .bt_layer_names)
  if (length(invalid)) {
    .bt_abort(
      sprintf("Unsupported BlueTopo layer(s): %s.", paste(invalid, collapse = ", ")),
      class = "bluertopo_error_argument"
    )
  }
  layers
}

.bt_assemble_terra <- function(
  geotiffs,
  tiles,
  aoi,
  layers,
  access,
  cache_dir,
  crop,
  mask,
  combine,
  output_crs,
  output_resolution,
  resampling,
  quiet = FALSE
) {
  crop <- .bt_validate_bool(crop, "crop")
  mask <- .bt_validate_bool(mask, "mask")
  if (mask) {
    crop <- TRUE
  }
  combine <- .bt_match_arg(combine, c("auto", "collection", "single"), "combine")
  access <- .bt_match_arg(access, c("download", "stream"), "access")
  if (nrow(geotiffs) == 0L) {
    .bt_abort("No GeoTIFF assets are available for terra assembly.",
      class = "bluertopo_error_no_coverage"
    )
  }
  paths <- if (identical(access, "stream")) {
    paste0("/vsicurl/", geotiffs$source_url)
  } else {
    geotiffs$local_path
  }
  rasters <- lapply(paths, .bt_open_source_raster)
  signatures <- vapply(rasters, .bt_grid_signature, character(1L))
  groups <- split(seq_along(paths), signatures)
  group_priority <- vapply(groups, function(idx) min(geotiffs$overlap_priority[idx], na.rm = TRUE), numeric(1L))
  groups <- groups[order(group_priority, names(groups))]
  assembled <- lapply(groups, function(idx) {
    .bt_build_group_raster(paths[idx], rasters[idx], layers, geotiffs[idx, , drop = FALSE], cache_dir)
  })
  assembled <- lapply(assembled, function(r) .bt_crop_mask_raster(r, aoi, crop, mask))

  resampled <- FALSE
  if (!is.null(output_crs) || !is.null(output_resolution)) {
    if (is.null(output_crs) || is.null(output_resolution)) {
      .bt_abort("`output_crs` and `output_resolution` must be supplied together.",
        class = "bluertopo_error_mixed_grid"
      )
    }
    output_resolution <- .bt_validate_number(output_resolution, "output_resolution")
    assembled <- .bt_project_to_output_grid(assembled, aoi, output_crs, output_resolution, layers, resampling)
    resampled <- TRUE
    .bt_warn(c(
      "BlueTopo source rasters were explicitly reprojected/resampled onto the requested output grid.",
      "i" = "Uncertainty values are no longer original source cells after resampling."
    ), class = "bluertopo_warning_resampled")
  }

  output <- .bt_combine_output(assembled, combine, output_requested = resampled)
  attr(output, "bluertopo_resampled") <- resampled
  output
}

.bt_open_source_raster <- function(path) {
  r <- tryCatch(terra::rast(path), error = function(e) {
    .bt_abort(sprintf("Could not open BlueTopo GeoTIFF `%s` with terra.", path),
      class = "bluertopo_error_raster",
      parent = e
    )
  })
  if (terra::nlyr(r) < 3L) {
    .bt_abort(sprintf("BlueTopo GeoTIFF `%s` has fewer than three expected bands.", path),
      class = "bluertopo_error_raster"
    )
  }
  r
}

.bt_grid_signature <- function(r) {
  paste(
    "crs", digest::digest(terra::crs(r), algo = "xxhash64"),
    "res", paste(format(terra::res(r), digits = 15), collapse = ","),
    "origin", paste(format(terra::origin(r), digits = 15), collapse = ","),
    "nlyr", terra::nlyr(r),
    sep = "|"
  )
}

.bt_build_group_raster <- function(paths, rasters, layers, geotiffs, cache_dir) {
  layer_index <- unname(.bt_layer_numbers[layers])
  if (length(paths) == 1L) {
    r <- rasters[[1L]]
  } else {
    vrt_dir <- .bt_cache_paths(cache_dir)$vrt
    .bt_ensure_dir(vrt_dir)
    vrt_hash <- .bt_hash_object(list(paths = paths, layers = layers, behavior = .bt_behavior_version))
    vrt_file <- file.path(vrt_dir, paste0(vrt_hash, ".vrt"))
    if (!file.exists(vrt_file)) {
      r_vrt <- tryCatch(terra::vrt(paths, filename = vrt_file, overwrite = TRUE), error = function(e) {
        .bt_abort("Could not create a VRT for compatible BlueTopo source files.",
          class = "bluertopo_error_raster",
          parent = e
        )
      })
      invisible(r_vrt)
    }
    r <- terra::rast(vrt_file)
  }
  r <- r[[layer_index]]
  names(r) <- layers
  r
}

.bt_crop_mask_raster <- function(r, aoi, crop, mask) {
  if (!crop && !mask) {
    return(r)
  }
  aoi_raster <- terra::project(aoi$vector, terra::crs(r))
  if (crop) {
    r <- terra::crop(r, aoi_raster)
  }
  if (mask) {
    r <- terra::mask(r, aoi_raster)
  }
  r
}

.bt_project_to_output_grid <- function(rasters, aoi, output_crs, output_resolution, layers, resampling) {
  aoi_target <- tryCatch(terra::project(aoi$vector, output_crs), error = function(e) {
    .bt_abort("Could not project AOI to `output_crs`.",
      class = "bluertopo_error_mixed_grid",
      parent = e
    )
  })
  template <- terra::rast(ext = terra::ext(aoi_target), resolution = output_resolution, crs = output_crs)
  if (terra::is.lonlat(template)) {
    .bt_abort(
      "`output_resolution` for a geographic output CRS is ambiguous in the initial release; use a projected CRS.",
      class = "bluertopo_error_mixed_grid"
    )
  }
  methods <- .bt_resampling_methods(layers, resampling)
  projected <- lapply(rasters, function(r) .bt_project_raster_layers(r, template, methods))
  combined <- projected[[1L]]
  if (length(projected) > 1L) {
    for (i in seq_along(projected)[-1L]) {
      combined <- terra::cover(combined, projected[[i]])
    }
  }
  list(combined)
}

.bt_resampling_methods <- function(layers, resampling) {
  defaults <- c(elevation = "bilinear", uncertainty = "bilinear", contributor = "near")
  if (is.null(resampling)) {
    return(defaults[layers])
  }
  if (!is.list(resampling) && !is.character(resampling)) {
    .bt_abort("`resampling` must be a named character vector or list.",
      class = "bluertopo_error_argument"
    )
  }
  resampling <- unlist(resampling)
  if (is.null(names(resampling)) || any(!nzchar(names(resampling)))) {
    .bt_abort("`resampling` must be named by layer.", class = "bluertopo_error_argument")
  }
  unsupported <- setdiff(names(resampling), .bt_layer_names)
  if (length(unsupported)) {
    .bt_abort(sprintf("Unsupported resampling layer name(s): %s.", paste(unsupported, collapse = ", ")),
      class = "bluertopo_error_argument"
    )
  }
  allowed <- c("near", "bilinear", "cubic", "cubicspline", "lanczos", "average", "mode")
  bad <- setdiff(resampling, allowed)
  if (length(bad)) {
    .bt_abort(sprintf("Unsupported resampling method(s): %s.", paste(bad, collapse = ", ")),
      class = "bluertopo_error_argument"
    )
  }
  if (!is.na(resampling["contributor"]) && !identical(resampling["contributor"], "near")) {
    .bt_abort("The contributor band must use nearest-neighbor resampling.",
      class = "bluertopo_error_argument"
    )
  }
  out <- defaults
  out[names(resampling)] <- resampling
  out[layers]
}

.bt_project_raster_layers <- function(r, template, methods) {
  projected <- vector("list", terra::nlyr(r))
  for (i in seq_len(terra::nlyr(r))) {
    method <- methods[[names(r)[i]]]
    projected[[i]] <- terra::project(r[[i]], template, method = method)
  }
  out <- do.call(c, projected)
  names(out) <- names(r)
  out
}

.bt_combine_output <- function(rasters, combine, output_requested) {
  if (identical(combine, "single")) {
    if (length(rasters) > 1L && !isTRUE(output_requested)) {
      .bt_abort(c(
        "Selected BlueTopo tiles have mixed native grids.",
        "i" = paste(
          "Supply `output_crs` and `output_resolution` for",
          "`combine = \"single\"`."
        )
      ),
      class = "bluertopo_error_mixed_grid"
      )
    }
    return(rasters[[1L]])
  }
  if (length(rasters) == 1L && !identical(combine, "collection")) {
    return(rasters[[1L]])
  }
  names(rasters) <- .bt_collection_names(rasters)
  terra::sprc(rasters)
}

.bt_collection_names <- function(rasters) {
  raw <- vapply(seq_along(rasters), function(i) {
    r <- rasters[[i]]
    epsg <- tryCatch(terra::crs(r, describe = TRUE)$code, error = function(e) NA)
    res <- paste(format(terra::res(r), trim = TRUE), collapse = "x")
    sprintf("grid_%02d_epsg%s_%s", i, epsg %||% "unknown", res)
  }, character(1L))
  make.unique(gsub("[^A-Za-z0-9_]+", "_", raw))
}

.bt_extract_vertical_reference <- function(paths) {
  first <- paths[!is.na(paths) & nzchar(paths)][1L]
  if (is.na(first)) {
    return("Vertical-reference metadata was not available from the selected source path.")
  }
  desc <- tryCatch(utils::capture.output(terra::describe(first)), error = function(e) character())
  hits <- grep("vertical|datum|compound|vert", desc, value = TRUE, ignore.case = TRUE)
  if (!length(hits)) {
    return("No vertical-reference text was detected by terra/GDAL metadata inspection.")
  }
  paste(unique(hits), collapse = "\n")
}
