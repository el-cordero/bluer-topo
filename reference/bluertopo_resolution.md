# Construct a BlueTopo native-resolution policy

`bluertopo_resolution()` creates an explicit native source-tile
selection policy. Smaller meter values are finer source resolution. This
object never requests output resampling; use `output_resolution` in
[`bluertopo()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo.md)
for an explicit output grid.

## Usage

``` r
bluertopo_resolution(
  strategy,
  value = NULL,
  values = NULL,
  min_m = NULL,
  max_m = NULL,
  n = NULL,
  scope = "global",
  tie = "finer",
  prefer = "finest",
  strict = TRUE,
  min_coverage = 1
)
```

## Arguments

- strategy:

  A character scalar naming a strategy: `"native"`, `"finest"`,
  `"coarsest"`, `"best_available"`, `"coarsest_available"`,
  `"dominant"`, `"exact"`, `"nearest"`, `"finer_or_equal"`,
  `"coarser_or_equal"`, `"between"`, `"rank"`, `"finest_n"`,
  `"coarsest_n"`, `"target"`, or `"coverage"`. `"highest"` and
  `"lowest"` are aliases for `"finest"` and `"coarsest"`.

- value:

  `NULL` or one positive numeric native cell size in meters. Required by
  `"nearest"`, `"target"`, `"finer_or_equal"`, and `"coarser_or_equal"`.

- values:

  `NULL` or a numeric vector of positive native cell sizes in meters.
  Required by `"exact"`.

- min_m, max_m:

  `NULL` or positive numeric inclusive bounds in meters. Both are
  required by `"between"`.

- n:

  `NULL` or a positive whole number used by `"rank"`, `"finest_n"`, and
  `"coarsest_n"`.

- scope:

  A character scalar. Only `"global"` is implemented; `"local"` is
  reserved and rejected.

- tie:

  A character scalar, `"finer"` or `"coarser"`, used when two native
  resolutions are equally close to a target.

- prefer:

  A character scalar, `"finest"` or `"coarsest"`, controlling ordering
  for coverage and rank strategies.

- strict:

  A length-one logical. If `TRUE`, coverage fallback stays within hard
  resolution constraints.

- min_coverage:

  A numeric value from 0 through 1 used by the `"coverage"` strategy.

## Value

A `bluertopo_resolution` S3 object containing the normalized policy
fields. Pass it to the `resolution` argument of
[`bluertopo()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo.md),
[`bluertopo_tiles()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo_tiles.md),
or
[`bluertopo_download()`](https://el-cordero.github.io/bluer-topo/reference/bluertopo_download.md).

## Examples

``` r
bluertopo_resolution("nearest", value = 10, tie = "finer")
#> <bluertopo_resolution>
#>   strategy: nearest 
#>   value: 10 m
#>   scope: global 
#>   strict: TRUE 
bluertopo_resolution("between", min_m = 4, max_m = 16)
#> <bluertopo_resolution>
#>   strategy: between 
#>   bounds: 4 to 16 m
#>   scope: global 
#>   strict: TRUE 
```
