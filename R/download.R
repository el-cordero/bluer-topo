#' Download original NOAA BlueTopo assets for an AOI
#'
#' Discovers selected BlueTopo tiles, downloads original GeoTIFF files and
#' optional RAT sidecars, verifies them, and writes download manifests.
#'
#' @inheritParams bluertopo
#' @inheritSection bluertopo AOI inputs
#' @param path A non-empty character path to the destination directory for the
#'   original source assets and generated CSV/JSON manifests. The argument is
#'   required; there is no default write location.
#' @param rat A length-one logical. If `TRUE`, download Raster Attribute Table
#'   (RAT) XML sidecars when the catalog provides them.
#' @param on_exists A character scalar: `"verify"` reuses only files that pass
#'   verification, `"skip"` leaves existing files untouched, and `"replace"`
#'   downloads them again.
#' @param on_error A character scalar: `"stop"` aborts after an asset failure;
#'   `"continue"` records the failure and processes the remaining assets.
#' @param retries A positive whole number giving the maximum attempts per
#'   asset.
#' @param timeout `NULL` or a positive numeric timeout in seconds for each HTTP
#'   request.
#' @param dry_run A length-one logical. If `TRUE`, return the planned assets
#'   without downloading source files.
#'
#' @return A `bluertopo_downloads` data frame with one row per planned asset.
#'   Important columns include `tile_id`, `asset_type`, `source_url`,
#'   `local_path`, `status`, `verification_mode`, `verified`, byte counts,
#'   checksums, attempts, and any recorded error. CSV and JSON copies are
#'   written below `path` unless `dry_run = TRUE`.
#' @export
#' @examples
#' aoi <- c(xmin = -74.045, ymin = 40.675, xmax = -73.995, ymax = 40.715)
#'
#' \donttest{
#' \dontshow{
#' host <- "noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com"
#' bluertopo_download <- function(...) if (!is.null(curl::nslookup(host, error = FALSE)))
#'   tryCatch(
#'     bluertopo::bluertopo_download(...),
#'     bluertopo_error = function(e) NULL
#'   )
#' }
#' files <- bluertopo_download(
#'   aoi,
#'   path = file.path(tempdir(), "bluertopo-downloads")
#' )
#' }
bluertopo_download <- function(
  aoi,
  path,
  resolution = "native",
  coverage = "warn",
  min_coverage = 1,
  rat = TRUE,
  refresh = "if_stale",
  verify = "sha256",
  workers = NULL,
  on_exists = "verify",
  on_error = "stop",
  retries = 3,
  timeout = NULL,
  dry_run = FALSE,
  progress = interactive(),
  quiet = FALSE,
  cache_dir = bluertopo_cache_dir()
) {
  if (missing(path) || !.bt_is_scalar_character(path) || !nzchar(path)) {
    .bt_abort("`path` is required for `bluertopo_download()`.", class = "bluertopo_error_argument")
  }
  .bt_download_impl(
    aoi = aoi,
    path = path,
    resolution = resolution,
    coverage = coverage,
    min_coverage = min_coverage,
    rat = rat,
    cache_dir = cache_dir,
    refresh = refresh,
    verify = verify,
    workers = workers,
    on_exists = on_exists,
    on_error = on_error,
    retries = retries,
    timeout = timeout,
    dry_run = dry_run,
    progress = progress,
    quiet = quiet
  )$downloads
}

.bt_download_impl <- function(
  aoi,
  path,
  resolution,
  coverage,
  min_coverage,
  rat = TRUE,
  cache_dir = bluertopo_cache_dir(),
  refresh = "if_stale",
  verify = "sha256",
  workers = NULL,
  on_exists = "verify",
  on_error = "stop",
  retries = 3,
  timeout = NULL,
  dry_run = FALSE,
  progress = interactive(),
  quiet = FALSE
) {
  rat <- .bt_validate_bool(rat, "rat")
  dry_run <- .bt_validate_bool(dry_run, "dry_run")
  progress <- .bt_validate_bool(progress, "progress")
  quiet <- .bt_validate_bool(quiet, "quiet")
  verify <- .bt_match_arg(verify, c("sha256", "size", "none"), "verify")
  on_exists <- .bt_match_arg(on_exists, c("verify", "skip", "replace"), "on_exists")
  on_error <- .bt_match_arg(on_error, c("stop", "continue"), "on_error")
  workers <- .bt_validate_workers(workers)
  retries <- .bt_validate_count(retries, "retries")
  if (!is.null(timeout)) {
    timeout <- .bt_validate_number(timeout, "timeout")
  }
  if (identical(verify, "none")) {
    .bt_warn(
      "Download verification was explicitly disabled with `verify = \"none\"`.",
      class = "bluertopo_warning_unverified"
    )
  }
  tiles_result <- .bt_tiles_impl(
    aoi = aoi,
    resolution = resolution,
    coverage = coverage,
    min_coverage = min_coverage,
    cache_dir = cache_dir,
    refresh = refresh,
    quiet = quiet
  )
  tiles <- tiles_result$tiles
  .bt_inform(sprintf("BlueTopo tiles selected: %d.", nrow(tiles)), quiet = quiet || !progress)
  plan <- .bt_download_plan(tiles, path = path, rat = rat, verify = verify)
  if (identical(verify, "size") && any(is.na(plan$expected_bytes))) {
    .bt_abort(
      c(
        "`verify = \"size\"` requires expected byte counts in the catalog.",
        "i" = "Use `verify = \"sha256\"` or `verify = \"none\"`."
      ),
      class = "bluertopo_error_download"
    )
  }
  .bt_inform(sprintf("BlueTopo assets planned: %d.", nrow(plan)), quiet = quiet || !progress)
  if (dry_run) {
    plan$status <- "planned"
    plan$verified <- FALSE
    plan$dry_run <- TRUE
    downloads <- .bt_as_downloads(plan)
    return(list(downloads = downloads, tiles_result = tiles_result))
  }
  path <- .bt_ensure_dir(path)
  results <- vector("list", nrow(plan))
  for (i in seq_len(nrow(plan))) {
    row <- plan[i, , drop = FALSE]
    results[[i]] <- tryCatch(
      .bt_download_one(row, verify, on_exists, retries, timeout, workers),
      error = function(e) {
        failed <- row
        failed$status <- "failed"
        failed$verified <- FALSE
        failed$actual_sha256 <- NA_character_
        failed$downloaded_bytes <- NA_real_
        failed$attempts <- retries
        failed$started_at <- NA_character_
        failed$completed_at <- .bt_now_iso()
        failed$error_class <- class(e)[1L]
        failed$error_message <- .bt_error_message(e)
        if (identical(on_error, "stop")) {
          .bt_abort(c(
            sprintf("BlueTopo download failed for tile `%s` (%s).", row$tile_id, row$asset_type),
            "i" = .bt_error_message(e)
          ), class = "bluertopo_error_download", parent = e)
        }
        failed
      }
    )
  }
  manifest <- do.call(rbind, results)
  manifest$dry_run <- FALSE
  downloads <- .bt_as_downloads(manifest)
  .bt_write_download_manifests(
    downloads,
    path = path,
    query = tiles_result$query,
    coverage = tiles_result$coverage,
    provenance = .bt_download_manifest_provenance(tiles_result$catalog)
  )
  .bt_inform(
    sprintf(
      "BlueTopo downloads complete: %d succeeded, %d failed.",
      sum(downloads$status %in% c("downloaded", "reused_verified", "skipped_existing")),
      sum(downloads$status == "failed")
    ),
    quiet = quiet || !progress
  )
  list(downloads = downloads, tiles_result = tiles_result)
}

.bt_validate_workers <- function(workers) {
  if (is.null(workers)) {
    return(1L)
  }
  workers <- .bt_validate_count(workers, "workers")
  if (!identical(workers, 1L)) {
    .bt_abort(
      "Parallel BlueTopo downloads are not implemented yet; use `workers = 1` or leave `workers = NULL`.",
      class = "bluertopo_error_download"
    )
  }
  workers
}

.bt_download_plan <- function(tiles, path, rat, verify) {
  df <- as.data.frame(tiles)
  rows <- list()
  for (i in seq_len(nrow(df))) {
    rows[[length(rows) + 1L]] <- .bt_asset_plan_row(df[i, , drop = FALSE], path, "geotiff", verify)
    if (isTRUE(rat) && !is.na(df$rat_url[i]) && nzchar(df$rat_url[i])) {
      rows[[length(rows) + 1L]] <- .bt_asset_plan_row(df[i, , drop = FALSE], path, "rat", verify)
    }
  }
  plan <- do.call(rbind, rows)
  plan <- .bt_resolve_destination_collisions(plan)
  row.names(plan) <- NULL
  plan
}

.bt_asset_plan_row <- function(tile, path, asset_type, verify) {
  if (identical(asset_type, "geotiff")) {
    url <- tile$geotiff_url
    expected_sha256 <- tile$geotiff_sha256
  } else {
    url <- tile$rat_url
    expected_sha256 <- tile$rat_sha256
  }
  .bt_validate_source_url(url, role = asset_type)
  basename <- .bt_safe_basename_from_url(url)
  local_dir <- file.path(path, tile$tile_id)
  data.frame(
    tile_id = tile$tile_id,
    asset_type = asset_type,
    source_url = url,
    source_basename = basename,
    expected_sha256 = expected_sha256 %||% NA_character_,
    local_path = file.path(local_dir, basename),
    status = "planned",
    verification_mode = verify,
    verified = FALSE,
    expected_bytes = NA_real_,
    downloaded_bytes = NA_real_,
    actual_sha256 = NA_character_,
    attempts = 0L,
    started_at = NA_character_,
    completed_at = NA_character_,
    error_class = NA_character_,
    error_message = NA_character_,
    stringsAsFactors = FALSE
  )
}

.bt_resolve_destination_collisions <- function(plan) {
  duplicated_paths <- unique(plan$local_path[duplicated(plan$local_path)])
  for (path in duplicated_paths) {
    idx <- which(plan$local_path == path)
    identity <- paste(plan$source_url[idx], plan$expected_sha256[idx])
    if (length(unique(identity)) == 1L) {
      next
    }
    for (i in idx) {
      ext <- tools::file_ext(plan$local_path[i])
      stem <- sub(sprintf("\\.%s$", ext), "", plan$local_path[i])
      suffix <- substr(.bt_hash_object(plan$source_url[i]), 1L, 8L)
      plan$local_path[i] <- if (nzchar(ext)) {
        sprintf("%s-%s.%s", stem, suffix, ext)
      } else {
        sprintf("%s-%s", stem, suffix)
      }
    }
  }
  plan
}

.bt_download_one <- function(row, verify, on_exists, retries, timeout, workers) {
  started <- .bt_now_iso()
  dest <- row$local_path
  .bt_ensure_dir(dirname(dest))
  lock <- paste0(dest, ".lock")
  .bt_with_lock(lock, {
    if (file.exists(dest) && !identical(on_exists, "replace")) {
      existing <- .bt_handle_existing_file(dest, row, verify, on_exists)
      if (!is.null(existing)) {
        existing$started_at <- started
        existing$completed_at <- .bt_now_iso()
        return(existing)
      }
    }
    tmp <- tempfile(pattern = paste0(basename(dest), "-"), tmpdir = dirname(dest), fileext = ".part")
    on.exit(unlink(tmp, force = TRUE), add = TRUE)
    downloaded_tmp <- .bt_curl_download(row$source_url, tmp, retries = retries, timeout = timeout)
    attempts <- attr(downloaded_tmp, "attempts", exact = TRUE) %||% retries
    .bt_install_file_transactionally(tmp, dest, validate = function(staged) {
      .bt_validate_downloaded_asset(staged, row, verify)
      TRUE
    })
    row$status <- "downloaded"
    row$verified <- !identical(verify, "none")
    row$actual_sha256 <- if (file.exists(dest)) .bt_sha256_file(dest) else NA_character_
    row$downloaded_bytes <- file.info(dest)$size
    row$attempts <- attempts
    row$started_at <- started
    row$completed_at <- .bt_now_iso()
    row$error_class <- NA_character_
    row$error_message <- NA_character_
    row
  })
}

.bt_handle_existing_file <- function(dest, row, verify, on_exists) {
  if (identical(on_exists, "skip")) {
    row$status <- "skipped_existing"
    row$verified <- FALSE
    row$downloaded_bytes <- file.info(dest)$size
    row$actual_sha256 <- if (file.exists(dest)) .bt_sha256_file(dest) else NA_character_
    row$attempts <- 0L
    return(row)
  }
  if (identical(on_exists, "verify")) {
    ok <- .bt_verify_file(dest, row, verify)
    if (isTRUE(ok)) {
      row$status <- "reused_verified"
      row$verified <- !identical(verify, "none")
      row$downloaded_bytes <- file.info(dest)$size
      row$actual_sha256 <- if (file.exists(dest)) .bt_sha256_file(dest) else NA_character_
      row$attempts <- 0L
      return(row)
    }
    unlink(dest, force = TRUE)
    return(NULL)
  }
  NULL
}

.bt_validate_downloaded_asset <- function(path, row, verify) {
  if (!.bt_file_exists_nonzero(path)) {
    .bt_abort(sprintf("Downloaded file for tile `%s` is empty.", row$tile_id),
      class = "bluertopo_error_download"
    )
  }
  if (!.bt_verify_file(path, row, verify)) {
    unlink(path, force = TRUE)
    .bt_abort(sprintf("Checksum verification failed for tile `%s` (%s).", row$tile_id, row$asset_type),
      class = "bluertopo_error_checksum"
    )
  }
  if (identical(row$asset_type, "geotiff")) {
    r <- tryCatch(terra::rast(path), error = function(e) {
      .bt_abort(sprintf("Downloaded GeoTIFF for tile `%s` is not readable by terra.", row$tile_id),
        class = "bluertopo_error_raster",
        parent = e
      )
    })
    if (terra::nlyr(r) < 3L) {
      .bt_abort(sprintf("Downloaded GeoTIFF for tile `%s` has fewer than three bands.", row$tile_id),
        class = "bluertopo_error_raster"
      )
    }
  }
  invisible(TRUE)
}

.bt_verify_file <- function(path, row, verify) {
  if (identical(verify, "none")) {
    return(TRUE)
  }
  if (identical(verify, "size")) {
    if (is.na(row$expected_bytes)) {
      .bt_abort("`verify = \"size\"` requires trustworthy expected byte counts, which are not present.",
        class = "bluertopo_error_download"
      )
    }
    return(identical(as.numeric(file.info(path)$size), as.numeric(row$expected_bytes)))
  }
  expected <- row$expected_sha256 %||% NA_character_
  if (is.na(expected) || !nzchar(expected)) {
    .bt_abort(sprintf("Missing expected SHA-256 checksum for tile `%s` (%s).", row$tile_id, row$asset_type),
      class = "bluertopo_error_checksum"
    )
  }
  identical(tolower(.bt_sha256_file(path)), tolower(expected))
}

.bt_as_downloads <- function(x) {
  structure(x, class = c("bluertopo_downloads", "data.frame"))
}
