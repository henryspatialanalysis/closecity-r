# Nearby POIs and their travel time from a point

Like
[`close_block_pois()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_block_pois.md),
but from the block containing a lat/lon. Paginated; loop with
[`close_records()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_records.md).
Metered per returned row.

## Usage

``` r
close_point_pois(
  client,
  lat,
  lon,
  mode = NULL,
  type = NULL,
  dest_id = NULL,
  max_minutes = NULL,
  limit = NULL,
  cursor = NULL
)
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- lat:

  Latitude (WGS84).

- lon:

  Longitude (WGS84).

- mode:

  Mode label(s) to filter by.

- type:

  Destination type id(s) to filter by.

- dest_id:

  Restrict to specific destination id(s).

- max_minutes:

  Cap travel time (\<= 30).

- limit:

  Page size (\<= 1000).

- cursor:

  Opaque keyset cursor; normally use
  [`close_records()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_records.md)
  instead.

## Value

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

## See also

Other point endpoints:
[`close_point_summary()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_point_summary.md)
