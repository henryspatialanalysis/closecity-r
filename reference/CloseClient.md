# Close API client

An R6 object that holds your connection settings and gives you one
method per public route. Create it with
[`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md)
rather than calling `$new()`. Results come back per the `output` field:
an [sf](https://r-spatial.github.io/sf/reference/sf.html) object where
geometry applies, a data frame otherwise, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`.

## Public fields

- `output`:

  (`character(1)`)  
  How results come back: `'spatial'`, `'tabular'`, or `'raw'`. Change it
  any time, or override it per call with the method's `output` argument.

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

- [`CloseClient$place_pois()`](#method-CloseClient-place_pois)

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
      output = "spatial"
    )

#### Arguments

- `api_key`:

  Your API key, or NULL for the free routes. When NULL, the
  `CLOSECITY_KEY` environment variable is used if set.

- `base_url`:

  API base URL.

- `timeout`:

  Request timeout, in seconds.

- `output`:

  One of `'spatial'`, `'tabular'`, or `'raw'`.

------------------------------------------------------------------------

### `CloseClient$health()`

Liveness check (free). Always a raw
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

#### Usage

    CloseClient$health()

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$last_updated()`

Publication time of the newest data (free). Always a raw reply.

#### Usage

    CloseClient$last_updated()

#### Returns

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

------------------------------------------------------------------------

### `CloseClient$modes()`

Travel modes and their numeric ids (free).

#### Usage

    CloseClient$modes(output = NULL)

#### Arguments

- `output`:

  Override the client's output mode for this call.

#### Returns

A data frame, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`.

------------------------------------------------------------------------

### `CloseClient$destination_types()`

Destination-type taxonomy (free). Use it to look up the numeric `type`
ids the data routes filter on; a parent type expands to its `leaf_ids`.

#### Usage

    CloseClient$destination_types(output = NULL)

#### Arguments

- `output`:

  Override the client's output mode for this call.

#### Returns

A data frame, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`.

------------------------------------------------------------------------

### `CloseClient$vintage()`

Active version of each dataset component (free).

#### Usage

    CloseClient$vintage(output = NULL)

#### Arguments

- `output`:

  Override the client's output mode for this call.

#### Returns

A data frame, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`.

------------------------------------------------------------------------

### `CloseClient$places()`

Look up a city or town by name (free). Each match carries its census
place GEOID and centre point.

#### Usage

    CloseClient$places(q, limit = NULL, output = NULL)

#### Arguments

- `q`:

  Name to search for, such as "Providence".

- `limit`:

  Most matches to return (1 to 20).

- `output`:

  Override the client's output mode for this call.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) of points (a
data frame in tabular mode, a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`).

------------------------------------------------------------------------

### `CloseClient$block_summary()`

Fastest travel time from a census block to each destination category, by
mode.

#### Usage

    CloseClient$block_summary(
      geoid,
      mode = NULL,
      type = NULL,
      if_none_match = NULL,
      output = NULL
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

- `output`:

  Override the client's output mode for this call.

#### Returns

A data frame with a broadcast `geoid` column, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`.

------------------------------------------------------------------------

### `CloseClient$block_pois()`

Nearby points of interest and their travel time from a block, one row
per (POI, mode). Reads every page by default.

#### Usage

    CloseClient$block_pois(
      geoid,
      mode = NULL,
      type = NULL,
      dest_id = NULL,
      max_minutes = NULL,
      limit = NULL,
      cursor = NULL,
      paginate = TRUE,
      output = NULL
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

  Page cursor from a previous reply's `next_cursor`; supplying one
  fetches only that page.

- `paginate`:

  Follow `next_cursor` and return every page (the default); set `FALSE`
  for the first page only.

- `output`:

  Override the client's output mode for this call.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) of points (a
data frame in tabular mode, a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`).

------------------------------------------------------------------------

### `CloseClient$point_summary()`

Like `$block_summary()`, but from the block containing a lat/lon point.
The resolved block is echoed as `resolved_block` and broadcast to a
`geoid` column.

#### Usage

    CloseClient$point_summary(
      lat,
      lon,
      mode = NULL,
      type = NULL,
      if_none_match = NULL,
      output = NULL
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

- `output`:

  Override the client's output mode for this call.

#### Returns

A data frame, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`.

------------------------------------------------------------------------

### `CloseClient$point_pois()`

Like `$block_pois()`, but from the block containing a lat/lon point.
Reads every page by default.

#### Usage

    CloseClient$point_pois(
      lat,
      lon,
      mode = NULL,
      type = NULL,
      dest_id = NULL,
      max_minutes = NULL,
      limit = NULL,
      cursor = NULL,
      paginate = TRUE,
      output = NULL
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

  Page cursor; supplying one fetches only that page.

- `paginate`:

  Follow `next_cursor` and return every page (the default); set `FALSE`
  for the first page only.

- `output`:

  Override the client's output mode for this call.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) of points (a
data frame in tabular mode, a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`).

------------------------------------------------------------------------

### `CloseClient$pois_search()`

Search points of interest by bounding box, or by a circle (`lat` +
`lon` + `radius_m`). Reads every page by default.

#### Usage

    CloseClient$pois_search(
      lat = NULL,
      lon = NULL,
      radius_m = NULL,
      bbox = NULL,
      type = NULL,
      q = NULL,
      limit = NULL,
      cursor = NULL,
      paginate = TRUE,
      output = NULL
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

  Page cursor; supplying one fetches only that page.

- `paginate`:

  Follow `next_cursor` and return every page (the default); set `FALSE`
  for the first page only.

- `output`:

  Override the client's output mode for this call.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) of points (a
data frame in tabular mode, a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`).

------------------------------------------------------------------------

### `CloseClient$poi()`

Details for one point of interest.

#### Usage

    CloseClient$poi(dest_id, if_none_match = NULL, output = NULL)

#### Arguments

- `dest_id`:

  Destination id.

- `if_none_match`:

  An ETag to revalidate for free.

- `output`:

  Override the client's output mode for this call.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) of one point
(a data frame in tabular mode, a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`).

------------------------------------------------------------------------

### `CloseClient$poi_catchment()`

Every census block that can reach a point of interest, one row per
(block, mode). Reads every page by default.

#### Usage

    CloseClient$poi_catchment(
      dest_id,
      mode = NULL,
      block = NULL,
      max_minutes = NULL,
      limit = NULL,
      cursor = NULL,
      paginate = TRUE,
      output = NULL
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

  Page cursor; supplying one fetches only that page.

- `paginate`:

  Follow `next_cursor` and return every page (the default); set `FALSE`
  for the first page only.

- `output`:

  Override the client's output mode for this call.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) of block
polygons (a data frame in tabular mode, a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`).

------------------------------------------------------------------------

### `CloseClient$blocks_query()`

Blocks inside a GeoJSON polygon, or a circle (`center` + `radius_m`),
one row per (block, category, mode). Rows carry the numeric `mode_id`
(join `$modes()` to label it). Reads every page by default.

#### Usage

    CloseClient$blocks_query(
      polygon = NULL,
      center = NULL,
      radius_m = NULL,
      type = NULL,
      mode = NULL,
      include_population = NULL,
      limit = NULL,
      cursor = NULL,
      paginate = TRUE,
      output = NULL
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

  Page cursor; supplying one fetches only that page.

- `paginate`:

  Follow `next_cursor` and return every page (the default); set `FALSE`
  for the first page only.

- `output`:

  Override the client's output mode for this call.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) of block
polygons (a data frame in tabular mode, a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`).

------------------------------------------------------------------------

### `CloseClient$place_blocks()`

Per-block travel times for every block in a place (a city or town), by
place GEOID. Rows carry the numeric `mode_id` (join `$modes()` to label
it). Reads every page by default.

#### Usage

    CloseClient$place_blocks(
      geoid,
      mode = NULL,
      type = NULL,
      include_population = NULL,
      limit = NULL,
      cursor = NULL,
      paginate = TRUE,
      output = NULL
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

  Page cursor; supplying one fetches only that page.

- `paginate`:

  Follow `next_cursor` and return every page (the default); set `FALSE`
  for the first page only.

- `output`:

  Override the client's output mode for this call.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) of block
polygons (a data frame in tabular mode, a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`).

------------------------------------------------------------------------

### `CloseClient$place_pois()`

Every point of interest within a census place (a city or town), by place
GEOID. The place analog of `$pois_search()`; pass `type` to get, e.g.,
all supermarkets in a city. Spatial only, no travel times. Reads every
page by default.

#### Usage

    CloseClient$place_pois(
      geoid,
      type = NULL,
      q = NULL,
      limit = NULL,
      cursor = NULL,
      paginate = TRUE,
      output = NULL
    )

#### Arguments

- `geoid`:

  Census place GEOID.

- `type`:

  Destination type id(s) to keep.

- `q`:

  Name substring to match.

- `limit`:

  Rows per page (up to 1000).

- `cursor`:

  Page cursor; supplying one fetches only that page.

- `paginate`:

  Follow `next_cursor` and return every page (the default); set `FALSE`
  for the first page only.

- `output`:

  Override the client's output mode for this call.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) of points (a
data frame in tabular mode, a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`).

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
      if_none_match = NULL,
      output = NULL
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

- `output`:

  Override the client's output mode for this call.

#### Returns

An [sf](https://r-spatial.github.io/sf/reference/sf.html) (contour
polygons for geojson, block polygons for blocks), a data frame in
tabular mode, or a
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
when `output` is `'raw'`.

------------------------------------------------------------------------

### `CloseClient$isochrone_meta()`

Isochrone version, directions, modes, and assumptions (free). Always a
raw
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

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
last page. The paginated methods now read every page by default, so this
is rarely needed; it remains for explicit control and back-compat.

#### Usage

    CloseClient$records(endpoint, ..., output = NULL)

#### Arguments

- `endpoint`:

  Name of a paginated method, such as "pois_search".

- `...`:

  Arguments passed on to that method.

- `output`:

  Override the client's output mode for this call.

#### Returns

A data frame (an [sf](https://r-spatial.github.io/sf/reference/sf.html)
in spatial mode), or a list of records when `output` is `'raw'`.

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
