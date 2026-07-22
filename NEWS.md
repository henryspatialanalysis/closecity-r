# closecity 1.0.0

First public release of the `closecity` R client for the Close API
(api.close.city).

* A `close_client()` over the metered, read-only public endpoints: catalog,
  block/point summaries and POIs, POI search/detail/catchment, areal block
  queries, and isochrones.
* First-class metering (`tokens_charged` / `tokens_remaining`), ETag/304
  conditional requests, keyset pagination via `close_records()`, and typed
  RFC 9457 errors as classed conditions.
* `close_places()` place-name lookup (city/town to GEOID + centroid).
* Opt-in spatial output: `close_as_sf()` and an `sf::st_as_sf()` method
  (POI points, isochrone polygons, and census-block joins).
