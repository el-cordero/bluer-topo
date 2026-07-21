#' Discover BlueTopo tiles intersecting an AOI
#'
#' Returns selected NOAA BlueTopo tile footprints and standardized metadata
#' without downloading raster assets.
#'
#' @inheritParams bluertopo
#' @inheritSection bluertopo AOI inputs
#'
#' @return A `terra::SpatVector` with selected tile metadata. Coverage
#'   diagnostics are attached as the `"coverage"` attribute and the normalized
#'   native-resolution policy as `"resolution_spec"`. Important fields include
#'   tile ID, native resolution, UTM zone, delivery date, intersection area and
#'   fraction, source URLs, expected SHA-256 checksums, selection rank/reason,
#'   and whether the tile was added as a coverage fallback.
#' @export
#' @examples
#' aoi <- c(xmin = -74.045, ymin = 40.675, xmax = -73.995, ymax = 40.715)
#'
#' \donttest{
#' \dontshow{
#' host <- "noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com"
#' bluertopo_tiles <- function(...) if (!is.null(curl::nslookup(host, error = FALSE)))
#'   tryCatch(
#'     bluertopo::bluertopo_tiles(...),
#'     bluertopo_error = function(e) NULL
#'   )
#' }
#' tiles <- bluertopo_tiles(aoi)
#' }
bluertopo_tiles <- function(
  aoi,
  resolution = "native",
  coverage = "warn",
  min_coverage = 1,
  cache_dir = bluertopo_cache_dir(),
  refresh = "if_stale",
  quiet = FALSE
) {
  .bt_tiles_impl(
    aoi = aoi,
    resolution = resolution,
    coverage = coverage,
    min_coverage = min_coverage,
    cache_dir = cache_dir,
    refresh = refresh,
    quiet = quiet
  )$tiles
}

.bt_tiles_impl <- function(
  aoi,
  resolution,
  coverage,
  min_coverage,
  cache_dir,
  refresh,
  quiet = FALSE
) {
  aoi_norm <- .bt_normalize_aoi(aoi)
  catalog <- .bt_get_catalog(cache_dir = cache_dir, refresh = refresh, quiet = quiet)
  catalog_vector <- .bt_read_catalog_vector(catalog)
  aoi_catalog <- .bt_project_aoi(aoi_norm, terra::crs(catalog_vector))
  intersections <- tryCatch(terra::intersect(catalog_vector, aoi_catalog), error = function(e) {
    .bt_abort("Could not intersect AOI with the BlueTopo tile scheme.",
      class = "bluertopo_error_aoi",
      parent = e
    )
  })
  if (nrow(intersections) == 0L) {
    .bt_abort(
      "No current BlueTopo tile footprints intersect the AOI.",
      class = "bluertopo_error_no_coverage"
    )
  }
  inter_df <- as.data.frame(intersections)
  valid <- .bt_valid_catalog_rows(inter_df)
  if (!any(valid)) {
    .bt_abort(
      "Intersecting BlueTopo tile footprints do not include complete GeoTIFF link, checksum, and resolution metadata.",
      class = "bluertopo_error_no_coverage"
    )
  }
  intersections <- intersections[valid, ]
  inter_df <- inter_df[valid, , drop = FALSE]
  areas <- .bt_area_m2(intersections)
  area_by_tile <- tapply(areas, inter_df$tile_id, sum, na.rm = TRUE)
  source_df <- as.data.frame(catalog_vector)
  idx <- match(names(area_by_tile), source_df$tile_id)
  idx <- idx[!is.na(idx)]
  candidates <- catalog_vector[idx, ]
  candidate_df <- as.data.frame(candidates)
  candidates$intersection_area_m2 <- as.numeric(area_by_tile[match(candidate_df$tile_id, names(area_by_tile))])
  tile_area <- .bt_area_m2(candidates)
  candidates$intersection_fraction <- ifelse(tile_area > 0, candidates$intersection_area_m2 / tile_area, NA_real_)

  selected <- .bt_apply_resolution_selection(
    candidates = candidates,
    intersections = intersections,
    aoi = aoi_catalog,
    resolution = resolution,
    coverage = coverage,
    min_coverage = min_coverage
  )
  query <- list(
    aoi_crs = aoi_norm$crs,
    aoi_hash = aoi_norm$hash,
    aoi_bbox = aoi_norm$bbox,
    aoi_source_type = aoi_norm$source_type,
    resolution = .bt_resolution_label(attr(selected, "resolution_spec")),
    coverage = coverage,
    min_coverage = min_coverage,
    effective_min_coverage = attr(selected, "coverage")$target_coverage,
    coverage_target_source = attr(selected, "coverage")$target_source %||% "min_coverage",
    request_timestamp = .bt_now_iso()
  )
  stable_query <- query
  stable_query$request_timestamp <- NULL
  query$query_hash <- .bt_hash_object(list(
    query = stable_query,
    catalog_checksum = catalog$metadata$local_checksum %||% NA_character_,
    behavior_version = .bt_behavior_version
  ))
  list(
    tiles = selected,
    intersections = intersections,
    aoi = aoi_norm,
    aoi_catalog = aoi_catalog,
    catalog = catalog,
    query = query,
    coverage = attr(selected, "coverage")
  )
}

.bt_valid_catalog_rows <- function(df) {
  !is.na(df$resolution_m) &
    !is.na(df$tile_id) & nzchar(df$tile_id) &
    !is.na(df$geotiff_url) & nzchar(df$geotiff_url) &
    !is.na(df$geotiff_sha256) & nzchar(df$geotiff_sha256)
}
