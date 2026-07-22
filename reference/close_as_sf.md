# Convert a Close reply to an `sf` object

Detects the geometry from the payload: POI replies (`close_pois_search`,
`close_block_pois`, `close_point_pois`, `close_poi`) become **points**
from their `lat`/`lon`; an isochrone
`close_isochrone(format = "geojson")` reply becomes **polygons**; block
replies (`close_block_summary`, `close_blocks_query`,
`close_place_blocks`, `close_poi_catchment`) carry only GEOIDs, so you
join census-block boundaries via `block_geometry` (an `sf` keyed on
`geoid_col`) or let it fetch them with `tigris` when `fetch = TRUE`.

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

  Optional `sf` of block boundaries with a `geoid_col` column, joined to
  block replies on the 15-digit GEOID.

- geoid_col:

  Name of the GEOID column in `block_geometry`. Default `"GEOID20"`
  (TIGER 2020 blocks).

- crs:

  Coordinate reference system for point/polygon geometry. Default 4326.

- fetch:

  If `TRUE` and `block_geometry` is `NULL`, pull the needed TIGER blocks
  with `tigris` (inferring state/county from the GEOIDs).

## Value

An `sf` data frame.

## Examples

``` r
if (FALSE) { # \dontrun{
close_as_sf(close_pois_search(client, lat = 41.82, lon = -71.41, radius_m = 1500))
close_as_sf(close_isochrone(client, block = "440070036001010", minutes = 15))
} # }
```
