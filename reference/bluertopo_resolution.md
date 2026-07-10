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

  Resolution strategy.

- value:

  A single meter value used by target-like strategies.

- values:

  One or more exact meter values.

- min_m, max_m:

  Inclusive meter bounds.

- n:

  Rank or count for rank-based strategies.

- scope:

  `"global"`. `"local"` is reserved for a future AOI-local ranking
  implementation and is rejected in this release.

- tie:

  Tie preference for nearest/target strategies.

- prefer:

  Preference direction for coverage/rank strategies.

- strict:

  Whether fallback must remain inside hard constraints.

- min_coverage:

  Coverage target for coverage-oriented strategies.

## Value

A `bluertopo_resolution` S3 object.

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
