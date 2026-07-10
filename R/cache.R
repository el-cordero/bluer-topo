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
  requested <- cache_dir
  cache_dir <- .bt_normalize_path(cache_dir, must_work = FALSE)
  configured <- .bt_normalize_path(bluertopo_cache_dir(), must_work = FALSE)
  if (!confirm) {
    .bt_abort(
      "`confirm = TRUE` is required to clear the bluertopo cache.",
      class = "bluertopo_error_filesystem"
    )
  }
  if (!identical(cache_dir, configured)) {
    .bt_abort(
      "Refusing to clear a path that is not the configured `bluertopo` cache directory.",
      class = "bluertopo_error_filesystem"
    )
  }
  if (.bt_is_symlink_path(requested)) {
    .bt_abort("Refusing to clear a cache path reached through a symlink.",
      class = "bluertopo_error_filesystem"
    )
  }
  .bt_refuse_suspicious_cache_path(cache_dir)
  if (!dir.exists(cache_dir)) {
    return(structure(
      data.frame(
        cache_dir = cache_dir,
        removed_files = 0L,
        removed_bytes = 0,
        failed_paths = I(list(character())),
        stringsAsFactors = FALSE
      ),
      class = c("bluertopo_cache_clear", "data.frame")
    ))
  }
  .bt_validate_cache_marker(cache_dir)
  entries <- .bt_cache_owned_paths(cache_dir)
  entries <- entries[file.exists(entries)]
  files <- unlist(lapply(entries, function(path) {
    c(path, list.files(path, all.files = TRUE, recursive = TRUE, full.names = TRUE, no.. = TRUE))
  }), use.names = FALSE)
  info <- file.info(files)
  removed_bytes <- sum(info$size[!is.na(info$size) & !info$isdir], na.rm = TRUE)
  removed_files <- sum(!is.na(info$isdir) & !info$isdir)
  failed <- character()
  if (length(entries)) {
    unlink(entries, recursive = TRUE, force = TRUE)
    failed <- entries[file.exists(entries)]
  }
  .bt_init_cache(cache_dir)
  structure(
    data.frame(
      cache_dir = cache_dir,
      removed_files = as.integer(removed_files),
      removed_bytes = as.numeric(removed_bytes),
      failed_paths = I(list(failed)),
      stringsAsFactors = FALSE
    ),
    class = c("bluertopo_cache_clear", "data.frame")
  )
}

.bt_cache_marker_name <- ".bluertopo-cache.json"

.bt_cache_known_children <- function() {
  c(
    .bt_cache_marker_name,
    "catalog",
    "tiles",
    "vrt",
    "manifests",
    "locks"
  )
}

.bt_cache_marker_path <- function(cache_dir) {
  file.path(cache_dir, .bt_cache_marker_name)
}

.bt_cache_owned_paths <- function(cache_dir) {
  file.path(cache_dir, setdiff(.bt_cache_known_children(), .bt_cache_marker_name))
}

.bt_is_symlink_path <- function(path) {
  link <- Sys.readlink(path)
  isTRUE(!is.na(link) && nzchar(link))
}

.bt_init_cache <- function(cache_dir = bluertopo_cache_dir()) {
  if (.bt_is_symlink_path(cache_dir)) {
    .bt_abort("Refusing to use a cache path reached through a symlink.",
      class = "bluertopo_error_filesystem"
    )
  }
  cache_dir <- .bt_ensure_dir(cache_dir)
  .bt_refuse_suspicious_cache_path(cache_dir)
  marker <- .bt_cache_marker_path(cache_dir)
  if (file.exists(marker)) {
    .bt_validate_cache_marker(cache_dir)
    return(cache_dir)
  }
  entries <- basename(list.files(cache_dir, all.files = TRUE, no.. = TRUE, full.names = FALSE))
  unexpected <- setdiff(entries, .bt_cache_known_children())
  if (length(unexpected)) {
    .bt_abort(c(
      sprintf("Refusing to mark non-empty cache directory `%s` as package-owned.", cache_dir),
      "x" = sprintf("Unexpected existing entries: %s.", paste(unexpected, collapse = ", ")),
      "i" = "Choose an empty directory or the package default cache path."
    ), class = "bluertopo_error_filesystem")
  }
  .bt_atomic_write_json(list(
    package = "bluertopo",
    cache_format_version = 1L,
    cache_dir = cache_dir,
    created_at = .bt_now_iso()
  ), marker)
  cache_dir
}

.bt_read_cache_marker <- function(cache_dir) {
  marker <- .bt_cache_marker_path(cache_dir)
  if (!file.exists(marker)) {
    .bt_abort(c(
      sprintf("The configured cache directory `%s` is missing `%s`.", cache_dir, .bt_cache_marker_name),
      "i" = "Refusing cache-clear operations unless package ownership can be verified."
    ), class = "bluertopo_error_filesystem")
  }
  tryCatch(
    jsonlite::read_json(marker, simplifyVector = TRUE),
    error = function(e) {
      .bt_abort(sprintf("Could not read bluertopo cache marker `%s`.", marker),
        class = "bluertopo_error_filesystem",
        parent = e
      )
    }
  )
}

.bt_validate_cache_marker <- function(cache_dir) {
  marker <- .bt_read_cache_marker(cache_dir)
  if (!identical(marker$package %||% NULL, "bluertopo")) {
    .bt_abort("Cache marker does not identify a `bluertopo` cache.",
      class = "bluertopo_error_filesystem"
    )
  }
  version <- as.integer(marker$cache_format_version %||% NA_integer_)
  if (is.na(version) || version != 1L) {
    .bt_abort("Unsupported bluertopo cache marker version.",
      class = "bluertopo_error_filesystem"
    )
  }
  marker_dir <- marker$cache_dir %||% cache_dir
  marker_dir <- .bt_normalize_path(marker_dir, must_work = FALSE)
  cache_dir <- .bt_normalize_path(cache_dir, must_work = FALSE)
  if (!identical(marker_dir, cache_dir)) {
    .bt_abort("Cache marker path does not match the configured cache directory.",
      class = "bluertopo_error_filesystem"
    )
  }
  invisible(marker)
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
