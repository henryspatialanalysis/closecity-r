# closecity <img src="man/figures/logo.png" align="right" height="120" alt="" />

R client for the Close API — travel times from every US census block to nearby
points of interest, by walking, biking, and public transit, the data behind
[close.city](https://close.city), over the [Close API](https://api.close.city).

**Documentation:** <https://henryspatialanalysis.github.io/closecity-r/>

## Install

```r
# install.packages("remotes")
remotes::install_github("henryspatialanalysis/closecity-r")
```

## Quickstart

```r
library(closecity)

# The API key (ck_live_ / ck_test_) is created at https://account.close.city.
client <- close_client("ck_live_your_key_here")

# Fastest travel time to each category from a census block.
summary <- close_block_summary(client, "410390020001010", mode = c("walk", "transit"))
for (row in summary$results) {
  cat(row$dest_type_id, row$mode, row$travel_time, "\n")
}

# Metering is surfaced on every metered reply.
cat(summary$tokens_charged, "charged;", summary$tokens_remaining, "left\n")
```

Free routes (catalog, place lookup, health) need no key:

```r
close_modes(close_client())$data$modes
close_last_updated(close_client())$data$last_updated

# Resolve a city name to its census place GEOID + centroid:
close_places(close_client(), "Providence")$results[[1]]
```

## Pagination

List endpoints are keyset-paginated. `close_records()` follows the opaque cursor
and returns every record:

```r
pois <- close_records(close_pois_search, client,
                      lat = 44.05, lon = -123.09, radius_m = 2000)
vapply(pois, function(p) p$name, character(1))
```

Or fetch a single page and read its metadata directly:

```r
page <- close_block_pois(client, "410390020001010", limit = 500)
cat(length(page$results), "rows;", page$tokens_remaining, "tokens left\n")
page$next_cursor   # pass back as `cursor =` for the next page
```

Cursors are opaque and signed — never construct or modify them.

## Conditional requests (free revalidation)

Metered `GET`s return an `ETag`. Send it back to revalidate for free — a `304`
costs no tokens, even at a zero balance:

```r
first <- close_block_summary(client, "410390020001010")
again <- close_block_summary(client, "410390020001010", if_none_match = first$etag)
if (isTRUE(again$not_modified)) {
  # your cached copy is still current; nothing was charged
}
```

## Isochrones

```r
iso <- close_isochrone(client, block = "410390020001010",
                       contours = c(15, 30, 45), mode = "walk", direction = "to")
for (f in iso$data$features) {
  cat(f$properties$contour, f$properties$reachable_blocks, "\n")
}
```

## Errors

Errors are [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) `problem+json`,
raised as classed conditions. Catch the base `close_api_error` or a specific
`close_api_<slug>`; every condition carries `slug`, `status`, `title`, `detail`,
`request_id`, and (when present) `retry_after`:

```r
tryCatch(
  close_block_summary(client, "000000000000000"),
  close_api_tokens_exhausted = function(e) message("buy more tokens"),
  close_api_error = function(e) {
    message(sprintf("%s (%d) — request %s", e$slug, e$status, e$request_id))
  }
)
```

## Spatial output

With `sf` installed, convert any reply to an `sf` object — POIs become points,
isochrones become polygons, and block replies join census-block boundaries
(`tigris`):

```r
pts <- close_as_sf(close_pois_search(client, lat = 41.823, lon = -71.412,
                                     radius_m = 1500))
iso <- close_as_sf(close_isochrone(client, block = "440070036001010", minutes = 15))
```

## Reference

- Documentation: <https://henryspatialanalysis.github.io/closecity-r/>
- Interactive API: <https://api.close.city/docs>
- Machine-readable contract: <https://api.close.city/openapi.json>

## Development

```r
# with the deps installed (httr2, jsonlite, rlang, testthat):
testthat::test_local(".")   # unit tests, no network (httr2 mocking)
```
