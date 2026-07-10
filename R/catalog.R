.bt_get_catalog <- function(
  cache_dir = bluertopo_cache_dir(),
  refresh = c("if_stale", "never", "always"),
  quiet = FALSE
) {
  refresh <- .bt_match_arg(refresh[1L], c("if_stale", "never", "always"), "refresh")
  override <- getOption("bluertopo.catalog.path", NULL)
  if (!is.null(override)) {
    return(.bt_catalog_from_local(override))
  }

  paths <- .bt_cache_paths(cache_dir)
  ttl <- getOption("bluertopo.catalog_ttl_seconds", .bt_catalog_ttl_seconds)
  ttl <- .bt_validate_number(ttl, "bluertopo.catalog_ttl_seconds", positive = TRUE)

  if (refresh == "never") {
    if (!file.exists(paths$catalog_gpkg)) {
      .bt_abort(
        "No cached BlueTopo tile-scheme catalog is available and `refresh = \"never\"` was requested.",
        class = "bluertopo_error_catalog"
      )
    }
    return(.bt_catalog_from_cache(paths))
  }

  if (refresh == "if_stale" && .bt_cached_catalog_is_fresh(paths, ttl)) {
    return(.bt_catalog_from_cache(paths))
  }

  .bt_with_lock(file.path(paths$locks, "catalog.lock"), {
    if (refresh == "if_stale" && .bt_cached_catalog_is_fresh(paths, ttl)) {
      return(.bt_catalog_from_cache(paths))
    }
    .bt_ensure_dir(paths$catalog)
    .bt_ensure_dir(paths$locks)
    remote <- .bt_discover_remote_catalog()
    if (.bt_remote_matches_cached(paths, remote)) {
      meta <- jsonlite::read_json(paths$catalog_metadata, simplifyVector = TRUE)
      meta$retrieved_at <- .bt_now_iso()
      .bt_atomic_write_json(meta, paths$catalog_metadata)
      return(.bt_catalog_from_cache(paths))
    }
    .bt_inform(
      sprintf("Downloading BlueTopo tile scheme `%s`.", basename(remote$key)),
      quiet = quiet
    )
    tmp <- tempfile(pattern = "catalog-", tmpdir = paths$catalog, fileext = ".gpkg")
    on.exit(unlink(tmp, force = TRUE), add = TRUE)
    invisible(.bt_curl_download(remote$url, tmp, retries = 3, timeout = NULL))
    .bt_validate_catalog_file(tmp, remote)
    if (!file.rename(tmp, paths$catalog_gpkg)) {
      .bt_abort("Could not replace cached BlueTopo catalog atomically.", class = "bluertopo_error_catalog")
    }
    meta <- .bt_catalog_metadata(paths$catalog_gpkg, remote)
    .bt_atomic_write_json(meta, paths$catalog_metadata)
    .bt_catalog_from_cache(paths)
  })
}

.bt_catalog_from_local <- function(path) {
  path <- .bt_normalize_path(path, must_work = TRUE)
  meta <- list(
    catalog_path = path,
    catalog_name = basename(path),
    source_url = .bt_file_url(path),
    source_key = basename(path),
    last_modified = NA_character_,
    etag = NA_character_,
    content_length = file.info(path)$size,
    retrieved_at = NA_character_,
    package_version = .bt_package_version(),
    local_checksum = .bt_sha256_file(path),
    behavior_version = .bt_behavior_version
  )
  .bt_validate_catalog_file(path, meta)
  list(path = path, metadata = meta)
}

.bt_catalog_from_cache <- function(paths) {
  if (!file.exists(paths$catalog_gpkg)) {
    .bt_abort("Cached BlueTopo catalog file is missing.", class = "bluertopo_error_catalog")
  }
  meta <- if (file.exists(paths$catalog_metadata)) {
    jsonlite::read_json(paths$catalog_metadata, simplifyVector = TRUE)
  } else {
    list()
  }
  meta$catalog_path <- paths$catalog_gpkg
  .bt_validate_catalog_file(paths$catalog_gpkg, meta)
  list(path = paths$catalog_gpkg, metadata = meta)
}

.bt_cached_catalog_is_fresh <- function(paths, ttl) {
  if (!file.exists(paths$catalog_gpkg) || !file.exists(paths$catalog_metadata)) {
    return(FALSE)
  }
  meta <- tryCatch(jsonlite::read_json(paths$catalog_metadata, simplifyVector = TRUE), error = function(e) NULL)
  if (is.null(meta) || is.null(meta$retrieved_at)) {
    return(FALSE)
  }
  retrieved <- as.POSIXct(meta$retrieved_at, tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")
  if (is.na(retrieved)) {
    return(FALSE)
  }
  age <- as.numeric(difftime(Sys.time(), retrieved, units = "secs"))
  is.finite(age) && age <= ttl
}

.bt_remote_matches_cached <- function(paths, remote) {
  if (!file.exists(paths$catalog_gpkg) || !file.exists(paths$catalog_metadata)) {
    return(FALSE)
  }
  meta <- tryCatch(jsonlite::read_json(paths$catalog_metadata, simplifyVector = TRUE), error = function(e) NULL)
  if (is.null(meta)) {
    return(FALSE)
  }
  same_key <- identical(meta$source_key %||% NA_character_, remote$key %||% NA_character_)
  same_etag <- nzchar(meta$etag %||% "") &&
    nzchar(remote$etag %||% "") &&
    identical(meta$etag, remote$etag)
  same_last_modified <- nzchar(meta$last_modified %||% "") &&
    nzchar(remote$last_modified %||% "") &&
    identical(meta$last_modified, remote$last_modified)
  same_size <- !is.na(meta$content_length %||% NA_real_) &&
    !is.na(remote$content_length %||% NA_real_) &&
    identical(as.numeric(meta$content_length), as.numeric(remote$content_length))
  same_key && (same_etag || (same_last_modified && same_size))
}

.bt_discover_remote_catalog <- function() {
  base_url <- getOption("bluertopo.catalog_base_url", .bt_bucket_url)
  prefix <- getOption("bluertopo.catalog_prefix", .bt_tile_scheme_prefix)
  all_objects <- list()
  token <- NULL
  repeat {
    page <- .bt_list_s3_objects(base_url, prefix, continuation_token = token)
    all_objects <- c(all_objects, page$objects)
    if (!isTRUE(page$is_truncated)) {
      break
    }
    token <- page$next_token
    if (is.null(token) || !nzchar(token)) {
      .bt_abort("S3 catalog listing was truncated but did not include a continuation token.",
        class = "bluertopo_error_catalog"
      )
    }
  }
  .bt_select_newest_catalog(all_objects)
}

.bt_list_s3_objects <- function(base_url, prefix, continuation_token = NULL, max_keys = 1000) {
  query <- sprintf(
    "list-type=2&prefix=%s&max-keys=%d",
    utils::URLencode(prefix, reserved = TRUE),
    as.integer(max_keys)
  )
  if (!is.null(continuation_token)) {
    query <- paste0(query, "&continuation-token=", utils::URLencode(continuation_token, reserved = TRUE))
  }
  url <- paste0(sub("/+$", "", base_url), "/?", query)
  response <- .bt_curl_fetch(url, timeout = 30)
  doc <- tryCatch(xml2::read_xml(response$content), error = function(e) {
    .bt_abort("Could not parse S3 ListObjectsV2 XML response.",
      class = "bluertopo_error_catalog",
      parent = e
    )
  })
  xml2::xml_ns_strip(doc)
  contents <- xml2::xml_find_all(doc, ".//Contents")
  objects <- lapply(contents, function(node) {
    key <- xml2::xml_text(xml2::xml_find_first(node, "Key"))
    last_modified <- xml2::xml_text(xml2::xml_find_first(node, "LastModified"))
    etag <- gsub('"', "", xml2::xml_text(xml2::xml_find_first(node, "ETag")), fixed = TRUE)
    size <- suppressWarnings(as.numeric(xml2::xml_text(xml2::xml_find_first(node, "Size"))))
    list(
      key = key,
      url = paste0(sub("/+$", "", base_url), "/", utils::URLencode(key, reserved = TRUE)),
      last_modified = last_modified,
      etag = etag,
      content_length = size
    )
  })
  is_truncated <- identical(tolower(xml2::xml_text(xml2::xml_find_first(doc, ".//IsTruncated"))), "true")
  next_token <- xml2::xml_text(xml2::xml_find_first(doc, ".//NextContinuationToken"))
  list(objects = objects, is_truncated = is_truncated, next_token = next_token)
}

.bt_select_newest_catalog <- function(objects) {
  if (!length(objects)) {
    .bt_abort("No objects were returned under the BlueTopo tile-scheme prefix.",
      class = "bluertopo_error_catalog"
    )
  }
  plausible <- vapply(objects, function(x) {
    grepl("\\.gpkg$", x$key, ignore.case = TRUE) &&
      grepl("BlueTopo_Tile_Scheme", basename(x$key), fixed = TRUE)
  }, logical(1L))
  candidates <- objects[plausible]
  if (!length(candidates)) {
    .bt_abort("No plausible BlueTopo tile-scheme GeoPackage objects were found.",
      class = "bluertopo_error_catalog"
    )
  }
  last_modified <- vapply(candidates, function(x) x$last_modified %||% "", character(1L))
  parsed_last_modified <- as.POSIXct(last_modified, tz = "UTC", format = "%Y-%m-%dT%H:%M:%OSZ")
  if (all(is.na(parsed_last_modified))) {
    .bt_abort("Could not parse LastModified timestamps for BlueTopo tile-scheme candidates.",
      class = "bluertopo_error_catalog"
    )
  }
  filename_stamp <- vapply(candidates, function(x) {
    m <- regmatches(basename(x$key), regexpr("[0-9]{8}_[0-9]{6}", basename(x$key)))
    ifelse(length(m) && nzchar(m), m, "")
  }, character(1L))
  key <- vapply(candidates, `[[`, "", "key")
  order_idx <- order(-as.numeric(parsed_last_modified), -as.numeric(gsub("[^0-9]", "", filename_stamp)), key)
  candidates[[order_idx[1L]]]
}

.bt_curl_fetch <- function(url, timeout = NULL) {
  handle <- curl::new_handle(
    useragent = .bt_user_agent(),
    followlocation = TRUE,
    failonerror = FALSE
  )
  if (!is.null(timeout)) {
    curl::handle_setopt(handle, timeout = timeout)
  }
  response <- tryCatch(curl::curl_fetch_memory(url, handle = handle), error = function(e) {
    .bt_abort(sprintf("HTTP request failed for `%s`.", .bt_redact_url(url)),
      class = "bluertopo_error_download",
      parent = e
    )
  })
  status <- response$status_code %||% 0L
  if (status < 200L || status >= 300L) {
    .bt_abort(
      sprintf("HTTP request for `%s` returned status %d.", .bt_redact_url(url), status),
      class = "bluertopo_error_download"
    )
  }
  response
}

.bt_curl_download <- function(url, dest, retries = 3, timeout = NULL) {
  .bt_validate_source_url(url, role = "download")
  last_error <- NULL
  attempts <- 0L
  for (attempt in seq_len(max(1L, retries))) {
    attempts <- attempt
    handle <- curl::new_handle(
      useragent = .bt_user_agent(),
      followlocation = TRUE,
      failonerror = TRUE
    )
    if (!is.null(timeout)) {
      curl::handle_setopt(handle, timeout = timeout)
    }
    ok <- tryCatch({
      curl::curl_download(url, destfile = dest, quiet = TRUE, handle = handle)
      TRUE
    }, error = function(e) {
      last_error <<- e
      FALSE
    })
    if (ok) {
      attr(dest, "attempts") <- attempts
      return(dest)
    }
    if (attempt < retries) {
      Sys.sleep(min(8, 0.25 * 2^(attempt - 1L)) + stats::runif(1L, 0, 0.2))
    }
  }
  .bt_abort(sprintf("Download failed for `%s` after %d attempt(s).", .bt_redact_url(url), retries),
    class = "bluertopo_error_download",
    parent = last_error
  )
}

.bt_catalog_metadata <- function(path, remote) {
  schema <- .bt_catalog_schema_fingerprint(path)
  list(
    catalog_path = path,
    catalog_name = basename(remote$key %||% path),
    source_url = remote$url %||% NA_character_,
    source_key = remote$key %||% NA_character_,
    last_modified = remote$last_modified %||% NA_character_,
    etag = remote$etag %||% NA_character_,
    content_length = remote$content_length %||% file.info(path)$size,
    retrieved_at = .bt_now_iso(),
    package_version = .bt_package_version(),
    local_checksum = .bt_sha256_file(path),
    schema_fingerprint = schema$fingerprint,
    schema_fields = schema$fields,
    behavior_version = .bt_behavior_version
  )
}

.bt_catalog_schema_fingerprint <- function(path) {
  layer <- .bt_catalog_layer(path)
  v <- terra::vect(path, layer = layer)
  fields <- names(v)
  list(
    fields = fields,
    fingerprint = .bt_hash_object(fields)
  )
}

.bt_validate_catalog_file <- function(path, metadata = list()) {
  layer <- .bt_catalog_layer(path)
  v <- tryCatch(terra::vect(path, layer = layer), error = function(e) {
    .bt_abort(sprintf("Downloaded catalog `%s` is not readable as a GeoPackage.", basename(path)),
      class = "bluertopo_error_catalog",
      parent = e
    )
  })
  observed <- names(v)
  missing <- setdiff(.bt_expected_catalog_fields, observed)
  if (length(missing)) {
    .bt_abort(c(
      sprintf("BlueTopo tile-scheme schema changed for `%s`.", basename(path)),
      "x" = sprintf("Missing expected fields: %s.", paste(missing, collapse = ", ")),
      "i" = sprintf("Observed fields: %s.", paste(observed, collapse = ", ")),
      "i" = sprintf("Package version: %s.", .bt_package_version()),
      "i" = "Please file an issue with the observed schema."
    ), class = "bluertopo_error_schema")
  }
  invisible(TRUE)
}

.bt_catalog_layer <- function(path) {
  layers <- tryCatch(terra::vector_layers(path), error = function(e) character())
  if (!length(layers)) {
    return(NULL)
  }
  for (layer in layers) {
    v <- tryCatch(terra::vect(path, layer = layer), error = function(e) NULL)
    if (!is.null(v) && all(.bt_expected_catalog_fields %in% names(v))) {
      return(layer)
    }
  }
  layers[1L]
}

.bt_read_catalog_vector <- function(catalog) {
  layer <- .bt_catalog_layer(catalog$path)
  v <- terra::vect(catalog$path, layer = layer)
  .bt_normalize_catalog_vector(v, catalog$metadata)
}

.bt_normalize_catalog_vector <- function(v, metadata = list()) {
  observed <- names(v)
  missing <- setdiff(.bt_expected_catalog_fields, observed)
  if (length(missing)) {
    .bt_abort(c(
      "BlueTopo tile-scheme schema does not match the expected fields.",
      "x" = sprintf("Missing expected fields: %s.", paste(missing, collapse = ", ")),
      "i" = sprintf("Observed fields: %s.", paste(observed, collapse = ", ")),
      "i" = sprintf("Catalog filename: %s.", metadata$catalog_name %||% "<unknown>"),
      "i" = sprintf("Package version: %s.", .bt_package_version()),
      "i" = "Please file an issue with the observed schema."
    ), class = "bluertopo_error_schema")
  }
  df <- as.data.frame(v)
  for (standard in names(.bt_catalog_field_map)) {
    source <- .bt_catalog_field_map[[standard]]
    value <- df[[source]]
    if (identical(standard, "resolution_m")) {
      value <- .bt_parse_resolution_m(value, allow_na = TRUE)
    } else if (identical(standard, "delivered_date")) {
      value <- .bt_parse_datetime(value)
    } else {
      value <- as.character(value)
    }
    v[[standard]] <- value
  }
  v$selected <- FALSE
  v$selection_rank <- NA_integer_
  v$selection_reason <- NA_character_
  v$overlap_priority <- NA_integer_
  v$intersection_area_m2 <- NA_real_
  v$intersection_fraction <- NA_real_
  v$fallback <- FALSE
  v$catalog_name <- metadata$catalog_name %||% basename(metadata$catalog_path %||% "")
  v$catalog_last_modified <- metadata$last_modified %||% NA_character_
  attr(v, "bluertopo_catalog") <- metadata
  v
}

.bt_parse_datetime <- function(x) {
  if (inherits(x, "POSIXt")) {
    return(as.POSIXct(x, tz = "UTC"))
  }
  if (inherits(x, "Date")) {
    return(as.POSIXct(x, tz = "UTC"))
  }
  x <- as.character(x)
  out <- as.POSIXct(rep(NA_character_, length(x)), tz = "UTC")
  not_missing <- !is.na(x) & nzchar(x)
  formats <- c(
    "%Y-%m-%d %H:%M:%S",
    "%Y-%m-%dT%H:%M:%OSZ",
    "%Y-%m-%dT%H:%M:%S",
    "%Y-%m-%d"
  )
  for (fmt in formats) {
    idx <- not_missing & is.na(out)
    if (!any(idx)) {
      break
    }
    parsed <- as.POSIXct(x[idx], tz = "UTC", format = fmt)
    out[idx] <- parsed
  }
  out
}
