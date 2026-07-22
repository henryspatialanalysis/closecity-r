# The amenity basket

A city planner wants every resident to be able to walk to a basket of
six everyday amenities: a supermarket, a library, a park, a
frequent-transit stop, a restaurant, and a cafe. This tutorial measures
how many residents already have that, and shows where the gaps are. The
idea follows [this
analysis](https://nathenry.com/writing/2023-02-07-seattle-walkability.html),
here applied to Richmond, Virginia.

*Running this tutorial uses about 3,500 tokens.*

## Set up

Read the six category ids from the free catalog, and turn the city name
into a centre point.

``` r

library(closecity)
library(sf)
close <- close_client("ck_live_your_key")   # use your own key here
```

``` r

types <- close$destination_types()
ids <- setNames(types$dest_type_id, types$label)

basket <- c(
  supermarket = ids[["grocery_stores"]],
  library = ids[["libraries"]],
  park = ids[["parks"]],
  transit = ids[["frequent_transit"]],
  restaurant = ids[["restaurants"]],
  cafe = ids[["cafes"]]
)

city <- close$places("Richmond")[1, ]
```

## Pull the blocks, with population

`$blocks_query()` reads every page: the walk time from every block to
each of the six categories, plus each block’s population, as one sf
table. To keep this tutorial cheap we take the central blocks within a
radius; `$place_blocks(city$geoid)` pulls **every** block in the city
the same way (at a higher token cost).

``` r

blocks <- close$blocks_query(
  center = list(lon = city$lon, lat = city$lat), radius_m = 2500,
  mode = "walk", type = unname(basket), include_population = TRUE
)

# One row per block, for population and for mapping.
one_per_block <- blocks[!duplicated(blocks$geoid), ]
total_pop <- sum(one_per_block$population)
```

## Coverage, one amenity at a time

For each amenity, a block counts as covered when it is within a
15-minute walk. Add up the population of the covered blocks.

``` r

for (name in names(basket)) {
  covered <- unique(blocks$geoid[blocks$dest_type_id == basket[name] &
                                   blocks$travel_time <= 15])
  pop <- sum(one_per_block$population[one_per_block$geoid %in% covered])
  cat(sprintf("%-11s %3.0f%%\n", name, 100 * pop / total_pop))
}
#> supermarket  13%
#> library      38%
#> park         89%
#> transit       5%
#> restaurant   71%
#> cafe         64%
```

Parks and restaurants tend to be everywhere; supermarkets and frequent
transit are usually the hardest to reach. Map one amenity — every block
shown, the covered ones highlighted.

``` r

near_transit <- unique(blocks$geoid[blocks$dest_type_id == basket["transit"] &
                                      blocks$travel_time <= 15])
one_per_block$has_transit <- one_per_block$geoid %in% near_transit
close_map(one_per_block, highlight = "has_transit", color = "#058040")
```

## The 15-minute-city score

Count, for each block, how many of the six amenities are within a
15-minute walk. That score, from 0 to 6, is the map planners reach for.
It reuses the data you already pulled, so it costs nothing more.

``` r

covered <- blocks[blocks$travel_time <= 15, ]
score <- tapply(covered$dest_type_id, covered$geoid, function(x) length(unique(x)))
one_per_block$score <- as.integer(score[one_per_block$geoid])
one_per_block$score[is.na(one_per_block$score)] <- 0L
close_map(one_per_block, fill = "score")
```

## Who can reach all six

A block is fully covered only if all six amenities are within 15
minutes. Fold the per-amenity covered sets together.

``` r

covered_sets <- lapply(names(basket), function(name) {
  unique(blocks$geoid[blocks$dest_type_id == basket[name] &
                        blocks$travel_time <= 15])
})
covered_all <- Reduce(intersect, covered_sets)

basket_pop <- sum(one_per_block$population[one_per_block$geoid %in% covered_all])
cat(sprintf("All six amenities: %.0f%% of residents\n", 100 * basket_pop / total_pop))
#> All six amenities: 4% of residents

one_per_block$full_basket <- one_per_block$geoid %in% covered_all
close_map(one_per_block, highlight = "full_basket", color = "#f36e21")
```

## Which amenity to add first

Look at the residents who are not yet fully covered, and count how many
of them are missing each amenity. The amenity that the most people lack
is the one to add first.

``` r

uncovered <- setdiff(one_per_block$geoid, covered_all)

for (name in names(basket)) {
  covered <- unique(blocks$geoid[blocks$dest_type_id == basket[name] &
                                   blocks$travel_time <= 15])
  lacking <- setdiff(uncovered, covered)
  pop <- sum(one_per_block$population[one_per_block$geoid %in% lacking])
  cat(sprintf("%-11s %6.0f residents would gain access\n", name, pop))
}
#> supermarket  26219 residents would gain access
#> library      18720 residents would gain access
#> park          3373 residents would gain access
#> transit      28424 residents would gain access
#> restaurant    8732 residents would gain access
#> cafe         10798 residents would gain access
```

## Site a new supermarket

The counts above say *which* amenity to add; the next question is
*where*. Take a candidate site near the city centre and ask how many
residents would newly gain a supermarket within a 15-minute walk if one
opened there. A `direction = "to"` isochrone gives exactly the blocks
that could reach the site on foot in 15 minutes.

``` r

reachable <- close$isochrone(lon = city$lon, lat = city$lat, mode = "walk",
                             direction = "to", minutes = 15, format = "blocks")

near_supermarket <- unique(blocks$geoid[blocks$dest_type_id == basket["supermarket"] &
                                          blocks$travel_time <= 15])
newly_served <- setdiff(reachable$geoid, near_supermarket)
gain_pop <- sum(one_per_block$population[one_per_block$geoid %in% newly_served])
cat(sprintf("A supermarket here would newly serve %.0f residents\n", gain_pop))
#> A supermarket here would newly serve 0 residents
```

Map the whole city and highlight the blocks that would newly gain access
— the population this one site reaches.

``` r

one_per_block$newly_served <- one_per_block$geoid %in% newly_served
close_map(one_per_block, highlight = "newly_served", color = "#e8590c")
```
