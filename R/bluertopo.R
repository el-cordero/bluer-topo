#' Download and extract NOAA BlueTopo bathymetry
#'
#' `bluertopo()` is the main extraction workflow. It discovers BlueTopo tiles
#' for an AOI, downloads verified original source assets by default, and opens
#' selected bands as lazy, file-backed `terra` objects.
#'
#' @param aoi A polygonal area of interest in one of the formats listed in
#'   **AOI inputs** below.
#' @param layers A character vector containing `"elevation"`, `"uncertainty"`,
#'   or `"contributor"`; use `"all"` for all three source bands. Elevation and
#'   uncertainty are continuous values. Contributor identifiers are categorical.
#' @param resolution A native source-tile selection policy. Supply a shortcut
#'   such as `"native"`, `"finest"`, `"coarsest"`, `"best_available"`,
#'   `"coarsest_available"`, or `"dominant"`; a positive numeric meter value
#'   for an exact match; or a [bluertopo_resolution()] object.
#' @param coverage A character scalar controlling incomplete selected coverage:
#'   `"ignore"`, `"warn"`, `"error"`, or `"fill"`. `"fill"` adds fallback
#'   native resolutions in policy order until the target is met when possible.
#' @param min_coverage A numeric value from 0 through 1 giving the target share
#'   of published tile-index coverage. This is geometric catalog coverage, not
#'   a data-quality measure.
#' @param access A character scalar. `"download"` stores and SHA-256 verifies
#'   source files before opening them; `"stream"` uses GDAL `/vsicurl/` access
#'   without local checksum verification.
#' @param cache_dir A non-empty character path for the package cache. The
#'   session-temporary default avoids writing to the user's home directory. Set
#'   an explicit path to reuse catalogs, source files, and VRTs across sessions.
#' @param refresh A character scalar controlling catalog access:
#'   `"if_stale"`, `"never"`, or `"always"`. `"never"` requires an existing
#'   cached catalog and performs no catalog request.
#' @param crop A length-one logical. If `TRUE`, crop each output to the AOI
#'   bounding extent.
#' @param mask A length-one logical. If `TRUE`, mask cells outside the AOI
#'   polygon and also enable cropping.
#' @param combine A character scalar controlling multiple native grids:
#'   `"auto"` returns one raster when compatible and a collection otherwise;
#'   `"collection"` always returns a collection; `"single"` requires compatible
#'   grids or an explicit output grid.
#' @param output_crs `NULL` or a non-empty character projected CRS accepted by
#'   `terra`, such as `"EPSG:26918"` or WKT. Supply it together with
#'   `output_resolution` to request one resampled output grid.
#' @param output_resolution `NULL` or one positive numeric cell size in
#'   `output_crs` units. It must be supplied together with `output_crs`.
#' @param resampling `NULL`, a named character vector, or a named list keyed by
#'   layer. Allowed methods are `"near"`, `"bilinear"`, `"cubic"`,
#'   `"cubicspline"`, `"lanczos"`, `"average"`, and `"mode"`. Defaults are
#'   bilinear for elevation/uncertainty and nearest-neighbor for contributor;
#'   contributor cannot use a non-nearest method.
#' @param verify A character scalar download-verification mode: `"sha256"`
#'   (default), `"size"`, or `"none"`. `"none"` is explicitly unverified.
#' @param workers `NULL` or the number `1`. Higher worker counts are rejected in
#'   this release.
#' @param progress A length-one logical controlling routine download progress.
#' @param quiet A length-one logical suppressing routine informational messages.
#' @param details A length-one logical. If `TRUE`, return data plus tile,
#'   download, query, coverage, and provenance records.
#'
#' @section AOI inputs:
#' `aoi` must resolve to polygon or multipolygon geometry with a known
#' coordinate reference system (CRS). Accepted inputs are:
#'
#' - a `terra::SpatVector`;
#' - an `sf::sf` data frame or `sf::sfc` geometry vector;
#' - a `terra::SpatRaster`, whose extent and CRS define the AOI;
#' - a `terra::SpatExtent`, interpreted as longitude/latitude in EPSG:4326;
#' - a numeric `c(xmin, ymin, xmax, ymax)` bounding box in EPSG:4326;
#' - a local vector-file path readable by [terra::vect()]; or
#' - a WKT or GeoJSON character string, interpreted as EPSG:4326.
#'
#' Remote AOI URLs are refused. Numeric bounding boxes must be ordered and fall
#' within valid longitude/latitude bounds. Point and line geometries are not
#' accepted as areas of interest.
#'
#' @section Output behavior:
#' Native source grids are preserved unless both `output_crs` and
#' `output_resolution` are supplied. With `details = FALSE`, the function
#' returns a `terra::SpatRaster` for one compatible grid or a
#' `terra::SpatRasterCollection` for multiple incompatible native grids. With
#' `details = TRUE`, it returns a `bluertopo_result` list containing:
#'
#' - `data`: the raster or raster collection;
#' - `tiles`: selected tile footprints and catalog metadata;
#' - `downloads`: one record per source asset;
#' - `query`: normalized request settings and query hash;
#' - `coverage`: geometric coverage diagnostics; and
#' - `provenance`: catalog, checksum, source, and vertical-reference records.
#'
#' @return A `terra::SpatRaster`, `terra::SpatRasterCollection`, or a
#'   `bluertopo_result` list as described in **Output behavior**.
#' @export
#' @examples
#' bbox <- c(-66.2, 18.2, -66.1, 18.3)
#'
#' # sf and sfc polygon objects with a known CRS can be passed directly.
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   aoi <- sf::st_sf(
#'     name = "example",
#'     geometry = sf::st_as_sfc(
#'       "POLYGON ((-66.2 18.2, -66.1 18.2, -66.1 18.3, -66.2 18.3, -66.2 18.2))",
#'       crs = 4326
#'     )
#'   )
#' } else {
#'   aoi <- bbox
#' }
#'
#' \donttest{
#' bathy <- tryCatch(
#'   bluertopo(aoi),
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
