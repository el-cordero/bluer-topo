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

  Cache directory to clear.

- confirm:

  Required as `TRUE` in noninteractive sessions.

## Value

A data frame summary with removed file count and bytes.

## Examples

``` r
# \donttest{
bluertopo_cache_clear(confirm = TRUE)
#> <bluertopo_cache_clear>
#>   cache_dir: /tmp/RtmpAdKN4v/bluertopo-cache 
#>   removed_files: 2 
#>   removed_bytes: 6247341 
# }
```
