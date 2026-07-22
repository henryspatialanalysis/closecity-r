# Changelog

## closecity 1.3.0

- `$place_pois()` — every point of interest within a census place (city
  or town), by place GEOID. The place analog of `$pois_search()`; pass
  `type` to get, e.g., all supermarkets in a city.
- [`close_map()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_map.md)
  — a one-line interactive map (CARTO Positron basemap, hoverable
  points, or filled blocks that highlight the features meeting a
  criterion) for the `sf` objects the client returns. Built on plotly (a
  Suggests dependency), so it needs no GDAL beyond what `sf` already
  uses.
- `$places()` results now carry a `state` column (two-letter USPS
  abbreviation), so same-named places are distinguishable.

## closecity 1.2.0

- [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md)
  reads the `CLOSECITY_KEY` environment variable when no `api_key` is
  given. A 401 with no key set carries an actionable hint pointing at
  `CLOSECITY_KEY` and the free-signup page.
- Paginated methods (`$pois_search()`, `$block_pois()`, `$point_pois()`,
  `$poi_catchment()`, `$blocks_query()`, `$place_blocks()`) read every
  page by default, matching the Python client. Pass `paginate = FALSE`
  for the first page only, or an explicit `cursor` for a single page.
  `$records()` is kept as an equivalent explicit form.
- The client does not retry: on a rate-limit or service-unavailable
  error, wait `e$retry_after` seconds and retry the request yourself.

## closecity 1.1.0

Tabular results by default, across every route.

- New `output` argument replaces `spatial`:
  `close_client(output = "spatial")` (the default) returns an `sf`
  object where geometry applies and a plain data frame for catalog and
  summary routes; `output = "tabular"` returns a data frame for every
  route and never downloads block boundaries (the cheap path when you
  only want the numbers); `output = "raw"` returns the `close_reply`.
  Set it on the client or per call.
- Catalog routes (`$modes()`, `$destination_types()`, `$vintage()`,
  `$places()`) and the block and point summaries now return data frames.
  `$block_summary()` / `$point_summary()` broadcast the origin GEOID to
  a `geoid` column, and `$isochrone(format = "blocks")` now converts
  too.
- Metering and envelope metadata (token counts, `block_geoid`,
  `assumptions`, …) are attached as attributes on the returned frame.
- New
  [`close_as_df()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_df.md)
  and an [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  method for `close_reply`, beside the existing
  [`close_as_sf()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_sf.md).
- Requires R \>= 4.1 (the native pipe is used internally).

## closecity 1.0.0

First public release of the `closecity` R client for the Close API
(api.close.city).

- An R6 client,
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md),
  with one method per public route: catalog, place lookup, block and
  point summaries and POIs, POI search, detail, and catchment, areal
  block queries, and isochrones.
- Feature methods return `sf` objects by default. Set `spatial = FALSE`
  to work with the raw reply. Block boundaries are joined with `tigris`.
- First-class metering (`tokens_charged`, `tokens_remaining`), ETag/304
  conditional requests, keyset pagination via `$records()`, and typed
  RFC 9457 errors as classed conditions.
- `$places()` looks up a city or town by name and returns its GEOID and
  centre.
