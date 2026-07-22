# Close API client

An R6 object that holds your connection settings and gives you one
method per public route. Create it with
[`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md)
rather than calling `$new()`. Feature methods return an
[sf](https://r-spatial.github.io/sf/reference/sf.html) object when
`spatial` is TRUE (the default), or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
otherwise.

## Public fields

- `spatial`:

  (`logical(1)`)  
  Should feature methods return an sf object? Toggle any time.

## Methods

### Public methods

- [`CloseClient$new()`](#method-CloseClient-initialize)

- [`CloseClient$health()`](#method-CloseClient-health)

- [`CloseClient$last_updated()`](#method-CloseClient-last_updated)

- [`CloseClient$modes()`](#method-CloseClient-modes)

- [`CloseClient$destination_types()`](#method-CloseClient-destination_types)

- [`CloseClient$vintage()`](#method-CloseClient-vintage)

- [`CloseClient$places()`](#method-CloseClient-places)

- [`CloseClient$block_summary()`](#method-CloseClient-block_summary)

- [`CloseClient$block_pois()`](#method-CloseClient-block_pois)

- [`CloseClient$point_summary()`](#method-CloseClient-point_summary)

- [`CloseClient$point_pois()`](#method-CloseClient-point_pois)

- [`CloseClient$pois_search()`](#method-CloseClient-pois_search)

- [`CloseClient$poi()`](#method-CloseClient-poi)

- [`CloseClient$poi_catchment()`](#method-CloseClient-poi_catchment)

- [`CloseClient$blocks_query()`](#method-CloseClient-blocks_query)

- [`CloseClient$place_blocks()`](#method-CloseClient-place_blocks)

- [`CloseClient$isochrone()`](#method-CloseClient-isochrone)

- [`CloseClient$isochrone_meta()`](#method-CloseClient-isochrone_meta)

- [`CloseClient$records()`](#method-CloseClient-records)

- [`CloseClient$clone()`](#method-CloseClient-clone)

------------------------------------------------------------------------

### `CloseClient$new()`

Create a client. Prefer
[`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

#### Usage

    CloseClient$new(
      api_key = NULL,
      base_url = DEFAULT_BASE_URL,
      timeout = 30,
      spatial = TRUE
    )

#### Arguments

- `api_key`:

  Your API key, or NULL for the free routes.

- `base_url`:

  API base URL.

- `timeout`:

  Request timeout, in seconds.

- `spatial`:

  Return feature results as sf objects?

------------------------------------------------------------------------

### `CloseClient$health()`

Liveness check (free).

#### Usage

    CloseClient$health()

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$last_updated()`

Publication time of the newest data (free).

#### Usage

    CloseClient$last_updated()

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$modes()`

Travel modes and their numeric ids (free).

#### Usage

    CloseClient$modes()

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$destination_types()`

Destination-type taxonomy (free). Use it to look up the numeric `type`
ids the data routes filter on.

#### Usage

    CloseClient$destination_types()

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$vintage()`

Active version of each dataset component (free).

#### Usage

    CloseClient$vintage()

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$places()`

Look up a city or town by name (free). Each match carries its census
place GEOID and centre point.

#### Usage

    CloseClient$places(q, limit = NULL)

#### Arguments

- `q`:

  Name to search for, such as "Providence".

- `limit`:

  Most matches to return (1 to 20).

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$block_summary()`

Fastest travel time from a census block to each destination category, by
mode.

#### Usage

    CloseClient$block_summary(
      geoid,
      mode = NULL,
      type = NULL,
      if_none_match = NULL
    )

#### Arguments

- `geoid`:

  15-digit census block GEOID.

- `mode`:

  Travel mode(s) to keep: "walk", "bike", "transit".

- `type`:

  Destination type id(s) to keep.

- `if_none_match`:

  An ETag from an earlier reply, to revalidate for free.

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$block_pois()`

Nearby points of interest and their travel time from a block, one row
per (POI, mode). Read every page with `$records()`.

#### Usage

    CloseClient$block_pois(
      geoid,
      mode = NULL,
      type = NULL,
      dest_id = NULL,
      max_minutes = NULL,
      limit = NULL,
      cursor = NULL
    )

#### Arguments

- `geoid`:

  15-digit census block GEOID.

- `mode`:

  Travel mode(s) to keep.

- `type`:

  Destination type id(s) to keep.

- `dest_id`:

  Specific destination id(s) to keep.

- `max_minutes`:

  Upper bound on travel time (up to 30).

- `limit`:

  Rows per page (up to 1000).

- `cursor`:

  Page cursor from a previous reply's `next_cursor`.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `spatial` is FALSE.

------------------------------------------------------------------------

### `CloseClient$point_summary()`

Like `$block_summary()`, but from the block containing a lat/lon point.
The resolved block is echoed as `resolved_block`.

#### Usage

    CloseClient$point_summary(
      lat,
      lon,
      mode = NULL,
      type = NULL,
      if_none_match = NULL
    )

#### Arguments

- `lat`:

  Latitude.

- `lon`:

  Longitude.

- `mode`:

  Travel mode(s) to keep.

- `type`:

  Destination type id(s) to keep.

- `if_none_match`:

  An ETag to revalidate for free.

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$point_pois()`

Like `$block_pois()`, but from the block containing a lat/lon point.
Read every page with `$records()`.

#### Usage

    CloseClient$point_pois(
      lat,
      lon,
      mode = NULL,
      type = NULL,
      dest_id = NULL,
      max_minutes = NULL,
      limit = NULL,
      cursor = NULL
    )

#### Arguments

- `lat`:

  Latitude.

- `lon`:

  Longitude.

- `mode`:

  Travel mode(s) to keep.

- `type`:

  Destination type id(s) to keep.

- `dest_id`:

  Specific destination id(s) to keep.

- `max_minutes`:

  Upper bound on travel time (up to 30).

- `limit`:

  Rows per page (up to 1000).

- `cursor`:

  Page cursor.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `spatial` is FALSE.

------------------------------------------------------------------------

### `CloseClient$pois_search()`

Search points of interest by bounding box, or by a circle (`lat` +
`lon` + `radius_m`). Read every page with `$records()`.

#### Usage

    CloseClient$pois_search(
      lat = NULL,
      lon = NULL,
      radius_m = NULL,
      bbox = NULL,
      type = NULL,
      q = NULL,
      limit = NULL,
      cursor = NULL
    )

#### Arguments

- `lat, lon`:

  Circle centre.

- `radius_m`:

  Circle radius, in metres (up to 50000).

- `bbox`:

  Bounding box, "min_lon,min_lat,max_lon,max_lat".

- `type`:

  Destination type id(s) to keep.

- `q`:

  Name text to match.

- `limit`:

  Rows per page (up to 1000).

- `cursor`:

  Page cursor.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `spatial` is FALSE.

------------------------------------------------------------------------

### `CloseClient$poi()`

Details for one point of interest.

#### Usage

    CloseClient$poi(dest_id, if_none_match = NULL)

#### Arguments

- `dest_id`:

  Destination id.

- `if_none_match`:

  An ETag to revalidate for free.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `spatial` is FALSE.

------------------------------------------------------------------------

### `CloseClient$poi_catchment()`

Every census block that can reach a point of interest, one row per
(block, mode). Read every page with `$records()`.

#### Usage

    CloseClient$poi_catchment(
      dest_id,
      mode = NULL,
      block = NULL,
      max_minutes = NULL,
      limit = NULL,
      cursor = NULL
    )

#### Arguments

- `dest_id`:

  Destination id.

- `mode`:

  Travel mode(s) to keep.

- `block`:

  Specific block id(s) to keep.

- `max_minutes`:

  Upper bound on travel time (up to 30).

- `limit`:

  Rows per page (up to 1000).

- `cursor`:

  Page cursor.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `spatial` is FALSE.

------------------------------------------------------------------------

### `CloseClient$blocks_query()`

Blocks inside a GeoJSON polygon, or a circle (`center` + `radius_m`),
one row per (block, category, mode). Read every page with `$records()`.

#### Usage

    CloseClient$blocks_query(
      polygon = NULL,
      center = NULL,
      radius_m = NULL,
      type = NULL,
      mode = NULL,
      include_population = NULL,
      limit = NULL,
      cursor = NULL
    )

#### Arguments

- `polygon`:

  A GeoJSON polygon or multipolygon (a list).

- `center`:

  A circle centre, `list(lon =, lat =)`.

- `radius_m`:

  Circle radius, in metres (up to 28000).

- `type`:

  Destination type id(s) to keep.

- `mode`:

  Travel mode(s) to keep.

- `include_population`:

  Add each block's population to its rows.

- `limit`:

  Rows per page (up to 1000).

- `cursor`:

  Page cursor.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `spatial` is FALSE.

------------------------------------------------------------------------

### `CloseClient$place_blocks()`

Per-block travel times for every block in a place (a city or town), by
place GEOID. Read every page with `$records()`.

#### Usage

    CloseClient$place_blocks(
      geoid,
      mode = NULL,
      type = NULL,
      include_population = NULL,
      limit = NULL,
      cursor = NULL
    )

#### Arguments

- `geoid`:

  Census place GEOID.

- `mode`:

  Travel mode(s) to keep.

- `type`:

  Destination type id(s) to keep.

- `include_population`:

  Add each block's population to its rows.

- `limit`:

  Rows per page (up to 1000).

- `cursor`:

  Page cursor.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `spatial` is FALSE.

------------------------------------------------------------------------

### `CloseClient$isochrone()`

Travel-time contours from a block or a lat/lon point. Give `minutes` for
one threshold, or `contours` for up to four.

#### Usage

    CloseClient$isochrone(
      block = NULL,
      lon = NULL,
      lat = NULL,
      mode = NULL,
      direction = NULL,
      minutes = NULL,
      contours = NULL,
      format = NULL,
      v = NULL,
      if_none_match = NULL
    )

#### Arguments

- `block`:

  Origin block GEOID (or give `lon` + `lat`).

- `lon, lat`:

  Origin point, instead of `block`.

- `mode`:

  "walk", "bike", or "transit".

- `direction`:

  "to" (blocks that can reach the origin) or "from".

- `minutes`:

  A single threshold (1 to 60).

- `contours`:

  Up to four ascending levels, instead of `minutes`.

- `format`:

  "geojson" (polygons) or "blocks" (a block list).

- `v`:

  Optional cache-buster, echoed back.

- `if_none_match`:

  An ETag to revalidate for free.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object of
contour polygons, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `spatial` is FALSE or `format` is "blocks".

------------------------------------------------------------------------

### `CloseClient$isochrone_meta()`

Isochrone version, directions, modes, and assumptions (free).

#### Usage

    CloseClient$isochrone_meta(if_none_match = NULL)

#### Arguments

- `if_none_match`:

  An ETag to revalidate for free.

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$records()`

Read every record from a paginated method, following the cursor to the
last page.

#### Usage

    CloseClient$records(endpoint, ...)

#### Arguments

- `endpoint`:

  Name of a paginated method, such as "pois_search".

- `...`:

  Arguments passed on to that method.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) object, or a
list of records when `spatial` is FALSE.

#### Examples

    close$records("pois_search", lat = 41.82, lon = -71.41, radius_m = 1500)

------------------------------------------------------------------------

### `CloseClient$clone()`

The objects of this class are cloneable with this method.

#### Usage

    CloseClient$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r

## ------------------------------------------------
## Method `CloseClient$records()`
## ------------------------------------------------

if (FALSE) { # \dontrun{
close$records("pois_search", lat = 41.82, lon = -71.41, radius_m = 1500)
} # }
```
