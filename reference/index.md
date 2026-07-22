# Package index

## Client

Create a client and understand the reply it returns.

- [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md)
  : Create a Close API client
- [`close_reply`](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
  : The reply object returned by every endpoint

## Catalog and lookup (free)

Keyless metadata and place-name lookup.

- [`close_destination_types()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_destination_types.md)
  : Destination-type taxonomy
- [`close_health()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_health.md)
  : Liveness check
- [`close_last_updated()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_last_updated.md)
  : Newest-data publication timestamp
- [`close_modes()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_modes.md)
  : Travel modes
- [`close_places()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_places.md)
  : Search census places by name
- [`close_vintage()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_vintage.md)
  : Dataset vintages

## Travel times from a block

- [`close_block_pois()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_block_pois.md)
  : Nearby POIs and their travel time from a block
- [`close_block_summary()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_block_summary.md)
  : Fastest travel time from a block to each destination category

## Travel times from a point

- [`close_point_pois()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_point_pois.md)
  : Nearby POIs and their travel time from a point
- [`close_point_summary()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_point_summary.md)
  : Fastest travel time from a point to each destination category

## Points of interest

- [`close_poi()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_poi.md)
  : One POI's details
- [`close_poi_catchment()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_poi_catchment.md)
  : A POI's catchment (blocks that can reach it)
- [`close_pois_search()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_pois_search.md)
  : Search POIs by area

## Areal queries

- [`close_blocks_query()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_blocks_query.md)
  : Per-block travel times within a polygon or radius
- [`close_place_blocks()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_place_blocks.md)
  : Per-block travel times for a whole place

## Isochrones

- [`close_isochrone()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_isochrone.md)
  : Travel-time contours (isochrone)
- [`close_isochrone_meta()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_isochrone_meta.md)
  : Isochrone metadata

## Pagination

- [`close_records()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_records.md)
  : Collect every record from a paginated endpoint

## Spatial output

Convert a reply to an sf object.

- [`close_as_sf()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_sf.md)
  :

  Convert a Close reply to an `sf` object
