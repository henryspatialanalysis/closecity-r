# Search census places by name

Resolve a city/town name to its census place GEOID and WGS84 centroid.
Free (no API key). Feed the centroid into
[`close_blocks_query()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_blocks_query.md)
(`center` + `radius_m`), or the GEOID into
[`close_place_blocks()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_place_blocks.md).

## Usage

``` r
close_places(client, q, limit = NULL)
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- q:

  Name substring, e.g. `"Providence"`.

- limit:

  Maximum matches to return (1-20).

## Value

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

## See also

Other catalog endpoints:
[`close_destination_types()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_destination_types.md),
[`close_health()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_health.md),
[`close_last_updated()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_last_updated.md),
[`close_modes()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_modes.md),
[`close_vintage()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_vintage.md)
