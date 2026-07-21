# Locate the bluertopo cache directory

Returns the configured package cache directory without creating it.

## Usage

``` r
bluertopo_cache_dir()
```

## Value

A length-one character vector containing the normalized cache path.

## Details

The default is a session-temporary directory so routine package calls do
not write to the user's home directory. Set
`options(bluertopo.cache_dir = ...)` when a persistent cache is wanted.

## Examples

``` r
bluertopo_cache_dir()
#> [1] "/tmp/RtmpILxmbU/bluertopo-cache"
```
