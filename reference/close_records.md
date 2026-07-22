# Collect every record from a paginated endpoint

Repeatedly calls a paginated endpoint function, following `next_cursor`
until it is null, and returns all records combined. Each page is metered
independently.

## Usage

``` r
close_records(fetch, ...)
```

## Arguments

- fetch:

  A paginated endpoint function (e.g.
  [`close_pois_search()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_pois_search.md)).

- ...:

  Arguments forwarded to `fetch` (starting with the client).

## Value

A list of record lists across all pages.

## Examples

``` r
if (FALSE) { # \dontrun{
close_records(close_pois_search, client, lat = 44.05, lon = -123.09,
              radius_m = 2000)
} # }
```
