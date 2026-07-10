.bt_bucket_url <- "https://noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com"
.bt_bucket_host <- "noaa-ocs-nationalbathymetry-pds.s3.amazonaws.com"
.bt_tile_scheme_prefix <- "BlueTopo/_BlueTopo_Tile_Scheme/BlueTopo_Tile_Scheme"
.bt_catalog_ttl_seconds <- 24 * 60 * 60
.bt_behavior_version <- "2026-07-10"
.bt_layer_names <- c("elevation", "uncertainty", "contributor")
.bt_layer_numbers <- c(elevation = 1L, uncertainty = 2L, contributor = 3L)
.bt_expected_catalog_fields <- c(
  "tile",
  "GeoTIFF_Link",
  "RAT_Link",
  "Delivered_Date",
  "Resolution",
  "UTM",
  "GeoTIFF_SHA256_Checksum",
  "RAT_SHA256_Checksum"
)
.bt_catalog_field_map <- c(
  tile_id = "tile",
  geotiff_url = "GeoTIFF_Link",
  rat_url = "RAT_Link",
  delivered_date = "Delivered_Date",
  resolution_m = "Resolution",
  utm_zone = "UTM",
  geotiff_sha256 = "GeoTIFF_SHA256_Checksum",
  rat_sha256 = "RAT_SHA256_Checksum"
)
.bt_not_for_navigation <- paste(
  "NOAA BlueTopo is not for navigation.",
  "bluertopo performs no vertical-datum conversion."
)
