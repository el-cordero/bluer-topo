# Contributing

Thanks for helping improve `bluertopo`.

Please keep contributions inside the package’s narrow scope:
discovering, downloading, verifying, and opening NOAA BlueTopo assets
with `terra`.

Before opening a pull request:

1.  Run `devtools::document()`.
2.  Run `devtools::test()`.
3.  Run `devtools::check(args = "--as-cran")` when possible.
4.  Keep normal tests network-free.

Do not add features that imply navigation fitness, vertical-datum
conversion, terrain derivatives, interpolation, permanent mosaics, or
non-BlueTopo data products.
