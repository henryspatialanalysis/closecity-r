# The amenity basket

**Question.** If we want every resident to be able to walk to a basket
of six everyday amenities, what share of the population is already
covered — and which five new amenities, sited where, would raise that
share the most? This is the population-weighted “15-minute city” method
from [this
analysis](https://nathenry.com/writing/2023-02-07-seattle-walkability.html),
applied to **Richmond, VA**.

``` r

library(closecity)
close <- close_client("ck_live_your_key_here")

basket <- c(grocery = 30, library = 43, park = 63,
            frequent_transit = 61, restaurant = 27, cafe = 31)
threshold <- 15  # minutes, walking
```

## Pull per-block walk times and population

``` r

richmond <- close_places(close, "Richmond")$results[[1]]
center <- list(lon = richmond$lon, lat = richmond$lat)

rows <- close_records(close_blocks_query, close, center = center, radius_m = 2500,
                      mode = "walk", type = unname(basket),
                      include_population = TRUE)

times <- list(); pop <- c()
for (r in rows) {
  times[[r$geoid]][[as.character(r$dest_type_id)]] <- r$travel_time
  pop[r$geoid] <- if (is.null(r$population)) 0 else r$population
}
```

## Current coverage

All local and free:

``` r

covered <- function(g, type_id) {
  t <- times[[g]][[as.character(type_id)]]
  !is.null(t) && t <= threshold
}
total <- sum(pop)

for (nm in names(basket)) {
  share <- sum(pop[vapply(names(times), covered, logical(1), basket[[nm]])]) / total
  cat(sprintf("%-18s %4.0f%%\n", nm, 100 * share))
}

fully <- Filter(function(g) all(vapply(basket, function(ti) covered(g, ti),
                                       logical(1))), names(times))
cat(sprintf("\nAll six: %.0f%% of residents\n", 100 * sum(pop[unlist(fully)]) / total))
```

Parks and restaurants are widespread; **grocery** and **frequent
transit** are the binding constraints.

## Which amenities to add, and where

A new facility of a type placed at a block covers everything within a
15-minute walk of it — a `direction = "from"` walk isochrone (1 token
each). We greedily pick the five sites that turn the most
currently-uncovered residents into fully-covered ones:

``` r

library(sf)
blocks <- close_as_sf(close_blocks_query(close, center = center, radius_m = 2500,
                                         mode = "walk", type = 30), fetch = TRUE)
cent <- st_coordinates(st_point_on_surface(blocks))
rownames(cent) <- blocks$geoid

missing1 <- function(g) {                # blocks missing exactly one amenity
  miss <- Filter(function(ti) !covered(g, ti), basket)
  if (length(miss) == 1) names(basket)[match(miss[[1]], basket)] else NA
}

candidates <- Filter(function(g) !is.na(missing1(g)) && g %in% blocks$geoid,
                     names(times))
candidates <- head(candidates[order(-pop[unlist(candidates)])], 25)

walkshed <- function(g) {
  iso <- close_isochrone(close, lon = cent[g, 1], lat = cent[g, 2], mode = "walk",
                         direction = "from", minutes = threshold, format = "blocks")
  vapply(iso$data$blocks, function(b) b$geoid, character(1))
}
```

Loop the greedy selection over the candidate walksheds, subtracting each
chosen site’s newly-covered residents before picking the next — the top
five are your ranked, mapped interventions.

## Token cost

- `close_places`: free. `close_blocks_query` disc (~700 blocks x 6
  categories): ~4,000 tokens.
- Up to 25 candidate isochrones: ~25 tokens.

Just inside a 5,000-token month. Shrink `radius_m` or the candidate
count to trade coverage for budget.
