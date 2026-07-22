# Convert a Close reply to an sf object

Detects the geometry from the payload. POI replies (from
`$pois_search()`, `$block_pois()`, `$point_pois()`, `$poi()`,
`$places()`) become points from their `lat`/`lon`. An isochrone reply
with `format = "geojson"` becomes polygons. Block replies
(`$blocks_query()`, `$place_blocks()`, `$poi_catchment()`, isochrone
`format = "blocks"`) carry only GEOIDs, so the block boundaries are
joined from `block_geometry`, or downloaded with `tigris` when
`fetch = TRUE`.

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

  (`close_reply`)  
  A reply, or the same list shape.

- block_geometry:

  (`sf`, default NULL)  
  Block boundaries with a `geoid_col` column, joined to block replies on
  the 15-digit GEOID.

- geoid_col:

  (`character(1)`, default `'GEOID20'`)  
  Name of the GEOID column in `block_geometry` (TIGER 2020 blocks).

- crs:

  (default `4326`)  
  Coordinate reference system for point and polygon geometry.

- fetch:

  (`logical(1)`, default FALSE)  
  If `TRUE` and `block_geometry` is `NULL`, download the needed TIGER
  blocks with `tigris` (inferring state and county from the GEOIDs).

## Value

An sf data frame. Metering and envelope metadata are attached as
attributes.

## Examples

``` r
if (FALSE) { # \dontrun{
close <- close_client(output = 'raw')
close_as_sf(close$pois_search(lat = 41.82, lon = -71.41, radius_m = 1500))
} # }
```
