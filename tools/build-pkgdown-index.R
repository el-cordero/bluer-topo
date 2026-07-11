#!/usr/bin/env Rscript

if (!identical(tolower(Sys.getenv("BLUERTOPO_BUILD_REAL_EXAMPLES")), "true")) {
  stop(
    "Set BLUERTOPO_BUILD_REAL_EXAMPLES=true before building the NOAA-backed pkgdown homepage.",
    call. = FALSE
  )
}

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("Install rmarkdown to render index.Rmd.", call. = FALSE)
}

rmarkdown::render(
  "index.Rmd",
  output_file = "index.md",
  quiet = FALSE,
  clean = TRUE,
  envir = new.env(parent = globalenv())
)

if (file.exists(file.path("pkgdown", "pkgdown.yml"))) {
  file.copy("index.md", file.path("pkgdown", "index.md"), overwrite = TRUE)
}
