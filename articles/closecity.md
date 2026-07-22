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
#> [[1]]
#> [[1]]$mode_id
#> [1] 1
#> 
#> [[1]]$mode
#> [1] "walk"
#> 
#> [[1]]$description
#> [1] "Walking"
#> 
#> 
#> [[2]]
#> [[2]]$mode_id
#> [1] 2
#> 
#> [[2]]$mode
#> [1] "bike"
#> 
#> [[2]]$description
#> [1] "Biking"
#> 
#> 
#> [[3]]
#> [[3]]$mode_id
#> [1] 3
#> 
#> [[3]]$mode
#> [1] "transit"
#> 
#> [[3]]$description
#> [1] "Public transit"
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

providence <- close$places("Providence")$data$places[[1]]
providence$geoid
#> [1] "4459000"
```

## Make a call and map it

Feature methods return an [sf](https://r-spatial.github.io/sf/) object,
so you can map the result straight away.

``` r

groceries <- close$pois_search(lat = providence$lat, lon = providence$lon,
                               radius_m = 1500, type = grocery_id)
plot(st_geometry(groceries), pch = 19, col = "#202a5b")
```

![](closecity_files/figure-html/unnamed-chunk-4-1.png)

## Turn spatial output off

Set the client’s `spatial` flag to FALSE to work with the raw data.
Block routes join census-block boundaries for you, using the `tigris`
package.

``` r

close$spatial <- FALSE
summary <- close$block_summary("440070008001068", mode = "walk")
summary$results
#> [[1]]
#> [[1]]$dest_type_id
#> [1] 1
#> 
#> [[1]]$mode
#> [1] "walk"
#> 
#> [[1]]$travel_time
#> [1] 10
#> 
#> 
#> [[2]]
#> [[2]]$dest_type_id
#> [1] 5
#> 
#> [[2]]$mode
#> [1] "walk"
#> 
#> [[2]]$travel_time
#> [1] 26
#> 
#> 
#> [[3]]
#> [[3]]$dest_type_id
#> [1] 6
#> 
#> [[3]]$mode
#> [1] "walk"
#> 
#> [[3]]$travel_time
#> [1] 22
#> 
#> 
#> [[4]]
#> [[4]]$dest_type_id
#> [1] 7
#> 
#> [[4]]$mode
#> [1] "walk"
#> 
#> [[4]]$travel_time
#> [1] 10
#> 
#> 
#> [[5]]
#> [[5]]$dest_type_id
#> [1] 27
#> 
#> [[5]]$mode
#> [1] "walk"
#> 
#> [[5]]$travel_time
#> [1] 3
#> 
#> 
#> [[6]]
#> [[6]]$dest_type_id
#> [1] 28
#> 
#> [[6]]$mode
#> [1] "walk"
#> 
#> [[6]]$travel_time
#> [1] 3
#> 
#> 
#> [[7]]
#> [[7]]$dest_type_id
#> [1] 29
#> 
#> [[7]]$mode
#> [1] "walk"
#> 
#> [[7]]$travel_time
#> [1] 9
#> 
#> 
#> [[8]]
#> [[8]]$dest_type_id
#> [1] 30
#> 
#> [[8]]$mode
#> [1] "walk"
#> 
#> [[8]]$travel_time
#> [1] 6
#> 
#> 
#> [[9]]
#> [[9]]$dest_type_id
#> [1] 31
#> 
#> [[9]]$mode
#> [1] "walk"
#> 
#> [[9]]$travel_time
#> [1] 3
#> 
#> 
#> [[10]]
#> [[10]]$dest_type_id
#> [1] 32
#> 
#> [[10]]$mode
#> [1] "walk"
#> 
#> [[10]]$travel_time
#> [1] 15
#> 
#> 
#> [[11]]
#> [[11]]$dest_type_id
#> [1] 33
#> 
#> [[11]]$mode
#> [1] "walk"
#> 
#> [[11]]$travel_time
#> [1] 18
#> 
#> 
#> [[12]]
#> [[12]]$dest_type_id
#> [1] 34
#> 
#> [[12]]$mode
#> [1] "walk"
#> 
#> [[12]]$travel_time
#> [1] 9
#> 
#> 
#> [[13]]
#> [[13]]$dest_type_id
#> [1] 35
#> 
#> [[13]]$mode
#> [1] "walk"
#> 
#> [[13]]$travel_time
#> [1] 13
#> 
#> 
#> [[14]]
#> [[14]]$dest_type_id
#> [1] 38
#> 
#> [[14]]$mode
#> [1] "walk"
#> 
#> [[14]]$travel_time
#> [1] 17
#> 
#> 
#> [[15]]
#> [[15]]$dest_type_id
#> [1] 40
#> 
#> [[15]]$mode
#> [1] "walk"
#> 
#> [[15]]$travel_time
#> [1] 8
#> 
#> 
#> [[16]]
#> [[16]]$dest_type_id
#> [1] 41
#> 
#> [[16]]$mode
#> [1] "walk"
#> 
#> [[16]]$travel_time
#> [1] 9
#> 
#> 
#> [[17]]
#> [[17]]$dest_type_id
#> [1] 43
#> 
#> [[17]]$mode
#> [1] "walk"
#> 
#> [[17]]$travel_time
#> [1] 3
#> 
#> 
#> [[18]]
#> [[18]]$dest_type_id
#> [1] 60
#> 
#> [[18]]$mode
#> [1] "walk"
#> 
#> [[18]]$travel_time
#> [1] 2
#> 
#> 
#> [[19]]
#> [[19]]$dest_type_id
#> [1] 63
#> 
#> [[19]]$mode
#> [1] "walk"
#> 
#> [[19]]$travel_time
#> [1] 3
#> 
#> 
#> [[20]]
#> [[20]]$dest_type_id
#> [1] 64
#> 
#> [[20]]$mode
#> [1] "walk"
#> 
#> [[20]]$travel_time
#> [1] 4
#> 
#> 
#> [[21]]
#> [[21]]$dest_type_id
#> [1] 65
#> 
#> [[21]]$mode
#> [1] "walk"
#> 
#> [[21]]$travel_time
#> [1] 7
#> 
#> 
#> [[22]]
#> [[22]]$dest_type_id
#> [1] 66
#> 
#> [[22]]$mode
#> [1] "walk"
#> 
#> [[22]]$travel_time
#> [1] 13
#> 
#> 
#> [[23]]
#> [[23]]$dest_type_id
#> [1] 67
#> 
#> [[23]]$mode
#> [1] "walk"
#> 
#> [[23]]$travel_time
#> [1] 3
#> 
#> 
#> [[24]]
#> [[24]]$dest_type_id
#> [1] 126
#> 
#> [[24]]$mode
#> [1] "walk"
#> 
#> [[24]]$travel_time
#> [1] 10
#> 
#> 
#> [[25]]
#> [[25]]$dest_type_id
#> [1] 159
#> 
#> [[25]]$mode
#> [1] "walk"
#> 
#> [[25]]$travel_time
#> [1] 14
#> 
#> 
#> [[26]]
#> [[26]]$dest_type_id
#> [1] 160
#> 
#> [[26]]$mode
#> [1] "walk"
#> 
#> [[26]]$travel_time
#> [1] 24
#> 
#> 
#> [[27]]
#> [[27]]$dest_type_id
#> [1] 200
#> 
#> [[27]]$mode
#> [1] "walk"
#> 
#> [[27]]$travel_time
#> [1] 2
#> 
#> 
#> [[28]]
#> [[28]]$dest_type_id
#> [1] 204
#> 
#> [[28]]$mode
#> [1] "walk"
#> 
#> [[28]]$travel_time
#> [1] 2
#> 
#> 
#> [[29]]
#> [[29]]$dest_type_id
#> [1] 205
#> 
#> [[29]]$mode
#> [1] "walk"
#> 
#> [[29]]$travel_time
#> [1] 2
#> 
#> 
#> [[30]]
#> [[30]]$dest_type_id
#> [1] 206
#> 
#> [[30]]$mode
#> [1] "walk"
#> 
#> [[30]]$travel_time
#> [1] 4
#> 
#> 
#> [[31]]
#> [[31]]$dest_type_id
#> [1] 207
#> 
#> [[31]]$mode
#> [1] "walk"
#> 
#> [[31]]$travel_time
#> [1] 7
#> 
#> 
#> [[32]]
#> [[32]]$dest_type_id
#> [1] 208
#> 
#> [[32]]$mode
#> [1] "walk"
#> 
#> [[32]]$travel_time
#> [1] 3
#> 
#> 
#> [[33]]
#> [[33]]$dest_type_id
#> [1] 209
#> 
#> [[33]]$mode
#> [1] "walk"
#> 
#> [[33]]$travel_time
#> [1] 9
```

## Handle errors

Failed requests raise a classed condition. Catch the base
`close_api_error`, or a specific one.

``` r

tryCatch(
  close$block_summary("000000000000000"),
  close_api_error = function(e) message(sprintf("%s (%d)", e$slug, e$status))
)
#> block-not-found (404)
```
