# Convert a Close reply to an sf object

Detects the geometry from the payload. POI replies (from
`$pois_search()`, `$block_pois()`, `$point_pois()`, `$poi()`) become
points from their `lat`/`lon`. An isochrone reply with
`format = "geojson"` becomes polygons. Block replies (`$blocks_query()`,
`$place_blocks()`, `$poi_catchment()`) carry only GEOIDs, so the block
boundaries are joined from `block_geometry`, or downloaded with `tigris`
when `fetch = TRUE`.

## Usage

``` r
close_as_sf(
  x,
  block_geometry = NULL,
  geoid_col = "GEOID20",
  crs = 4326,
  fetch = FALSE
)
```

## Arguments

- x:

  A `close_reply` (or the same list shape).

- block_geometry:

  Optional sf of block boundaries with a `geoid_col` column, joined to
  block replies on the 15-digit GEOID.

- geoid_col:

  Name of the GEOID column in `block_geometry`. Default `"GEOID20"`
  (TIGER 2020 blocks).

- crs:

  Coordinate reference system for point and polygon geometry. Default
  4326.

- fetch:

  If `TRUE` and `block_geometry` is `NULL`, download the needed TIGER
  blocks with `tigris` (inferring state and county from the GEOIDs).

## Value

An sf data frame.

## Examples

``` r
if (FALSE) { # \dontrun{
close <- close_client(spatial = FALSE)
close_as_sf(close$pois_search(lat = 41.82, lon = -71.41, radius_m = 1500))
} # }
```
