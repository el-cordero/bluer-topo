## Resubmission

This is a resubmission. In this version I have:

- expanded NOAA as "National Oceanic and Atmospheric Administration (NOAA)"
  on first use in the `Description` field;
- added angle-bracketed links in the `Description` field for the BlueTopo web
  service and product documentation;
- removed all `\dontrun{}` directives, left fast local examples unwrapped, and
  used `\donttest{}` only for examples that access the BlueTopo web service;
- made the download destination an explicitly required argument with no
  default; and
- ensured that default package caching and all writing examples, vignettes, and
  tests use `tempdir()` or `tempfile()` rather than the user's home directory,
  package directory, or working directory.

Normal tests are network-free. Live integration tests are opt-in through
environment variables.

## R CMD check results

Validation of the resubmission tarball on 2026-07-21:

- `R CMD check --as-cran bluertopo_0.0.1.tar.gz`: 0 errors, 0 warnings,
  3 notes.
- `Rscript -e 'testthat::test_local()'`: 280 passed; the two live-network
  integration tests were skipped as intended.
- `Rscript -e 'lintr::lint_package()'`: no lints found.
- `Rscript -e 'urlchecker::url_check()'`: all 16 URLs passed.

The three check notes are environmental or expected for a new submission:

```text
New submission
unable to verify current time
Skipping checking HTML validation: 'tidy' doesn't look like recent enough HTML Tidy.
```
