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

# The key (ck_live_ or ck_test_) comes from https://account.close.city
close <- close_client("ck_live_your_key")   # use your own key here
```

The catalog and lookup routes are free, so you can also start without a
key:

``` r

close <- close_client()
close$modes()$data$modes                       # walk, bike, transit
close$last_updated()$data$last_updated
```

## Look things up instead of guessing

Two free calls save you from memorising codes. Use
`$destination_types()` to find the numeric id for a category, and
`$places()` to turn a city name into a GEOID and a centre point.

``` r

# The catalog lists every category with its numeric id and label.
types <- close$destination_types()$data$destination_types
labels <- sapply(types, `[[`, "label")
ids <- sapply(types, `[[`, "dest_type_id")
grocery_id <- ids[labels == "grocery_stores"]

# A city name gives you a GEOID and a centre point.
providence <- close$places("Providence")$results[[1]]
providence$geoid
```

## Make a call and map it

Feature methods return an [sf](https://r-spatial.github.io/sf/) object,
so you can map the result straight away.

``` r

library(sf)

groceries <- close$pois_search(lat = providence$lat, lon = providence$lon,
                               radius_m = 1500, type = grocery_id)
plot(st_geometry(groceries), pch = 19, col = "#202a5b")
```

## Read every page

List routes return one page at a time. `$records()` follows the pages to
the end.

``` r

all_groceries <- close$records("pois_search", lat = providence$lat,
                               lon = providence$lon, radius_m = 1500,
                               type = grocery_id)
```

## Turn spatial output off

Set `spatial = FALSE` to work with the raw data. Block routes join
census-block boundaries for you, using the `tigris` package to download
them once.

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
