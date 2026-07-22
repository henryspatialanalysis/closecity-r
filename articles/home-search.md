# Looking for a home

**Question.** In a city, which blocks are within a 10-minute walk of a
supermarket, a 5-minute walk of a restaurant, and a 20-minute walk of a
frequent-transit stop? Then, given two workplaces, which of those blocks
sit in the overlap of both commutes? We use **Somerville, MA**.

## Find the place and the type ids

Both lookups are free (no tokens):

``` r

library(closecity)
close <- close_client("ck_live_your_key_here")

geoid <- close_places(close, "Somerville")$results[[1]]$geoid
GROCERY <- 30; RESTAURANT <- 27; FREQ_TRANSIT <- 61
```

## Pull the per-block walk times

``` r

rows <- close_records(close_place_blocks, close, geoid, mode = "walk",
                      type = c(GROCERY, RESTAURANT, FREQ_TRANSIT))

# Pivot to one record per block.
by_block <- list()
for (r in rows) {
  g <- r$geoid
  by_block[[g]][[as.character(r$dest_type_id)]] <- r$travel_time
}

meets <- function(t) {
  g <- t[["30"]]; r <- t[["27"]]; ft <- t[["61"]]
  !is.null(g) && g <= 10 && !is.null(r) && r <= 5 && !is.null(ft) && ft <= 20
}
candidates <- names(Filter(meets, by_block))
length(candidates)
```

## Map the candidates

Block replies carry only GEOIDs, so join census-block boundaries — with
`sf` and `tigris` installed, `close_as_sf(..., fetch = TRUE)` pulls
them:

``` r

library(sf)
blocks <- close_as_sf(close_place_blocks(close, geoid, mode = "walk",
                                         type = GROCERY), fetch = TRUE)
hits <- blocks[blocks$geoid %in% candidates, ]
plot(st_geometry(hits), col = "#f36e21", border = NA)
```

## Narrow to the overlap of two commutes

A 20-minute transit isochrone from each workplace is 10 tokens per
contour:

``` r

kendall  <- close_as_sf(close_isochrone(close, lon = -71.0865, lat = 42.3625,
                                        mode = "transit", direction = "from",
                                        minutes = 20))
downtown <- close_as_sf(close_isochrone(close, lon = -71.0589, lat = 42.3555,
                                        mode = "transit", direction = "from",
                                        minutes = 20))

commute_overlap <- st_intersection(st_union(kendall), st_union(downtown))
chosen <- hits[st_intersects(hits, commute_overlap, sparse = FALSE)[, 1], ]
plot(st_geometry(chosen), col = "#058040", border = NA)
```

The blocks in `chosen` are walkable to groceries, food, and frequent
transit **and** a reasonable transit commute for both workers.

## Token cost

- `close_places` + `close_destination_types`: free.
- `close_place_blocks` over Somerville (~800 blocks x 3 categories):
  ~2,400 tokens.
- Two transit isochrones (1 contour each): ~20 tokens.

Comfortably inside a 5,000-token month. For a larger city, swap
[`close_place_blocks()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_place_blocks.md)
for a bounded disc:
`close_blocks_query(close, center = list(lon = , lat = ), radius_m = 2500, ...)`.
