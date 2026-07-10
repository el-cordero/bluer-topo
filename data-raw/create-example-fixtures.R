dir.create(file.path("inst", "extdata"), recursive = TRUE, showWarnings = FALSE)
root <- file.path("inst", "extdata", "examples")
if (dir.exists(root)) {
  unlink(root, recursive = TRUE, force = TRUE)
}
dir.create(file.path(root, "catalog"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(root, "tiles"), recursive = TRUE, showWarnings = FALSE)

poly_from_bbox <- function(xmin, ymin, xmax, ymax, crs = "EPSG:4326") {
  terra::as.polygons(terra::ext(xmin, xmax, ymin, ymax), crs = crs)
}

web_mercator_bbox <- function(xmin, ymin, xmax, ymax) {
  p <- poly_from_bbox(xmin, ymin, xmax, ymax)
  terra::ext(terra::project(p, "EPSG:3857"))
}

write_rat <- function(path, tile, contributors) {
  rows <- unlist(lapply(seq_len(nrow(contributors)), function(i) {
    sprintf(
      paste0(
        "    <Contributor id=\"%s\" source_survey_id=\"%s\" ",
        "source_institution=\"%s\" source_type=\"%s\" />"
      ),
      contributors$contributor_id[i],
      contributors$source_survey_id[i],
      contributors$source_institution[i],
      contributors$source_type[i]
    )
  }))
  table_rows <- unlist(lapply(seq_len(nrow(contributors)), function(i) {
    sprintf(
      paste0(
        "    <Row index=\"%d\"><F>%s</F><F>%s</F><F>%s</F><F>%s</F></Row>"
      ),
      i - 1L,
      contributors$contributor_id[i],
      contributors$source_survey_id[i],
      contributors$source_institution[i],
      contributors$source_type[i]
    )
  }))
  writeLines(
    c(
      "<PAMDataset>",
      "  <Metadata domain=\"BLUE_TOPO_SYNTHETIC_FIXTURE\">",
      sprintf("    <MDI key=\"tile\">%s</MDI>", tile),
      "    <MDI key=\"label\">Synthetic miniature BlueTopo fixture for package demonstration.</MDI>",
      "    <MDI key=\"not_for_navigation\">true</MDI>",
      "    <MDI key=\"vertical_datum_conversion\">none</MDI>",
      "  </Metadata>",
      "  <Contributors>",
      rows,
      "  </Contributors>",
      "  <GDALRasterAttributeTable>",
      "    <FieldDefn index=\"0\"><Name>contributor_id</Name><Type>0</Type><Usage>0</Usage></FieldDefn>",
      "    <FieldDefn index=\"1\"><Name>source_survey_id</Name><Type>2</Type><Usage>0</Usage></FieldDefn>",
      "    <FieldDefn index=\"2\"><Name>source_institution</Name><Type>2</Type><Usage>0</Usage></FieldDefn>",
      "    <FieldDefn index=\"3\"><Name>source_type</Name><Type>2</Type><Usage>0</Usage></FieldDefn>",
      table_rows,
      "  </GDALRasterAttributeTable>",
      "</PAMDataset>"
    ),
    path,
    useBytes = TRUE
  )
}

write_tile <- function(tile, bbox, crs, nrows, ncols, base_elevation, uncertainty, contributors) {
  tile_dir <- file.path(root, "tiles", tile)
  dir.create(tile_dir, recursive = TRUE, showWarnings = FALSE)
  tif <- file.path(tile_dir, paste0("BlueTopo_", tile, ".tiff"))
  aux <- paste0(tif, ".aux.xml")
  raster_ext <- if (identical(crs, "EPSG:3857")) {
    web_mercator_bbox(bbox[1], bbox[2], bbox[3], bbox[4])
  } else {
    terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])
  }
  r <- terra::rast(
    nrows = nrows,
    ncols = ncols,
    nlyrs = 3,
    ext = raster_ext,
    crs = crs
  )
  cell <- seq_len(terra::ncell(r))
  elevation <- base_elevation + rep(seq_len(nrows), each = ncols) * 0.8 + rep(seq_len(ncols), nrows) * 0.4
  uncertainty_values <- rep(uncertainty, terra::ncell(r)) + (cell %% 3) * 0.05
  contributor_values <- rep(contributors$contributor_id, length.out = terra::ncell(r))
  terra::values(r) <- cbind(elevation, uncertainty_values, contributor_values)
  names(r) <- c("Elevation", "Uncertainty", "Contributor")
  terra::writeRaster(r, tif, overwrite = TRUE, filetype = "GTiff", datatype = "FLT4S")
  write_rat(aux, tile, contributors)
  list(
    tif = tif,
    aux = aux,
    geotiff_link = file.path("..", "tiles", tile, basename(tif)),
    rat_link = file.path("..", "tiles", tile, basename(aux)),
    geotiff_sha = digest::digest(file = tif, algo = "sha256", serialize = FALSE),
    rat_sha = digest::digest(file = aux, algo = "sha256", serialize = FALSE)
  )
}

contributors <- list(
  TILE_FINE_A = data.frame(
    contributor_id = c(101L, 102L),
    source_survey_id = c("SYN_FINE_A_2024_A", "SYN_FINE_A_2024_B"),
    source_institution = c("Synthetic Coastal Survey Office", "Synthetic University Lab"),
    source_type = c("synthetic multibeam", "synthetic lidar"),
    stringsAsFactors = FALSE
  ),
  TILE_COARSE_B = data.frame(
    contributor_id = c(201L, 202L),
    source_survey_id = c("SYN_COARSE_B_2023_A", "SYN_COARSE_B_2023_B"),
    source_institution = c("Synthetic NOAA Partner", "Synthetic Coastal Survey Office"),
    source_type = c("synthetic chart compilation", "synthetic multibeam"),
    stringsAsFactors = FALSE
  ),
  TILE_UTM_C = data.frame(
    contributor_id = c(301L, 302L),
    source_survey_id = c("SYN_UTM_C_2022_A", "SYN_UTM_C_2022_B"),
    source_institution = c("Synthetic Hydrographic Branch", "Synthetic Academic Partner"),
    source_type = c("synthetic multibeam", "synthetic backscatter classification"),
    stringsAsFactors = FALSE
  )
)

specs <- data.frame(
  tile = c("TILE_FINE_A", "TILE_COARSE_B", "TILE_UTM_C"),
  xmin = c(0.00, 0.60, 1.15),
  ymin = c(0.00, 0.10, 0.05),
  xmax = c(1.00, 1.60, 2.05),
  ymax = c(1.00, 1.10, 0.95),
  crs = c("EPSG:4326", "EPSG:4326", "EPSG:3857"),
  nrows = c(4L, 2L, 3L),
  ncols = c(4L, 2L, 3L),
  Resolution = c("4m", "8m", "16m"),
  UTM = c("18", "18", "19"),
  Delivered_Date = c(
    "2026-01-15 00:00:00",
    "2025-07-15 00:00:00",
    "2024-10-15 00:00:00"
  ),
  base_elevation = c(-18, -25, -33),
  uncertainty = c(0.35, 0.65, 0.95),
  stringsAsFactors = FALSE
)

tiles <- vector("list", nrow(specs))
polys <- vector("list", nrow(specs))
for (i in seq_len(nrow(specs))) {
  tile <- specs$tile[i]
  tiles[[i]] <- write_tile(
    tile = tile,
    bbox = unlist(specs[i, c("xmin", "ymin", "xmax", "ymax")]),
    crs = specs$crs[i],
    nrows = specs$nrows[i],
    ncols = specs$ncols[i],
    base_elevation = specs$base_elevation[i],
    uncertainty = specs$uncertainty[i],
    contributors = contributors[[tile]]
  )
  polys[[i]] <- poly_from_bbox(specs$xmin[i], specs$ymin[i], specs$xmax[i], specs$ymax[i])
}

catalog <- do.call(rbind, polys)
catalog$tile <- specs$tile
catalog$Delivered_Date <- specs$Delivered_Date
catalog$UTM <- specs$UTM
catalog$Resolution <- specs$Resolution
catalog$GeoTIFF_Link <- vapply(tiles, `[[`, "", "geotiff_link")
catalog$GeoTIFF_SHA256_Checksum <- vapply(tiles, `[[`, "", "geotiff_sha")
catalog$RAT_Link <- vapply(tiles, `[[`, "", "rat_link")
catalog$RAT_SHA256_Checksum <- vapply(tiles, `[[`, "", "rat_sha")

catalog_path <- file.path(root, "catalog", "BlueTopo_Tile_Scheme_example.gpkg")
if (file.exists(catalog_path)) {
  unlink(catalog_path, force = TRUE)
}
terra::writeVector(
  catalog,
  catalog_path,
  filetype = "GPKG",
  layer = "BlueTopo_Tile_Scheme_example",
  overwrite = TRUE
)

aoi <- poly_from_bbox(0.25, 0.15, 1.75, 0.90)
aoi$name <- "Synthetic miniature BlueTopo fixture AOI"
aoi_path <- file.path(root, "aoi.gpkg")
if (file.exists(aoi_path)) {
  unlink(aoi_path, force = TRUE)
}
terra::writeVector(aoi, aoi_path, filetype = "GPKG", layer = "aoi", overwrite = TRUE)

message("Wrote example fixtures to ", normalizePath(root, mustWork = TRUE))
