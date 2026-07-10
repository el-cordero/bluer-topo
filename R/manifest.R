.bt_manifest_paths <- function(path) {
  list(
    csv = file.path(path, "bluertopo-download-manifest.csv"),
    json = file.path(path, "bluertopo-download-manifest.json")
  )
}

.bt_query_manifest_paths <- function(path, query_hash) {
  if (is.null(query_hash) || is.na(query_hash) || !nzchar(query_hash)) {
    return(list())
  }
  hash <- gsub("[^A-Za-z0-9_-]", "", substr(query_hash, 1L, 16L))
  if (!nzchar(hash)) {
    return(list())
  }
  list(
    csv = file.path(path, "manifests", paste0("bluertopo-download-manifest-", hash, ".csv")),
    json = file.path(path, "manifests", paste0("bluertopo-download-manifest-", hash, ".json"))
  )
}

.bt_write_download_manifests <- function(manifest, path, query = list(), coverage = list(), provenance = list()) {
  paths <- .bt_manifest_paths(path)
  .bt_atomic_write_csv(manifest, paths$csv)
  payload <- list(
    query = query,
    coverage = coverage,
    provenance = provenance,
    downloads = manifest,
    written_at = .bt_now_iso(),
    package_version = .bt_package_version()
  )
  .bt_atomic_write_json(payload, paths$json)
  query_paths <- .bt_query_manifest_paths(path, query$query_hash %||% NA_character_)
  if (length(query_paths)) {
    .bt_atomic_write_csv(manifest, query_paths$csv)
    .bt_atomic_write_json(payload, query_paths$json)
    paths$query_csv <- query_paths$csv
    paths$query_json <- query_paths$json
  }
  invisible(paths)
}

.bt_download_manifest_provenance <- function(catalog) {
  meta <- catalog$metadata
  list(
    noaa_attribution = "NOAA National Bathymetric Source Data / BlueTopo",
    source_product_name = "NOAA BlueTopo",
    noaa_bluetopo_reference_url = "https://nauticalcharts.noaa.gov/data/bluetopo.html",
    not_for_navigation = .bt_not_for_navigation,
    noaa_affiliation = "This R package is not affiliated with, endorsed by, or supported by NOAA.",
    catalog_name = meta$catalog_name %||% NA_character_,
    catalog_source_url = meta$source_url %||% NA_character_,
    catalog_source_key = meta$source_key %||% NA_character_,
    catalog_last_modified = meta$last_modified %||% NA_character_,
    catalog_etag = meta$etag %||% NA_character_,
    catalog_checksum = meta$local_checksum %||% NA_character_,
    catalog_retrieved_at = meta$retrieved_at %||% NA_character_
  )
}
