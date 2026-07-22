# Looking for a home

Say you are moving to a new city and want to live near the amenities
that are important to you. In this tutorial, we find the blocks that are
within a 10-minute walk of a supermarket, a 5-minute walk of a
restaurant, and a 20-minute walk of a frequent-transit stop. Then, we
narrow those blocks to the overlap of two commutes. The example city is
Somerville, Massachusetts.

*Running this tutorial uses about 2,900 tokens.*

## Set up

Build a client, then read the pieces you need from the free catalog
instead of memorising codes.

``` r

library(closecity)
library(sf)
close <- close_client("ck_live_your_key")   # use your own key here
```

``` r

# The catalog lists every category with its numeric id. Pull the ids you need.
types <- close$destination_types()
ids <- setNames(types$dest_type_id, types$label)

supermarket_dest_id <- ids[["grocery_stores"]]
restaurant_dest_id <- ids[["restaurants"]]
freq_transit_stop_dest_id <- ids[["frequent_transit"]]

# Turn the city name into a GEOID and a centre point.
city <- close$places("Somerville")[1, ]
```

## See what is around

Look at the raw ingredients first. Each search returns points; give each
category a colour and map them together.

``` r

supermarkets <- close$pois_search(lat = city$lat, lon = city$lon,
                                  radius_m = 3000, type = supermarket_dest_id)
restaurants <- close$pois_search(lat = city$lat, lon = city$lon,
                                 radius_m = 3000, type = restaurant_dest_id)
stops <- close$pois_search(lat = city$lat, lon = city$lon,
                           radius_m = 3000, type = freq_transit_stop_dest_id)

supermarkets$kind <- "Supermarket"
restaurants$kind <- "Restaurant"
stops$kind <- "Transit stop"
around <- rbind(supermarkets[, "kind"], restaurants[, "kind"], stops[, "kind"])

palette <- c(Supermarket = "#058040", Restaurant = "#c6cbe0",
             `Transit stop` = "#f36e21")
close_map(around, color = palette[around$kind], label = "kind")
```

## Find the blocks that qualify

Somerville is a census place, so one call by place GEOID pulls the
per-block walk times for every block in the city — `$place_blocks()`
reads every page and returns one sf table with one row per (block,
category); block boundaries come from `tigris`, downloaded once and
cached. (To search an arbitrary area instead, use `$blocks_query()` with
a centre and radius or a polygon — we do that with a radius in the other
tutorials only to keep their token cost low; a place GEOID pulls the
whole city.)

``` r

blocks <- close$place_blocks(city$geoid, mode = "walk",
                             type = c(supermarket_dest_id, restaurant_dest_id,
                                      freq_transit_stop_dest_id))
```

Each amenity has its own rule, so pick the blocks that pass each one,
then keep the blocks that pass all three.
[`intersect()`](https://rdrr.io/r/base/sets.html) takes two sets, so
fold it over the list.

``` r

near_supermarket <- unique(blocks$geoid[blocks$dest_type_id == supermarket_dest_id &
                                          blocks$travel_time <= 10])
near_restaurant <- unique(blocks$geoid[blocks$dest_type_id == restaurant_dest_id &
                                         blocks$travel_time <= 5])
near_transit <- unique(blocks$geoid[blocks$dest_type_id == freq_transit_stop_dest_id &
                                      blocks$travel_time <= 20])

candidates <- Reduce(intersect, list(near_supermarket, near_restaurant, near_transit))
```

Show every block in the city, and highlight the ones that qualify.

``` r

city_blocks <- blocks[!duplicated(blocks$geoid), ]
city_blocks$qualifies <- city_blocks$geoid %in% candidates
close_map(city_blocks, highlight = "qualifies", color = "#f36e21")
```

## Narrow to a shared commute

Suppose two of you work in different places. A transit isochrone from
each workplace shows how far each commute reaches.

``` r

work_a <- close$isochrone(lon = -71.0865, lat = 42.3625, mode = "transit",
                          direction = "from", minutes = 20)
work_b <- close$isochrone(lon = -71.0589, lat = 42.3555, mode = "transit",
                          direction = "from", minutes = 20)

close_map(work_a, color = "#058040")
```

``` r

close_map(work_b, color = "#f36e21")
```

Keep the qualifying blocks that also sit inside both commutes. That
short list is where to look.

``` r

both_commutes <- st_intersection(st_union(work_a), st_union(work_b))
winners <- city_blocks[city_blocks$qualifies, ]
winners$shortlist <- st_intersects(winners, both_commutes, sparse = FALSE)[, 1]
close_map(winners, highlight = "shortlist", color = "#058040")
```
