# A POI's catchment (blocks that can reach it)

Every census block that can reach a POI, one row per (block, mode).
Paginated; loop with
[`close_records()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_records.md).
Metered per returned row.

## Usage

``` r
close_poi_catchment(
  client,
  dest_id,
  mode = NULL,
  block = NULL,
  max_minutes = NULL,
  limit = NULL,
  cursor = NULL
)
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- dest_id:

  Destination id.

- mode:

  Mode label(s) to filter by.

- block:

  Restrict to specific block id(s).

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

Other POI endpoints:
[`close_poi()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_poi.md),
[`close_pois_search()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_pois_search.md)
