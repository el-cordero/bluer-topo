# Clear package-owned cache content

Deletes only the configured `bluertopo` package cache after path
safeguards.

## Usage

``` r
bluertopo_cache_clear(
  cache_dir = bluertopo_cache_dir(),
  confirm = interactive()
)
```

## Arguments

- cache_dir:

  Length-one character path to a package-owned cache directory.

- confirm:

  A length-one logical. Must be `TRUE` in noninteractive sessions.

## Value

A one-row data frame with `cache_dir`, `removed_files`, and
`removed_bytes` columns.

## Examples

``` r
# \donttest{
bluertopo_cache_clear(confirm = TRUE)
#> <bluertopo_cache_clear>
#>   cache_dir: /tmp/RtmpzH0oWC/bluertopo-cache 
#>   removed_files: 2 
#>   removed_bytes: 6247341 
# }
```
