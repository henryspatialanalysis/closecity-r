# Competitor walksheds

A coffee shop wants to know which competitors draw from the same
neighbourhood it does. Its **walkshed** is every residential block that
can walk to it. This tutorial finds the competitors and measures how
much of that walkshed they share. The example city is Providence, Rhode
Island.

*Running this tutorial uses about 700 tokens.*

## Set up

Read the cafe category id from the free catalog and find the city.

``` r

library(closecity)
library(sf)
close <- close_client("ck_live_your_key")   # use your own key here
```

``` r

types <- close$destination_types()
ids <- setNames(types$dest_type_id, types$label)
cafe <- ids[["cafes"]]

city <- close$places("Providence")[1, ]
```

## Find the shops

`$place_pois()` returns every cafe within the city’s boundary — no
radius to guess. Pick one as the subject and draw it in orange; the rest
are the field.

``` r

cafes <- close$place_pois(city$geoid, type = cafe)
ours <- cafes[1, ]
ours$name
#> [1] "Little Sister"

cafes$is_ours <- cafes$dest_id == ours$dest_id
close_map(cafes, color = ifelse(cafes$is_ours, "#f36e21", "#202a5b"), label = "name")
```

## Our walkshed

Ask for every block that can reach our shop within a 10-minute walk.
This comes back as sf polygons, with the block boundaries downloaded
once by `tigris`.

``` r

our_shed <- close$poi_catchment(ours$dest_id, mode = "walk", max_minutes = 10)
close_map(our_shed, color = "#74b9ff")
```

## Who else serves it

For each of the nearest competitors, pull their walkshed and count the
blocks they share with ours. `our_shed$geoid` is just a vector of block
ids, so the overlap is a plain set intersection.

``` r

for (i in 2:6) {
  their_shed <- close$poi_catchment(cafes$dest_id[i], mode = "walk",
                                    max_minutes = 10)
  shared <- intersect(our_shed$geoid, their_shed$geoid)
  cat(sprintf("%-28s %3d shared blocks (%.0f%% of ours)\n",
              cafes$name[i], length(shared),
              100 * length(shared) / nrow(our_shed)))
}
#> Three Sisters                 11 shared blocks (10% of ours)
#> New Harvest Coffee Roasters    0 shared blocks (0% of ours)
#> Sawyer’s                     0 shared blocks (0% of ours)
#> The Nitro Bar                  0 shared blocks (0% of ours)
#> Schaste                        0 shared blocks (0% of ours)
```

## Map the contested ground

Draw every cafe, with our shop in orange and the field in navy. The
clusters of competitors sitting inside our walkshed are the ones
competing for the same walk-in traffic.

``` r

close_map(cafes, color = ifelse(cafes$is_ours, "#f36e21", "#202a5b"), label = "name")
```

The same recipe scales up: loop `poi_catchment` over more competitors,
or compare whole cities by pulling each one’s cafes with
`$place_pois()`.
