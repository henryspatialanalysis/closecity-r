# Fastest travel time from a point to each destination category

Like
[`close_block_summary()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_block_summary.md),
but from the census block containing a lat/lon; the resolved block GEOID
is echoed as `resolved_block`. Metered per row.

## Usage

``` r
close_point_summary(
  client,
  lat,
  lon,
  mode = NULL,
  type = NULL,
  if_none_match = NULL
)
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- lat:

  Latitude (WGS84).

- lon:

  Longitude (WGS84).

- mode:

  Mode label(s) to filter by.

- type:

  Destination type id(s) to filter by.

- if_none_match:

  An ETag to revalidate; returns a free HTTP 304 on a match.

## Value

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

## See also

Other point endpoints:
[`close_point_pois()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_point_pois.md)
