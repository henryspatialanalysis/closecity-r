# Nearby POIs and their travel time from a block

Every nearby POI and its travel time from a block, one row per (POI,
mode). Paginated: loop it with
[`close_records()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_records.md).
Metered per returned row.

## Usage

``` r
close_block_pois(
  client,
  geoid,
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

- geoid:

  15-digit census block GEOID.

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

  Opaque keyset cursor from a previous page's `next_cursor`; normally
  you use
  [`close_records()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_records.md)
  instead of setting this by hand.

## Value

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

## See also

Other block endpoints:
[`close_block_summary()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_block_summary.md)
