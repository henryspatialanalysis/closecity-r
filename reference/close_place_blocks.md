# Per-block travel times for a whole place

Per-block travel times for every census block in a place (city/town), by
place GEOID, one row per (block, category, mode). Paginated; loop with
[`close_records()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_records.md).
Metered per returned row.

## Usage

``` r
close_place_blocks(
  client,
  geoid,
  mode = NULL,
  type = NULL,
  include_population = NULL,
  limit = NULL,
  cursor = NULL
)
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- geoid:

  Census place GEOID.

- mode:

  Mode label(s) to filter by.

- type:

  Destination type id(s) to filter by.

- include_population:

  Add each block's population to its rows.

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

Other areal endpoints:
[`close_blocks_query()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_blocks_query.md)
