# Changelog

## closecity 1.0.0

First public release of the `closecity` R client for the Close API
(api.close.city).

- A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md)
  over the metered, read-only public endpoints: catalog, block/point
  summaries and POIs, POI search/detail/catchment, areal block queries,
  and isochrones.
- First-class metering (`tokens_charged` / `tokens_remaining`), ETag/304
  conditional requests, keyset pagination via
  [`close_records()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_records.md),
  and typed RFC 9457 errors as classed conditions.
- [`close_places()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_places.md)
  place-name lookup (city/town to GEOID + centroid).
- Opt-in spatial output:
  [`close_as_sf()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_sf.md)
  and an
  [`sf::st_as_sf()`](https://r-spatial.github.io/sf/reference/st_as_sf.html)
  method (POI points, isochrone polygons, and census-block joins).
