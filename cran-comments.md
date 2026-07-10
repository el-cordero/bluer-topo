## R CMD check results

This package is pre-release and not yet submitted to CRAN.

Validation on 2026-07-10:

- `Rscript -e 'devtools::test()'`: 81 passed, 1 skipped live-network test.
- `Rscript -e 'lintr::lint_package()'`: no lints found.
- `Rscript -e 'pkgdown::build_site(new_process = FALSE, install = TRUE)'`:
  succeeded locally.
- `R CMD build .`: succeeded.
- `R CMD check --as-cran --no-manual bluertopo_0.0.1.tar.gz`: 0 errors,
  0 warnings, 1 note.

The remaining NOTE is expected before the pkgdown site is deployed:

```text
New submission

Found the following (possibly) invalid URLs:
  URL: https://el-cordero.github.io/bluer-topo/
    From: DESCRIPTION
          man/bluertopo-package.Rd
          inst/CITATION
    Status: 404
    Message: Not Found
```

Network access is disabled during normal examples and tests. Live NOAA
integration tests are opt-in through environment variables.
