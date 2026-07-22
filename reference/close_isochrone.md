# Travel-time contours (isochrone)

Travel-time contours from a `block` (GEOID) or `lon` + `lat`. Charged
one token per contour level (1-4), not per row. With
`format = "geojson"` the reply carries polygon geometry you can convert
with
[`close_as_sf()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_sf.md).

## Usage

``` r
close_isochrone(
  client,
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
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- block:

  Origin block GEOID (or give `lon` + `lat`).

- lon, lat:

  Origin point (WGS84), as an alternative to `block`.

- mode:

  `"walk"`, `"bike"`, or `"transit"`.

- direction:

  `"to"` (blocks that can reach the origin) or `"from"`.

- minutes:

  A single threshold (1-60).

- contours:

  Up to 4 ascending levels (a vector or comma string), instead of
  `minutes`.

- format:

  `"geojson"` (polygons) or `"blocks"` (a block list).

- v:

  Opaque cache-buster, echoed back.

- if_none_match:

  An ETag to revalidate; returns a free HTTP 304 on a match.

## Value

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

## See also

Other isochrone endpoints:
[`close_isochrone_meta()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_isochrone_meta.md)

## Examples

``` r
if (FALSE) { # \dontrun{
iso <- close_isochrone(cl, block = "440070036001010", mode = "walk",
                       minutes = 15, format = "geojson")
close_as_sf(iso)
} # }
```
