#' Locate the bluertopo cache directory
#'
#' Returns the configured package cache directory without creating it.
#'
#' @return A single character string.
#' @export
#' @examples
#' bluertopo_cache_dir()
bluertopo_cache_dir <- function() {
  path <- getOption("bluertopo.cache_dir", NULL)
  if (is.null(path) || !nzchar(path)) {
    path <- tools::R_user_dir("bluertopo", "cache")
  }
  .bt_normalize_path(path, must_work = FALSE)
}

#' Clear package-owned cache content
#'
#' Deletes only the configured `bluertopo` package cache after path safeguards.
#'
#' @param cache_dir Cache directory to clear.
#' @param confirm Required as `TRUE` in noninteractive sessions.
#'
#' @return A data frame summary with removed file count and bytes.
#' @export
#' @examples
#' \dontrun{
#' bluertopo_cache_clear(confirm = TRUE)
#' }
bluertopo_cache_clear <- function(cache_dir = bluertopo_cache_dir(), confirm = interactive()) {
  confirm <- .bt_validate_bool(confirm, "confirm")
  cache_dir <- .bt_normalize_path(cache_dir, must_work = FALSE)
  if (!confirm) {
    .bt_abort(
      "`confirm = TRUE` is required to clear the bluertopo cache.",
      class = "bluertopo_error_filesystem"
    )
  }
  .bt_refuse_suspicious_cache_path(cache_dir)
  if (!dir.exists(cache_dir)) {
    return(structure(
      data.frame(cache_dir = cache_dir, removed_files = 0L, removed_bytes = 0, stringsAsFactors = FALSE),
      class = c("bluertopo_cache_clear", "data.frame")
    ))
  }
  entries <- list.files(cache_dir, all.files = TRUE, no.. = TRUE, full.names = TRUE)
  files <- list.files(cache_dir, all.files = TRUE, recursive = TRUE, full.names = TRUE, no.. = TRUE)
  info <- file.info(files)
  removed_bytes <- sum(info$size[!is.na(info$size) & !info$isdir], na.rm = TRUE)
  removed_files <- sum(!is.na(info$isdir) & !info$isdir)
  unlink(entries, recursive = TRUE, force = TRUE)
  structure(
    data.frame(
      cache_dir = cache_dir,
      removed_files = as.integer(removed_files),
      removed_bytes = as.numeric(removed_bytes),
      stringsAsFactors = FALSE
    ),
    class = c("bluertopo_cache_clear", "data.frame")
  )
}

.bt_refuse_suspicious_cache_path <- function(path) {
  path <- .bt_normalize_path(path, must_work = FALSE)
  home <- .bt_normalize_path("~", must_work = TRUE)
  cwd <- .bt_normalize_path(getwd(), must_work = TRUE)
  root <- .bt_normalize_path(.Platform$file.sep, must_work = TRUE)
  suspicious <- path %in% c(root, home, cwd, dirname(home), tempdir())
  if (isTRUE(suspicious)) {
    .bt_abort(
      sprintf("Refusing to clear suspicious cache path `%s`.", path),
      class = "bluertopo_error_filesystem"
    )
  }
  invisible(path)
}

.bt_cache_paths <- function(cache_dir = bluertopo_cache_dir()) {
  cache_dir <- .bt_normalize_path(cache_dir, must_work = FALSE)
  list(
    root = cache_dir,
    catalog = file.path(cache_dir, "catalog"),
    catalog_gpkg = file.path(cache_dir, "catalog", "current.gpkg"),
    catalog_metadata = file.path(cache_dir, "catalog", "catalog-metadata.json"),
    tiles = file.path(cache_dir, "tiles"),
    vrt = file.path(cache_dir, "vrt"),
    manifests = file.path(cache_dir, "manifests"),
    locks = file.path(cache_dir, "locks")
  )
}
