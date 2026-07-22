# Package index

## Client

The client is an R6 object with one method per route. Build it with
close_client(); make calls through its methods.

- [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md)
  : Create a Close API client
- [`CloseClient`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.md)
  : Close API client

## Spatial output and replies

Feature methods return sf objects by default. Turn that off to work with
the raw reply.

- [`close_as_sf()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_sf.md)
  : Convert a Close reply to an sf object
- [`close_reply`](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
  : The reply object
