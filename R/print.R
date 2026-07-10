#' @export
print.bluertopo_resolution <- function(x, ...) {
  cat("<bluertopo_resolution>\n")
  cat("  strategy:", x$strategy, "\n")
  if (!is.null(x$value)) cat("  value:", x$value, "m\n")
  if (!is.null(x$values)) cat("  values:", paste(x$values, collapse = ", "), "m\n")
  if (!is.null(x$min_m) || !is.null(x$max_m)) {
    cat("  bounds:", x$min_m %||% "-Inf", "to", x$max_m %||% "Inf", "m\n")
  }
  if (!is.null(x$n)) cat("  n:", x$n, "\n")
  cat("  scope:", x$scope, "\n")
  cat("  strict:", x$strict, "\n")
  invisible(x)
}

#' @export
print.bluertopo_downloads <- function(x, ...) {
  cat("<bluertopo_downloads> ", nrow(x), " asset", if (nrow(x) == 1L) "" else "s", "\n", sep = "")
  if (nrow(x)) {
    counts <- table(x$status, useNA = "ifany")
    cat("  status:", paste(sprintf("%s=%s", names(counts), as.integer(counts)), collapse = ", "), "\n")
    cat("  tiles:", length(unique(x$tile_id)), "\n")
  }
  invisible(x)
}

#' @export
print.bluertopo_result <- function(x, ...) {
  cat("<bluertopo_result>\n")
  cat("  data:", paste(class(x$data), collapse = "/"), "\n")
  cat("  tiles:", nrow(x$tiles), "\n")
  cat("  downloads:", nrow(x$downloads), "\n")
  cov <- x$coverage
  if (length(cov)) {
    cat(sprintf("  selected coverage: %.1f%% of published coverage\n", 100 * cov$selected_coverage_fraction))
  }
  invisible(x)
}

#' @export
print.bluertopo_cache_clear <- function(x, ...) {
  cat("<bluertopo_cache_clear>\n")
  cat("  cache_dir:", x$cache_dir[1L], "\n")
  cat("  removed_files:", x$removed_files[1L], "\n")
  cat("  removed_bytes:", x$removed_bytes[1L], "\n")
  invisible(x)
}
