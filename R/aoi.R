.bt_normalize_aoi <- function(aoi) {
  source_type <- class(aoi)[1L] %||% typeof(aoi)
  v <- NULL
  if (inherits(aoi, "SpatVector")) {
    v <- aoi
  } else if (inherits(aoi, "SpatRaster")) {
    crs <- terra::crs(aoi)
    if (!nzchar(crs)) {
      .bt_abort("`aoi` raster must have a known CRS.", class = "bluertopo_error_aoi")
    }
    v <- terra::as.polygons(terra::ext(aoi), crs = crs)
  } else if (inherits(aoi, "SpatExtent")) {
    v <- terra::as.polygons(aoi, crs = "EPSG:4326")
    source_type <- "SpatExtent_EPSG4326"
  } else if (is.numeric(aoi) && length(aoi) == 4L) {
    .bt_validate_bbox(aoi)
    v <- terra::as.polygons(terra::ext(aoi[1L], aoi[3L], aoi[2L], aoi[4L]), crs = "EPSG:4326")
    source_type <- "bbox_EPSG4326"
  } else if (.bt_is_scalar_character(aoi)) {
    v <- .bt_aoi_from_character(aoi)
    source_type <- if (file.exists(aoi)) "vector_path" else "character_geometry_EPSG4326"
  } else if (inherits(aoi, c("sf", "sfc"))) {
    if (!requireNamespace("sf", quietly = TRUE)) {
      .bt_abort("AOI objects from sf require the sf package to be installed.",
        class = "bluertopo_error_aoi"
      )
    }
    v <- terra::vect(aoi)
    source_type <- "sf"
  } else {
    .bt_abort(
      "`aoi` must be a terra object, bbox, WKT/GeoJSON string, vector path, or sf object.",
      class = "bluertopo_error_aoi"
    )
  }

  if (is.null(v) || !inherits(v, "SpatVector") || nrow(v) < 1L) {
    .bt_abort("`aoi` did not produce any vector features.", class = "bluertopo_error_aoi")
  }
  if (!nzchar(terra::crs(v))) {
    .bt_abort("`aoi` must have a known CRS.", class = "bluertopo_error_aoi")
  }
  if (!identical(terra::geomtype(v), "polygons")) {
    .bt_abort(
      "`aoi` must contain polygon or multipolygon geometry; points and lines are not areas of interest.",
      class = "bluertopo_error_aoi"
    )
  }
  v <- .bt_make_valid(v)
  .bt_guard_antimeridian(v)
  wgs84 <- terra::project(v, "EPSG:4326")
  list(
    vector = v,
    wgs84 = wgs84,
    crs = terra::crs(v),
    bbox = as.vector(terra::ext(wgs84)),
    hash = .bt_hash_aoi(wgs84),
    source_type = source_type
  )
}

.bt_validate_bbox <- function(x) {
  if (any(!is.finite(x))) {
    .bt_abort("Numeric AOI bbox values must be finite.", class = "bluertopo_error_aoi")
  }
  if (x[1L] >= x[3L] || x[2L] >= x[4L]) {
    .bt_abort("Numeric AOI bbox must be ordered as xmin, ymin, xmax, ymax.",
      class = "bluertopo_error_aoi"
    )
  }
  if (x[1L] < -180 || x[3L] > 180 || x[2L] < -90 || x[4L] > 90) {
    .bt_abort("Numeric AOI bbox is interpreted as EPSG:4326 and must be within valid lon/lat bounds.",
      class = "bluertopo_error_aoi"
    )
  }
  invisible(TRUE)
}

.bt_aoi_from_character <- function(x) {
  if (.bt_is_url(x)) {
    .bt_abort(
      "Character AOI inputs that look like URLs are refused; provide a local vector path instead.",
      class = "bluertopo_error_aoi"
    )
  }
  if (file.exists(x)) {
    v <- tryCatch(terra::vect(x), error = function(e) {
      .bt_abort(sprintf("Could not read AOI vector path `%s`.", x),
        class = "bluertopo_error_aoi",
        parent = e
      )
    })
    return(v)
  }
  trimmed <- trimws(x)
  if (grepl("^\\s*[\\[{]", trimmed)) {
    tmp <- tempfile(fileext = ".geojson")
    on.exit(unlink(tmp, force = TRUE), add = TRUE)
    writeLines(x, tmp, useBytes = TRUE)
    v <- tryCatch(terra::vect(tmp), error = function(e) {
      .bt_abort("Could not parse AOI GeoJSON string.",
        class = "bluertopo_error_aoi",
        parent = e
      )
    })
    terra::crs(v) <- "EPSG:4326"
    return(v)
  }
  v <- tryCatch(terra::vect(trimmed, crs = "EPSG:4326"), error = function(e) {
    .bt_abort(
      "Character AOI must be a local vector path, WKT geometry, or GeoJSON geometry/feature string.",
      class = "bluertopo_error_aoi",
      parent = e
    )
  })
  v
}

.bt_make_valid <- function(v) {
  if (exists("makeValid", envir = asNamespace("terra"), inherits = FALSE)) {
    fn <- get("makeValid", envir = asNamespace("terra"), inherits = FALSE)
    out <- tryCatch(fn(v), error = function(e) v)
    return(out)
  }
  v
}

.bt_guard_antimeridian <- function(v) {
  wgs <- tryCatch(terra::project(v, "EPSG:4326"), error = function(e) NULL)
  if (is.null(wgs)) {
    return(invisible(FALSE))
  }
  e <- terra::ext(wgs)
  width <- e[2L] - e[1L]
  if (is.finite(width) && width > 180) {
    .bt_abort(
      "AOI appears to span or cross the antimeridian; split it into explicit parts before querying BlueTopo.",
      class = "bluertopo_error_aoi"
    )
  }
  invisible(FALSE)
}

.bt_hash_aoi <- function(v) {
  wkt <- tryCatch(as.data.frame(v, geom = "WKT")$geometry, error = function(e) NULL)
  if (is.null(wkt)) {
    wkt <- paste(as.vector(terra::ext(v)), collapse = ",")
  }
  .bt_hash_object(list(crs = terra::crs(v), geometry = sort(wkt)))
}

.bt_project_aoi <- function(aoi_normalized, crs) {
  if (identical(terra::crs(aoi_normalized$vector), crs)) {
    aoi_normalized$vector
  } else {
    terra::project(aoi_normalized$vector, crs)
  }
}
