# Search POIs by area

Search points of interest by bounding box (`bbox`) or radius (`lat` +
`lon` + `radius_m`). Spatial only (no travel times). Paginated; loop
with
[`close_records()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_records.md).
Metered per returned row.

## Usage

``` r
close_pois_search(
  client,
  lat = NULL,
  lon = NULL,
  radius_m = NULL,
  bbox = NULL,
  type = NULL,
  q = NULL,
  limit = NULL,
  cursor = NULL
)
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- lat, lon:

  Circle centre (WGS84), with `radius_m`.

- radius_m:

  Search radius in metres (\<= 50000).

- bbox:

  Bounding box `"min_lon,min_lat,max_lon,max_lat"`.

- type:

  Destination type id(s) to filter by.

- q:

  Name substring to match.

- limit:

  Page size (\<= 1000).

- cursor:

  Opaque keyset cursor; normally use
  [`close_records()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_records.md)
  instead.

## Value

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

## See also

Other POI endpoints:
[`close_poi()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_poi.md),
[`close_poi_catchment()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_poi_catchment.md)
