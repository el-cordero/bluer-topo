## R CMD check results

This package is pre-release and not yet submitted to CRAN.

Validation on 2026-07-10:

- `Rscript -e 'testthat::test_local()'`: 156 passed, 2 skipped opt-in
  live-network tests.
- `BLUERTOPO_RUN_REAL_EXAMPLE_TESTS=true Rscript -e 'testthat::test_local(filter = "examples")'`:
  85 passed.
- `Rscript -e 'lintr::lint_package()'`: no lints found.
- `BLUERTOPO_BUILD_REAL_EXAMPLES=true Rscript -e 'pkgdown::build_site(new_process = FALSE, install = TRUE)'`:
  succeeded locally and rendered the Examples section from real NOAA BlueTopo
  assets.
- `Rscript -e 'pkgdown::deploy_to_branch(new_process = FALSE, install = TRUE)'`:
  succeeded and pushed the site to `gh-pages`.
- GitHub Pages is configured from `gh-pages` at `/`, and
  `https://el-cordero.github.io/bluer-topo/` and
  `https://el-cordero.github.io/bluer-topo/articles/examples.html` return
  HTTP 200.
- `R CMD build .`: succeeded.
- `R CMD check --as-cran bluertopo_0.0.1.tar.gz`: 0 errors, 0 warnings,
  1 note.

The remaining NOTE is expected for a first CRAN submission:

```text
New submission
```

Network access is disabled during normal examples and tests. Public pkgdown
examples are real-data renders only when `BLUERTOPO_BUILD_REAL_EXAMPLES=true`.
Live NOAA integration tests are opt-in through environment variables.
