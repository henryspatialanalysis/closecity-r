# Changelog

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
