`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

.bt_package_version <- function() {
  as.character(utils::packageVersion("bluertopo"))
}

.bt_user_agent <- function() {
  sprintf("bluertopo/%s (https://github.com/el-cordero/bluer-topo)", .bt_package_version())
}

.bt_is_scalar_character <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x)
}

.bt_match_arg <- function(x, choices, name = deparse(substitute(x))) {
  if (!.bt_is_scalar_character(x) || !(x %in% choices)) {
    .bt_abort(
      sprintf("`%s` must be one of: %s.", name, paste(sQuote(choices), collapse = ", ")),
      class = "bluertopo_error_argument"
    )
  }
  x
}

.bt_validate_bool <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    .bt_abort(sprintf("`%s` must be TRUE or FALSE.", name), class = "bluertopo_error_argument")
  }
  x
}

.bt_validate_number <- function(x, name, positive = TRUE, allow_null = FALSE) {
  if (allow_null && is.null(x)) {
    return(NULL)
  }
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x)) {
    .bt_abort(sprintf("`%s` must be a finite number.", name), class = "bluertopo_error_argument")
  }
  if (positive && x <= 0) {
    .bt_abort(sprintf("`%s` must be greater than zero.", name), class = "bluertopo_error_argument")
  }
  x
}

.bt_validate_count <- function(x, name, allow_null = FALSE, class = "bluertopo_error_argument") {
  value <- .bt_validate_number(x, name, positive = TRUE, allow_null = allow_null)
  if (is.null(value)) {
    return(NULL)
  }
  if (isTRUE(value != floor(value))) {
    .bt_abort(sprintf("`%s` must be a positive whole number.", name), class = class)
  }
  as.integer(value)
}

.bt_file_exists_nonzero <- function(path) {
  file.exists(path) && isTRUE(file.info(path)$size > 0)
}

.bt_sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

.bt_normalize_path <- function(path, must_work = FALSE) {
  normalizePath(path, winslash = "/", mustWork = must_work)
}

.bt_ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  .bt_normalize_path(path, must_work = TRUE)
}

.bt_is_url <- function(x) {
  .bt_is_scalar_character(x) && grepl("^[A-Za-z][A-Za-z0-9+.-]*://", x)
}

.bt_parse_url <- function(url) {
  out <- tryCatch(curl::curl_parse_url(url), error = function(e) NULL)
  if (is.null(out)) {
    .bt_abort(
      sprintf("Could not parse source URL: %s.", .bt_redact_url(url)),
      class = "bluertopo_error_download"
    )
  }
  out
}

.bt_redact_url <- function(url) {
  sub("://[^/@]+@", "://<redacted>@", url)
}

.bt_validate_source_url <- function(url, role = "source asset") {
  if (!.bt_is_scalar_character(url) || !nzchar(url)) {
    .bt_abort(sprintf("Missing %s URL.", role), class = "bluertopo_error_download")
  }
  parsed <- .bt_parse_url(url)
  allow_test_hosts <- isTRUE(getOption("bluertopo.allow_test_hosts", FALSE))
  scheme <- parsed$scheme %||% ""
  host <- parsed$host %||% ""
  if (!allow_test_hosts) {
    if (!identical(tolower(scheme), "https")) {
      .bt_abort(
        sprintf("Refusing non-HTTPS %s URL: %s.", role, .bt_redact_url(url)),
        class = "bluertopo_error_download"
      )
    }
    if (!identical(tolower(host), .bt_bucket_host)) {
      .bt_abort(
        sprintf(
          "Refusing unexpected %s host `%s`; expected `%s`.",
          role,
          host,
          .bt_bucket_host
        ),
        class = "bluertopo_error_download"
      )
    }
  } else if (!(tolower(scheme) %in% c("https", "http", "file"))) {
    .bt_abort(
      sprintf("Unsupported test %s URL scheme `%s`.", role, scheme),
      class = "bluertopo_error_download"
    )
  }
  username <- parsed$username %||% parsed$user %||% ""
  password <- parsed$password %||% ""
  if (nzchar(username) || nzchar(password)) {
    .bt_abort(
      sprintf("Refusing %s URL with embedded credentials: %s.", role, .bt_redact_url(url)),
      class = "bluertopo_error_download"
    )
  }
  invisible(url)
}

.bt_safe_basename_from_url <- function(url) {
  parsed <- .bt_parse_url(url)
  path <- parsed$path %||% ""
  name <- basename(utils::URLdecode(path))
  invalid <- !nzchar(name) ||
    name %in% c(".", "..") ||
    grepl("[/\\\\]", name) ||
    any(charToRaw(name) == as.raw(0))
  if (invalid) {
    .bt_abort(
      sprintf("Could not derive a safe local filename from URL: %s.", .bt_redact_url(url)),
      class = "bluertopo_error_download"
    )
  }
  name
}

.bt_atomic_write_json <- function(x, path, pretty = TRUE) {
  .bt_ensure_dir(dirname(path))
  tmp <- tempfile(pattern = paste0(basename(path), "-"), tmpdir = dirname(path))
  on.exit(unlink(tmp, force = TRUE), add = TRUE)
  jsonlite::write_json(x, tmp, auto_unbox = TRUE, pretty = pretty, null = "null")
  .bt_install_file_transactionally(tmp, path, validate = function(staged) {
    jsonlite::read_json(staged, simplifyVector = FALSE)
    TRUE
  })
  invisible(path)
}

.bt_atomic_write_csv <- function(x, path) {
  .bt_ensure_dir(dirname(path))
  tmp <- tempfile(pattern = paste0(basename(path), "-"), tmpdir = dirname(path))
  on.exit(unlink(tmp, force = TRUE), add = TRUE)
  utils::write.csv(x, tmp, row.names = FALSE, na = "")
  .bt_install_file_transactionally(tmp, path, validate = function(staged) {
    .bt_file_exists_nonzero(staged)
  })
  invisible(path)
}

.bt_install_file_transactionally <- function(tmp, dest, validate = function(path) TRUE) {
  if (!file.exists(tmp)) {
    .bt_abort(sprintf("Staged file `%s` does not exist.", tmp), class = "bluertopo_error_filesystem")
  }
  if (dir.exists(dest)) {
    .bt_abort(sprintf("Destination `%s` is a directory, not a file.", dest),
      class = "bluertopo_error_filesystem"
    )
  }
  .bt_ensure_dir(dirname(dest))
  dest <- .bt_normalize_path(dest, must_work = FALSE)
  tmp <- .bt_normalize_path(tmp, must_work = TRUE)
  validated <- tryCatch(validate(tmp), error = function(e) {
    if (inherits(e, "bluertopo_error")) {
      stop(e)
    }
    .bt_abort(sprintf("Staged file `%s` failed validation before install.", tmp),
      class = "bluertopo_error_filesystem",
      parent = e
    )
  })
  if (!isTRUE(validated)) {
    .bt_abort(sprintf("Staged file `%s` failed validation before install.", tmp),
      class = "bluertopo_error_filesystem"
    )
  }

  backup <- NULL
  restore_needed <- FALSE
  if (file.exists(dest)) {
    backup <- paste0(
      dest,
      ".backup-",
      format(Sys.time(), "%Y%m%d%H%M%S", tz = "UTC"),
      "-",
      substr(.bt_hash_object(list(dest, tmp, Sys.getpid(), stats::runif(1L))), 1L, 8L)
    )
    if (!file.rename(dest, backup)) {
      .bt_abort(sprintf("Could not back up existing file `%s` before install.", dest),
        class = "bluertopo_error_filesystem"
      )
    }
    restore_needed <- TRUE
  }
  on.exit({
    if (!is.null(backup) && file.exists(backup)) {
      unlink(backup, force = TRUE)
    }
  }, add = TRUE)

  install_error <- NULL
  tryCatch({
    if (isTRUE(getOption("bluertopo.test_install_fail_after_backup", FALSE))) {
      stop("Injected transactional install failure.", call. = FALSE)
    }
    if (!file.rename(tmp, dest)) {
      stop("Could not move staged file into place.", call. = FALSE)
    }
  }, error = function(e) {
    install_error <<- e
  })

  if (!is.null(install_error)) {
    restored <- FALSE
    if (isTRUE(restore_needed) && !file.exists(dest) && !is.null(backup) && file.exists(backup)) {
      restored <- file.rename(backup, dest)
    }
    .bt_abort(c(
      sprintf("Could not install staged file at `%s` transactionally.", dest),
      "i" = if (isTRUE(restored)) {
        "The previous file was restored."
      } else if (isTRUE(restore_needed)) {
        "The previous file could not be restored automatically."
      } else {
        "No previous file existed."
      }
    ), class = "bluertopo_error_filesystem", parent = install_error)
  }

  invisible(dest)
}

.bt_with_lock <- function(lock_dir, expr, timeout = 30, stale_seconds = 2 * 60 * 60) {
  lock_dir <- .bt_normalize_path(lock_dir, must_work = FALSE)
  .bt_ensure_dir(dirname(lock_dir))
  start <- Sys.time()
  repeat {
    if (dir.create(lock_dir, showWarnings = FALSE)) {
      break
    }
    info <- file.info(lock_dir)
    if (isTRUE(!is.na(info$mtime))) {
      age <- as.numeric(difftime(Sys.time(), info$mtime, units = "secs"))
      if (is.finite(age) && age > stale_seconds) {
        unlink(lock_dir, recursive = TRUE, force = TRUE)
        next
      }
    }
    waited <- as.numeric(difftime(Sys.time(), start, units = "secs"))
    if (waited > timeout) {
      .bt_abort(
        sprintf("Timed out waiting for lock `%s`.", lock_dir),
        class = "bluertopo_error_filesystem"
      )
    }
    Sys.sleep(stats::runif(1L, 0.05, 0.2))
  }
  on.exit(unlink(lock_dir, recursive = TRUE, force = TRUE), add = TRUE)
  force(expr)
}

.bt_hash_object <- function(x) {
  digest::digest(x, algo = "sha256", serialize = TRUE)
}

.bt_now_iso <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

.bt_file_url <- function(path) {
  paste0("file://", .bt_normalize_path(path, must_work = TRUE))
}

.bt_subset_df <- function(x, rows) {
  x[rows, , drop = FALSE]
}
