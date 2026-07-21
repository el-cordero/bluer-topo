#' Download and extract NOAA BlueTopo bathymetry
#'
#' `bluertopo()` is the main extraction workflow. It discovers BlueTopo tiles
#' for an AOI, downloads verified original source assets by default, and opens
#' selected bands as lazy, file-backed `terra` objects.
#'
#' @param aoi Area of interest.
#' @param layers `"elevation"`, `"uncertainty"`, `"contributor"`, `"all"`, or a
#' character vector of canonical layer names.
#' @param resolution Native source-resolution policy.
#' @param coverage Coverage policy.
#' @param min_coverage Target share of published tile coverage.
#' @param access `"download"` or opt-in `"stream"`.
#' @param cache_dir Package cache directory.
#' @param refresh Catalog refresh policy.
#' @param crop Crop each result to the AOI extent.
#' @param mask Mask each result to the AOI polygon. Implies `crop = TRUE`.
#' @param combine `"auto"`, `"collection"`, or `"single"`.
#' @param output_crs Optional explicit output CRS.
#' @param output_resolution Optional explicit output-grid resolution in target
#' CRS units.
#' @param resampling Optional named resampling methods by layer.
#' @param verify Download verification mode.
#' @param workers Worker count. Only `NULL`/`1` is currently supported; higher
#' values are rejected until bounded parallel downloads are implemented.
#' @param progress Show routine progress messages.
#' @param quiet Suppress routine messages.
#' @param details Return a `bluertopo_result` instead of only the terra object.
#'
#' @return A `terra::SpatRaster`, `terra::SpatRasterCollection`, or
#' `bluertopo_result` when `details = TRUE`.
#' @export
#' @examples
#' \donttest{
#' bathy <- tryCatch(
#'   bluertopo(c(-66.2, 18.2, -66.1, 18.3)),
#'   bluertopo_error = function(e) {
#'     message("Network-backed example skipped: ", conditionMessage(e))
#'     NULL
#'   }
#' )
#' }
bluertopo <- function(
  aoi,
  layers = "elevation",
  resolution = "native",
  coverage = "warn",
  min_coverage = 1,
  access = "download",
  cache_dir = bluertopo_cache_dir(),
  refresh = "if_stale",
  crop = TRUE,
  mask = FALSE,
  combine = "auto",
  output_crs = NULL,
  output_resolution = NULL,
  resampling = NULL,
  verify = "sha256",
  workers = NULL,
  progress = interactive(),
  quiet = FALSE,
  details = FALSE
) {
  layers <- .bt_normalize_layers(layers)
  access <- .bt_match_arg(access, c("download", "stream"), "access")
  details <- .bt_validate_bool(details, "details")
  cache_dir <- .bt_init_cache(cache_dir)
  if (identical(access, "stream")) {
    .bt_warn(
      "Streaming BlueTopo assets is opt-in and depends on GDAL virtual file access and network performance.",
      class = "bluertopo_warning_unverified"
    )
    tiles_result <- .bt_tiles_impl(aoi, resolution, coverage, min_coverage, cache_dir, refresh, quiet)
    geotiffs <- .bt_stream_geotiffs(tiles_result$tiles)
    downloads <- .bt_as_downloads(geotiffs)
  } else {
    paths <- .bt_cache_paths(cache_dir)
    download_result <- .bt_download_impl(
      aoi = aoi,
      path = paths$tiles,
      resolution = resolution,
      coverage = coverage,
      min_coverage = min_coverage,
      rat = TRUE,
      cache_dir = cache_dir,
      refresh = refresh,
      verify = verify,
      workers = workers,
      on_exists = "verify",
      on_error = "stop",
      retries = 3,
      timeout = NULL,
      dry_run = FALSE,
      progress = progress,
      quiet = quiet
    )
    tiles_result <- download_result$tiles_result
    downloads <- download_result$downloads
    geotiffs <- .bt_geotiffs_from_downloads(downloads, tiles_result$tiles)
  }

  data <- .bt_assemble_terra(
    geotiffs = geotiffs,
    tiles = tiles_result$tiles,
    aoi = tiles_result$aoi,
    layers = layers,
    access = access,
    cache_dir = cache_dir,
    crop = crop,
    mask = mask,
    combine = combine,
    output_crs = output_crs,
    output_resolution = output_resolution,
    resampling = resampling,
    quiet = quiet
  )
  query <- .bt_enrich_query(
    query = tiles_result$query,
    layers = layers,
    access = access,
    crop = crop,
    mask = mask,
    combine = combine,
    output_crs = output_crs,
    output_resolution = output_resolution,
    resampling = resampling
  )
  provenance <- .bt_result_provenance(tiles_result, downloads, geotiffs)
  provenance$query_hash <- query$query_hash
  if (!details) {
    return(data)
  }
  structure(
    list(
      data = data,
      tiles = tiles_result$tiles,
      downloads = downloads,
      query = query,
      provenance = provenance,
      coverage = tiles_result$coverage
    ),
    class = "bluertopo_result"
  )
}

.bt_enrich_query <- function(
  query,
  layers,
  access,
  crop,
  mask,
  combine,
  output_crs,
  output_resolution,
  resampling
) {
  query$package_version <- .bt_package_version()
  query$requested_layers <- layers
  query$access <- access
  query$crop <- crop
  query$mask <- mask
  query$combine <- combine
  query$output_grid <- list(
    output_crs = output_crs %||% NA_character_,
    output_resolution = output_resolution %||% NA_real_,
    resampling = resampling %||% list()
  )
  stable <- query
  stable$request_timestamp <- NULL
  query$query_hash <- .bt_hash_object(list(
    query = stable,
    behavior_version = .bt_behavior_version
  ))
  query
}

.bt_geotiffs_from_downloads <- function(downloads, tiles) {
  geotiffs <- downloads[downloads$asset_type == "geotiff" & downloads$status != "failed", , drop = FALSE]
  tile_df <- as.data.frame(tiles)
  geotiff_key <- paste(geotiffs$tile_id, geotiffs$source_url, sep = "\r")
  tile_key <- paste(tile_df$tile_id, tile_df$geotiff_url, sep = "\r")
  geotiffs$overlap_priority <- tile_df$overlap_priority[match(geotiff_key, tile_key)]
  geotiffs <- geotiffs[order(geotiffs$overlap_priority, geotiffs$tile_id), , drop = FALSE]
  geotiffs
}

.bt_stream_geotiffs <- function(tiles) {
  df <- as.data.frame(tiles)
  data.frame(
    tile_id = df$tile_id,
    asset_type = "geotiff",
    source_url = df$geotiff_url,
    source_basename = basename(df$geotiff_url),
    expected_sha256 = df$geotiff_sha256,
    local_path = NA_character_,
    status = "stream",
    verification_mode = "none",
    verified = FALSE,
    expected_bytes = NA_real_,
    downloaded_bytes = NA_real_,
    actual_sha256 = NA_character_,
    attempts = 0L,
    started_at = NA_character_,
    completed_at = NA_character_,
    error_class = NA_character_,
    error_message = NA_character_,
    overlap_priority = df$overlap_priority,
    stringsAsFactors = FALSE
  )
}

.bt_result_provenance <- function(tiles_result, downloads, geotiffs) {
  catalog <- .bt_download_manifest_provenance(tiles_result$catalog)
  paths <- geotiffs$local_path
  paths[is.na(paths)] <- geotiffs$source_url[is.na(paths)]
  c(catalog, list(
    layer_definitions = list(
      elevation = "BlueTopo source band 1: elevation.",
      uncertainty = "BlueTopo source band 2: vertical uncertainty.",
      contributor = "BlueTopo source band 3: contributor/source identifier."
    ),
    vertical_reference_text = .bt_extract_vertical_reference(paths),
    no_vertical_datum_conversion_performed = TRUE,
    downloads_verified = all(downloads$verified[downloads$asset_type == "geotiff"] %in% TRUE),
    behavior_version = .bt_behavior_version
  ))
}
