# bluertopo Assessment and Remediation Ledger

Date: 2026-07-10

Repository: `el-cordero/bluer-topo`

This ledger records what was audited, what was remediated in this pass, and
which architectural requests remain intentionally deferred. Deferred items are
not treated as supported behavior by the current API.

## Completed in this pass

### Repository and package identity

Status: REMEDIATED

Evidence:

- `DESCRIPTION` now identifies Elvin Cordero as author, maintainer, and
  copyright holder, advertises `https://el-cordero.github.io/bluer-topo/`, and
  points issues to `https://github.com/el-cordero/bluer-topo/issues`.
- `CITATION.cff` and `inst/CITATION` use the same maintainer identity and cite
  NOAA BlueTopo at `https://nauticalcharts.noaa.gov/data/bluetopo.html`.
- `R/utils.R` uses the canonical repository URL in the HTTP user agent.
- `_pkgdown.yml` follows the `blueterra` Bootstrap 5/Flatly visual system,
  uses local system fonts for network-free builds, and targets the GitHub Pages
  URL.

### CI and website readiness

Status: REMEDIATED

Evidence:

- `.github/workflows/R-CMD-check.yaml` now runs `roxygen2::roxygenise()` and
  fails on documentation drift with `git diff --exit-code`.
- `.github/workflows/pkgdown.yaml` builds the site and deploys it through
  `pkgdown::deploy_to_branch()` using `GITHUB_TOKEN`.
- `_pkgdown.yml` uses `destination: pkgdown`; generated site output is ignored
  through `.gitignore` and `.Rbuildignore`.
- `README.Rmd` is the README source; `README.md` is regenerated from it during
  validation.

### API honesty for unsupported modes

Status: REMEDIATED

Evidence:

- `R/download.R` rejects `workers > 1` instead of accepting a value that has no
  effect. Current supported values are `NULL` and `1`.
- `R/resolution.R` rejects `scope = "local"` instead of accepting a local-scope
  ranking mode that has not been implemented.
- `R/resolution.R` validates rank/count `n` values as positive whole numbers
  instead of silently truncating fractional values.
- Regression coverage: `tests/testthat/test-resolution.R` and
  `tests/testthat/test-tiles-download-terra.R`.

### Verification semantics

Status: REMEDIATED

Evidence:

- `R/download.R` now rejects `verify = "size"` before transfer when the plan has
  no trustworthy expected byte counts.
- SHA-256 remains the default verification mode.
- Regression coverage: `tests/testthat/test-tiles-download-terra.R`.

### Cache safety

Status: REMEDIATED

Evidence:

- `R/cache.R` writes and validates `.bluertopo-cache.json` before package-owned
  cache content is cleared.
- `bluertopo_cache_clear()` clears only the configured package cache, refuses
  unmarked roots, refuses symlinked cache paths, refuses suspicious roots, and
  removes only known package-owned children: `catalog`, `tiles`, `vrt`,
  `manifests`, and `locks`.
- The return value now includes `removed_files`, `removed_bytes`, and
  `failed_paths`.
- Regression coverage: `tests/testthat/test-cache.R`.

### Transactional file installation

Status: REMEDIATED

Evidence:

- `R/utils.R` adds `.bt_install_file_transactionally()`, which validates staged
  files, backs up an existing destination, installs the staged file, and restores
  the previous destination on install failure.
- JSON, CSV, cached catalog replacement, and downloaded assets now use the
  transactional helper.
- Regression coverage: `tests/testthat/test-cache.R`.

### Query-addressed manifests

Status: REMEDIATED

Evidence:

- `R/tiles.R` records a deterministic tile-query hash before download.
- `R/manifest.R` still writes the fixed manifest filenames for user convenience
  and also writes query-addressed CSV/JSON manifest copies under `manifests/`.
- Regression coverage: `tests/testthat/test-tiles-download-terra.R`.

### Coverage target routing

Status: REMEDIATED

Evidence:

- `R/coverage.R` now uses the coverage target stored in
  `bluertopo_resolution("coverage", min_coverage = ...)` for coverage-strategy
  selections.
- Coverage diagnostics record whether the target came from the resolution
  policy or the function-level `min_coverage` argument.
- Regression coverage: `tests/testthat/test-tiles-download-terra.R`.

### Download-to-tile ordering

Status: REMEDIATED

Evidence:

- `R/bluertopo.R` matches downloaded GeoTIFF rows back to selected tiles by the
  pair `(tile_id, source_url)` instead of tile ID alone, reducing ambiguity when
  duplicate tile identifiers appear in a catalog.

### User-facing documentation

Status: REMEDIATED

Evidence:

- `README.Rmd` and `README.md` now cover installation, basic usage, original
  downloads, native resolution policies, mixed source grids, cache operations,
  verification semantics, and NOAA/no-navigation disclaimers.
- Vignettes in `vignettes/` were expanded into practical guides for getting
  BlueTopo, resolution policies, downloads/cache/reproducibility, mixed UTM
  collections, and layers/RAT metadata.
- The top-level pkgdown Examples section now renders actual NOAA BlueTopo tables
  and figures when `BLUERTOPO_BUILD_REAL_EXAMPLES=true`; normal tests keep using
  deterministic synthetic fixtures without live NOAA downloads.

## Intentionally deferred items

### Bounded parallel curl-multi downloader

Status: INTENTIONALLY DEFERRED

Current API behavior:

- `workers = NULL` and `workers = 1` are supported.
- `workers > 1` raises `bluertopo_error_download`.

Reason:

- True parallel transfer needs a bounded curl-multi scheduler with per-asset
  retry state, lock coordination, partial-file cleanup, manifest row ordering,
  and deterministic error aggregation. Accepting `workers > 1` before that work
  exists would mislead users.

Future implementation target:

- Add a curl multi pool with a fixed maximum worker count, deterministic result
  ordering, per-host politeness, and tests using a local HTTP fixture server.

### HTTP status fixture server and full retry matrix

Status: INTENTIONALLY DEFERRED

Current API behavior:

- Downloads retry transient curl failures with exponential backoff.
- Unit tests use local file URLs and fixture catalogs.

Reason:

- The repo does not yet include a local HTTP fixture server capable of simulating
  206/304/404/429/5xx behavior, range requests, ETags, redirects, and timeouts.

Future implementation target:

- Add a test-only HTTP fixture server and status-aware tests for catalog
  discovery, transfer retry, checksum failure, stale partial cleanup, and
  `on_error = "continue"` manifests.

### Local AOI-scoped resolution ranking

Status: INTENTIONALLY DEFERRED

Current API behavior:

- `scope = "global"` is supported.
- `scope = "local"` raises `bluertopo_error_resolution`.

Reason:

- AOI-local ranking should be implemented against intersection areas and
  coverage semantics for every selected tile, not as a label on the existing
  global ordering.

Future implementation target:

- Add local ranking diagnostics and tests where the same AOI intersects multiple
  resolutions unevenly.

### Full RAT parsing and contributor lookup normalization

Status: INTENTIONALLY DEFERRED

Current API behavior:

- RAT sidecar assets can be downloaded and are listed in manifests.
- Contributor values are exposed as the source raster band.

Reason:

- A stable contributor lookup requires reading real NOAA sidecar formats,
  normalizing table schemas, and preserving source provenance. The current
  fixture only proves sidecar preservation, not semantic parsing.

Future implementation target:

- Add RAT reader fixtures, contributor table output, and round-trip tests for
  source metadata.

### Advanced grid snapping and VRT grouping diagnostics

Status: INTENTIONALLY DEFERRED

Current API behavior:

- Compatible source rasters are grouped by CRS, resolution, origin, and layer
  count; incompatible groups return a `terra::SpatRasterCollection`.
- Explicit output grids are supported through `output_crs` and
  `output_resolution`.

Reason:

- Snapping output extents to a stable target grid and exposing a richer grid
  signature needs careful terra/GDAL behavior checks across projected CRSs.

Future implementation target:

- Add target-grid snapping utilities, richer VRT/grid provenance, and tests
  across mixed UTM fixtures.

### Full NOAA catalog schema drift contract

Status: INTENTIONALLY DEFERRED

Current API behavior:

- Catalog fields are validated against the expected current schema.
- A schema fingerprint is recorded in cached catalog metadata.

Reason:

- A more complete drift contract should include archived schema fixtures,
  versioned migration behavior, and compatibility notes for known historical
  catalogs.

Future implementation target:

- Add multiple catalog fixtures and a schema compatibility table with explicit
  fail/warn behavior by field.

## Validation

Validation commands and outcomes from this remediation run:

- `Rscript -e 'roxygen2::roxygenise()'`: succeeded.
- `Rscript -e 'rmarkdown::render("README.Rmd", quiet = TRUE)'`: succeeded.
  Pandoc warned that sandboxed rendering could not fetch remote badge SVGs, but
  the Markdown links were generated.
- `Rscript -e 'testthat::test_local()'`: succeeded with 156 passed and 2
  intentionally skipped live-network tests.
- `BLUERTOPO_RUN_REAL_EXAMPLE_TESTS=true Rscript -e 'testthat::test_local(filter = "examples")'`:
  succeeded with 85 passed.
- `Rscript -e 'lintr::lint_package()'`: succeeded with no lints.
- `BLUERTOPO_BUILD_REAL_EXAMPLES=true Rscript -e 'pkgdown::build_site(new_process = FALSE, install = TRUE)'`:
  succeeded after rerunning with elevated permissions because pkgdown article
  rendering uses processx/callr in this desktop sandbox. This built local site
  files with actual NOAA BlueTopo example outputs but did not itself enable or
  publish GitHub Pages.
- `Rscript -e 'pkgdown::deploy_to_branch(new_process = FALSE, install = TRUE)'`:
  succeeded and pushed the generated site to `gh-pages` with the Examples
  section.
- GitHub Pages is configured from `gh-pages` at `/`, and
  `https://el-cordero.github.io/bluer-topo/` and
  `https://el-cordero.github.io/bluer-topo/articles/examples.html` return
  HTTP 200.
- `R CMD build .`: succeeded and built `bluertopo_0.0.1.tar.gz`.
- `R CMD check --as-cran bluertopo_0.0.1.tar.gz`: 0 errors, 0 warnings,
  1 note.

Remaining check note:

```text
New submission
```

Disposition:

- This is the expected first-submission NOTE.
