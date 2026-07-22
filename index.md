# closecity

R client for the Close API. Get travel times from every US census block
to nearby places, on foot, by bike, and by public transit. This is the
data behind [close.city](https://close.city), read over the [Close
API](https://api.close.city).

**Documentation:** <https://henryspatialanalysis.github.io/closecity-r/>

## Install

``` r

# install.packages("remotes")
remotes::install_github("henryspatialanalysis/closecity-r")
```

## A first call

You make requests through a client object. Feature results come back as
[sf](https://r-spatial.github.io/sf/) objects, so you can map them right
away.

``` r

library(closecity)
# The key (ck_live_) comes from https://account.close.city (5,000 free tokens,
# no card). Or set the CLOSECITY_KEY environment variable and call
# close_client() with no argument.
close <- close_client("ck_live_your_key")   # use your own key here
```

``` r

# Supermarkets within a 1.5 km walk of a point (type 30 is grocery stores):
supermarkets <- close$pois_search(lat = 41.823, lon = -71.412, radius_m = 1500, type = 30)
plot(sf::st_geometry(supermarkets), pch = 19, col = "#e8590c")
```

![Supermarkets near downtown Providence, drawn as
points.](reference/figures/README-first-call-1.png)

The tutorials draw results as one-line interactive maps with
[`close_map()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_map.md)
(bright hoverable points, or blocks shaded by travel time), on a CARTO
Positron basemap.

Catalog and lookup routes are free and need no key:

``` r

close$modes()                    # walk, bike, transit
#>   mode_id    mode    description
#> 1       1    walk        Walking
#> 2       2    bike         Biking
#> 3       3 transit Public transit
close$places("Providence")       # a city name to its GEOID and centre
#> Simple feature collection with 9 features and 5 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -111.8133 ymin: 32.34238 xmax: -71.35821 ymax: 42.28133
#> Geodetic CRS:  WGS 84
#>                 name   geoid state        lon      lat
#> 1         Providence 4459000    RI  -71.41872 41.82301
#> 2         Providence 4962360    UT -111.81331 41.70341
#> 3 Providence Village 4859748    TX  -96.95432 33.23890
#> 4         Providence 2163372    KY  -87.75094 37.39935
#> 5         Providence 0162688    AL  -87.77611 32.34238
#> 6    East Providence 4422960    RI  -71.35821 41.80049
#> 7     New Providence 3451810    NJ  -74.40343 40.69964
#> 8    Lake Providence 2241400    LA  -91.18247 32.81322
#> 9     New Providence 1956415    IA  -93.17162 42.28133
#>                     geometry
#> 1 POINT (-71.41872 41.82301)
#> 2 POINT (-111.8133 41.70341)
#> 3  POINT (-96.95432 33.2389)
#> 4 POINT (-87.75094 37.39935)
#> 5 POINT (-87.77611 32.34238)
#> 6 POINT (-71.35821 41.80049)
#> 7 POINT (-74.40343 40.69964)
#> 8 POINT (-91.18247 32.81322)
#> 9 POINT (-93.17162 42.28133)
```

## Key terms

- **Census block.** The smallest area the Census Bureau publishes. Each
  one has a 15-digit id called a **GEOID**.
- **Destination type.** A category of place, such as grocery stores or
  libraries. Each type has a numeric id. Look them up with
  `close$destination_types()`.
- **Mode.** How someone travels: walk, bike, or transit.
- **Isochrone** or **catchment.** Two views of the same reachability:
  the area you can reach from a point within a time limit (an
  isochrone), or every block that can reach a place (a catchment).

## Choosing an output

Set `output` on the client, or per call:

- `output = "spatial"` (the default) returns an `sf` object where
  geometry applies and a `data.frame` otherwise. Block routes join
  census-block boundaries with the `tigris` package, downloaded once and
  cached.
- `output = "tabular"` returns a `data.frame` for every route and never
  downloads boundaries. Reach for it when you only want the numbers.
- `output = "raw"` returns the underlying `close_reply`, with the parsed
  body on `$data` and the token counts alongside.

``` r

close$output <- "raw"
reply <- close$block_summary("440070008001068", mode = "walk")
reply$results
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

## Handling errors

Failed requests raise a classed condition. Catch the base
`close_api_error`, or a specific one such as
`close_api_tokens_exhausted`.

``` r

tryCatch(
  close$block_summary("000000000000000"),
  close_api_error = function(e) message(sprintf("%s (%d)", e$slug, e$status))
)
#> block-not-found (404)
```

The client does not retry automatically. On a rate-limit or
service-unavailable error, wait `e$retry_after` seconds (from the
`Retry-After` header) and retry the request yourself.

## Reference

- Documentation: <https://henryspatialanalysis.github.io/closecity-r/>
- Interactive API: <https://api.close.city/docs>
- Machine-readable contract: <https://api.close.city/openapi.json>
