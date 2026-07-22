# Get started with closecity

`closecity` reads the Close API: travel times from every US census block
to nearby places, on foot, by bike, and by public transit. This vignette
is a short tour. The three tutorials go further.

## Words you will see

A few terms come up throughout:

- **Census block.** The smallest area the Census Bureau publishes. Each
  one has a 15-digit id, its **GEOID**.
- **Destination type.** A category of place, such as grocery stores or
  libraries. Every type has a numeric id.
- **Mode.** How someone travels: walk, bike, or transit.
- **Isochrone.** The area reachable from a point within a time limit, as
  a polygon.
- **Catchment.** The reverse: every block that can reach a given place.

## Build a client

You make every request through a client object.

``` r

library(closecity)
close <- close_client("ck_live_your_key")   # use your own key here
```

The catalog and lookup routes are free, so
[`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md)
with no key also works for those.

``` r

close$modes()$data$modes
```

## Look things up instead of guessing

Two free calls save you from memorising codes. Read the numeric id for a
category from the catalog, and turn a city name into a GEOID and a
centre point.

``` r

types <- close$destination_types()$data$destination_types
labels <- sapply(types, `[[`, "label")
ids <- sapply(types, `[[`, "dest_type_id")
grocery_id <- ids[labels == "grocery_stores"]

providence <- close$places("Providence")$results[[1]]
providence$geoid
```

## Make a call and map it

Feature methods return an [sf](https://r-spatial.github.io/sf/) object,
so you can map the result straight away.

``` r

groceries <- close$pois_search(lat = providence$lat, lon = providence$lon,
                               radius_m = 1500, type = grocery_id)
plot(st_geometry(groceries), pch = 19, col = "#202a5b")
```

## Turn spatial output off

Set the client’s `spatial` flag to FALSE to work with the raw data.
Block routes join census-block boundaries for you, using the `tigris`
package.

``` r

close$spatial <- FALSE
summary <- close$block_summary("440070036001010", mode = "walk")
summary$results
```

## Handle errors

Failed requests raise a classed condition. Catch the base
`close_api_error`, or a specific one.

``` r

tryCatch(
  close$block_summary("000000000000000"),
  close_api_error = function(e) message(sprintf("%s (%d)", e$slug, e$status))
)
```
