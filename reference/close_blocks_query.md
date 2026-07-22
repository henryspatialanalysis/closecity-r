# Per-block travel times within a polygon or radius

Blocks within a GeoJSON `polygon` or a `center` + `radius_m`, one row
per (block, category, mode). Paginated with the cursor carried in the
request body. Metered per returned row.

## Usage

``` r
close_blocks_query(
  client,
  polygon = NULL,
  center = NULL,
  radius_m = NULL,
  type = NULL,
  mode = NULL,
  include_population = NULL,
  limit = NULL,
  cursor = NULL
)
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- polygon:

  A GeoJSON Polygon/MultiPolygon (as a list).

- center:

  A `list(lon =, lat =)` centre, used with `radius_m`.

- radius_m:

  Radius in metres (\<= 28000).

- type:

  Destination type id(s) to filter by.

- mode:

  Mode label(s) to filter by.

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
[`close_place_blocks()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_place_blocks.md)
