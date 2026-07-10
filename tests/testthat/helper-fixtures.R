make_bt_fixture <- function(root = tempfile("bluertopo-fixture-")) {
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  assets <- file.path(root, "assets")
  dir.create(assets, showWarnings = FALSE)

  specs <- data.frame(
    tile = c("TILE_4M_A", "TILE_8M_B", "TILE_2M_C", "TILE_16M_D"),
    xmin = c(0, 0.5, 10, 3),
    xmax = c(1, 1.5, 11, 4),
    ymin = c(0, 0, 0, 0),
    ymax = c(1, 1, 1, 1),
    Resolution = c("4m", "8m", "2m", "16m"),
    UTM = c("18", "18", "19", "18"),
    Delivered_Date = c(
      "2024-01-01 00:00:00",
      "2025-01-01 00:00:00",
      "2024-06-01 00:00:00",
      "2023-01-01 00:00:00"
    ),
    base_value = c(4, 8, 2, 16),
    stringsAsFactors = FALSE
  )

  geotiff <- character(nrow(specs))
  rat <- character(nrow(specs))
  geotiff_sha <- character(nrow(specs))
  rat_sha <- character(nrow(specs))

  polys <- vector("list", nrow(specs))
  for (i in seq_len(nrow(specs))) {
    tile_dir <- file.path(assets, specs$tile[i])
    dir.create(tile_dir, recursive = TRUE, showWarnings = FALSE)
    tif <- file.path(tile_dir, paste0("BlueTopo_", specs$tile[i], ".tiff"))
    aux <- paste0(tif, ".aux.xml")
    r <- terra::rast(
      nrows = 2,
      ncols = 2,
      nlyrs = 3,
      xmin = specs$xmin[i],
      xmax = specs$xmax[i],
      ymin = specs$ymin[i],
      ymax = specs$ymax[i],
      crs = "EPSG:4326"
    )
    terra::values(r) <- cbind(
      rep(specs$base_value[i], terra::ncell(r)),
      rep(specs$base_value[i] / 10, terra::ncell(r)),
      rep(i, terra::ncell(r))
    )
    names(r) <- c("Elevation", "Uncertainty", "Contributor")
    terra::writeRaster(r, tif, overwrite = TRUE, filetype = "GTiff")
    writeLines(
      c(
        "<PAMDataset>",
        "  <Metadata domain=\"BLUE_TOPO_TEST\">",
        sprintf("    <MDI key=\"tile\">%s</MDI>", specs$tile[i]),
        "  </Metadata>",
        "</PAMDataset>"
      ),
      aux,
      useBytes = TRUE
    )
    geotiff[i] <- .bt_file_url(tif)
    rat[i] <- .bt_file_url(aux)
    geotiff_sha[i] <- .bt_sha256_file(tif)
    rat_sha[i] <- .bt_sha256_file(aux)
    polys[[i]] <- terra::as.polygons(
      terra::ext(specs$xmin[i], specs$xmax[i], specs$ymin[i], specs$ymax[i]),
      crs = "EPSG:4326"
    )
  }

  v <- do.call(rbind, polys)
  v$tile <- specs$tile
  v$GeoTIFF_Link <- geotiff
  v$RAT_Link <- rat
  v$Delivered_Date <- specs$Delivered_Date
  v$Resolution <- specs$Resolution
  v$UTM <- specs$UTM
  v$GeoTIFF_SHA256_Checksum <- geotiff_sha
  v$RAT_SHA256_Checksum <- rat_sha

  catalog <- file.path(root, "BlueTopo_Tile_Scheme_20260101_000000.gpkg")
  terra::writeVector(v, catalog, filetype = "GPKG", layer = "BlueTopo_Tile_Scheme_fixture", overwrite = TRUE)

  list(
    root = root,
    catalog = catalog,
    aoi = c(0, 0, 1.5, 1),
    aoi_left = c(0, 0, 1, 1),
    cache = file.path(root, "cache"),
    downloads = file.path(root, "downloads")
  )
}

with_bt_fixture <- function(code) {
  fixture <- make_bt_fixture()
  assign("fixture", fixture, envir = parent.frame())
  withr::local_options(
    bluertopo.catalog.path = fixture$catalog,
    bluertopo.allow_test_hosts = TRUE,
    bluertopo.cache_dir = fixture$cache,
    .local_envir = parent.frame()
  )
  eval(substitute(code), envir = parent.frame())
}
