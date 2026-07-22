# One POI's details

Name, location, address, types, and whitelisted attributes for one POI.
Metered: one token per call.

## Usage

``` r
close_poi(client, dest_id, if_none_match = NULL)
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- dest_id:

  Destination id.

- if_none_match:

  An ETag to revalidate; returns a free HTTP 304 on a match.

## Value

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

## See also

Other POI endpoints:
[`close_poi_catchment()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_poi_catchment.md),
[`close_pois_search()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_pois_search.md)
