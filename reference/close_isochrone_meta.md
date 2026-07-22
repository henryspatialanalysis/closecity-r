# Isochrone metadata

The active isochrone store version, available directions/modes, and the
routing assumptions (free, keyless).

## Usage

``` r
close_isochrone_meta(client, if_none_match = NULL)
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- if_none_match:

  An ETag to revalidate; returns a free HTTP 304 on a match.

## Value

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

## See also

Other isochrone endpoints:
[`close_isochrone()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_isochrone.md)
