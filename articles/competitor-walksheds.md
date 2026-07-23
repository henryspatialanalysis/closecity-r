# Competitor walksheds

A coffee shop wants to understand the competition inside its own
catchment. Its **walkshed** is every residential block that can walk to
it in 10 minutes. This tutorial asks, block by block, how many other
cafes those residents can also reach on foot, and which one is closest.
The example city is Providence, Rhode Island.

*Running this tutorial uses about 450 tokens.*

## Set up

Read the cafe category id from the free catalog and find the city.

``` r

library(closecity)
library(sf)
close <- closecity::close_client(api_key = "ck_live_your_key")   # use your own key here
```

``` r

amenity_types <- close$destination_types()
ids <- setNames(amenity_types$dest_type_id, amenity_types$label)
cafe <- ids[["cafes"]]

city <- close$places(q = "Providence")[1, ]
city_boundary <- close$place_boundary(geoid = city$geoid)
```

## Find the shops and our walkshed

`$place_pois()` returns every cafe within the city’s boundary. Pick one
as the subject, then pull its walkshed: every block that can walk to it
in 10 minutes. Draw the walkshed with the cafes on top, our shop in
orange.

``` r

cafes <- close$place_pois(geoid = city$geoid, type = cafe)
ours <- cafes[1, ]
ours$name
#> [1] "Little Sister"

our_shed <- close$poi_catchment(dest_id = ours$dest_id, mode = "walk",
                                max_minutes = 10)
closecity::close_map(
  x = cafes,
  color = ifelse(cafes$dest_id == ours$dest_id, "#f36e21", "#202a5b"),
  label = "name",
  background = sf::st_union(our_shed),
  background_color = "#74b9ff",
  boundary = city_boundary
)
```

## What each block can reach

Now split the walkshed by block. A single `$block_pois()` call takes the
whole vector of walkshed blocks and returns, for every block, each cafe
its residents can walk to within 10 minutes — the real routed answer,
not a straight-line guess, and one request rather than one per block.
Passing a vector of GEOIDs tags every row with its origin `geoid`, so
grouping by it reads two things per block: how many cafes are in reach,
and which one is closest by walk time.

``` r

reach <- close$block_pois(
  our_shed$geoid,
  mode = "walk", type = cafe, max_minutes = 10, output = "tabular"
)

per_block <- split(reach, reach$geoid)
counts <- vapply(per_block, nrow, integer(1))
closest <- vapply(
  per_block, function(r) r$dest_id[which.min(r$travel_time)], numeric(1)
)
our_shed$n_cafes <- unname(counts[as.character(our_shed$geoid)])
our_shed$n_cafes[is.na(our_shed$n_cafes)] <- 0L
our_shed$closest_cafe <- unname(closest[as.character(our_shed$geoid)])
```

## How many cafes each block can reach

Shade every block in the walkshed by the number of cafes within a
10-minute walk; blue marks the blocks with the most choice.

``` r

closecity::close_map(
  x = our_shed,
  fill = "n_cafes",
  reverse = TRUE,
  boundary = city_boundary
)
```

## Which cafe is closest

Give each cafe that wins at least one block a colour, then paint every
block with the colour of its closest cafe. The cafe points share those
colours. The result is the contested ground — where our shop’s catchment
gives way to a competitor’s.

``` r

closest <- unique(stats::na.omit(our_shed$closest_cafe))
palette <- setNames(grDevices::hcl.colors(length(closest), "Dark 3"), closest)

block_color <- palette[as.character(our_shed$closest_cafe)]
block_color[is.na(block_color)] <- "#dddddd"

winning_cafes <- cafes[cafes$dest_id %in% closest, ]
closecity::close_map(
  x = our_shed,
  color = block_color,
  points = winning_cafes,
  points_color = palette[as.character(winning_cafes$dest_id)],
  boundary = city_boundary
)
```

The same recipe scales up: raise `max_minutes`, or compare whole cities
by pulling each one’s cafes with `$place_pois()`.
