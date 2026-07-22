# Package index

## Client

The client is an R6 object with one method per route. Build it with
close_client(); make calls through its methods.

- [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md)
  : Create a Close API client
- [`CloseClient`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.md)
  : Close API client

## Output modes and replies

Routes return tabular data by default: an sf object where geometry
applies, a data frame otherwise. Convert a raw reply by hand, or read
its fields.

- [`close_as_sf()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_sf.md)
  : Convert a Close reply to an sf object
- [`close_as_df()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_df.md)
  : Convert a Close reply to a data.frame
- [`close_reply`](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
  : The reply object

## Mapping

Draw a client result on an interactive CARTO Positron basemap in one
call.

- [`close_map()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_map.md)
  : Interactive map of Close spatial results
