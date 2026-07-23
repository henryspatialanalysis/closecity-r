# Get started with closecity

`closecity` reads the Close API: travel times from every US census block
to nearby places, on foot, by bike, and by public transit. This vignette
is a short tour. The three tutorials go further. The full list of query
methods is on the
[`CloseClient`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.md)
reference page, and the wider API is documented at
[docs.close.city](https://docs.close.city).

## Key terms

A few terms come up throughout:

- **Census block.** The smallest area the Census Bureau publishes. Each
  one has a 15-digit id, its **GEOID**. Block GEOIDs come from the
  census — look them up with the `tigris` or `tidycensus` packages, the
  Census Bureau geocoder/API, or read them straight off Close’s block
  routes (`$blocks_query()`, `$place_blocks()`).
- **Destination type.** A category of place, such as grocery stores or
  libraries. Every type has a numeric id.
- **Mode.** How someone travels: walk, bike, or transit.
- **Isochrone** or **catchment**: the area you can reach starting from a
  point within a time limit, by a selected travel mode.

## Travel times

Times to nearby places are **capped at 30 minutes** for each mode, and
recorded in **whole minutes**. A missing time means the place is not
reachable within the cap, not that it is zero. Isochrones are the
exception: they are available for any budget up to an hour.

## Build a client

You make every request through a client object.

``` r

library(closecity)
close <- closecity::close_client(api_key = "ck_live_your_key")   # use your own key here
```

The catalog and lookup routes are free, so
[`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md)
with no key also works for those.

``` r

close$modes()
#>   mode_id    mode    description
#> 1       1    walk        Walking
#> 2       2    bike         Biking
#> 3       3 transit Public transit
```

## Look things up instead of guessing

Two free calls save you from memorising codes. Both come back as data
frames, so you filter and index them the usual way: read the numeric id
for a category from the catalog, and turn a city name into a GEOID and a
centre point.

``` r

amenity_types <- close$destination_types()
supermarket_type <- amenity_types[amenity_types$label == "grocery_stores", ]$dest_type_id

providence_ri <- close$places(q = "Providence")[1, ]
providence_ri[, c("name", "state", "geoid")]
#> Simple feature collection with 1 feature and 3 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -71.41872 ymin: 41.82301 xmax: -71.41872 ymax: 41.82301
#> Geodetic CRS:  WGS 84
#>         name state   geoid                   geometry
#> 1 Providence    RI 4459000 POINT (-71.41872 41.82301)
```

The catalog’s `name` column is the readable label (“Grocery stores”);
the underscored `label` is the internal key you match on. A place lookup
carries a `state`, so you can tell Providence, RI from the one in Utah.
When you have a point rather than a block,
`$point_summary(lat = , lon = )` reads the same travel times for a
`lat`/`lon` starting point instead of a GEOID.

## Make a call and map it

Routes with geometry return an [sf](https://r-spatial.github.io/sf/)
object.
[`close_map()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_map.md)
draws it on an interactive basemap in one line — bright, hoverable
points here, with the city boundary behind them and the view zoomed to
fit.

``` r

supermarkets <- close$place_pois(geoid = providence_ri$geoid, type = supermarket_type)
city_boundary <- close$place_boundary(geoid = providence_ri$geoid)
closecity::close_map(
  x = supermarkets,
  color = "#e8590c",
  boundary = city_boundary,
  label = "name"
)
```

## Choose an output

Every route returns tabular data by default: an sf object for inherently
spatial data, a data frame otherwise. The `output` setting changes the
shape — `"tabular"` never downloads boundaries, and `"raw"` gives the
underlying reply with its metering and cursor fields. Set it on the
client, or pass `output =` to one call.

A block summary, with the readable category names merged on and sorted
by time:

``` r

walk_times <- close$block_summary(geoid = "440070008001068", mode = "walk")
walk_times <- merge(
  walk_times,
  amenity_types[, c("dest_type_id", "name")],
  by = "dest_type_id"
)
walk_times[order(walk_times$travel_time), c("name", "travel_time")]
#>                                name travel_time
#> 18                All transit stops           2
#> 27       Non-frequent transit stops           2
#> 28 Non-frequent other transit stops           2
#> 29              Other transit stops           2
#> 5                       Restaurants           3
#> 6                              Bars           3
#> 9            Cafes and coffee shops           3
#> 17                        Libraries           3
#> 19                            Parks           3
#> 23               Parks (<0.5 acres)           3
#> 32                 Public libraries           3
#> 20              Parks (0.5–1 acres)           4
#> 30               Parks (>0.5 acres)           4
#> 8                    Grocery stores           6
#> 21               Parks (1–10 acres)           7
#> 31                  Parks (>1 acre)           7
#> 15                       Bookstores           8
#> 7                Convenience stores           9
#> 12                       Pharmacies           9
#> 16                       Bike shops           9
#> 33     University/private libraries           9
#> 1                    Public schools          10
#> 4                      High schools          10
#> 24                      Playgrounds          10
#> 13                       Preschools          13
#> 22                Parks (>10 acres)          13
#> 25                         Bakeries          14
#> 10                         Dentists          15
#> 14                Community centers          17
#> 11        Gyms and exercise studios          18
#> 3                    Middle schools          22
#> 26                  Hardware stores          24
#> 2                Elementary schools          26
```

…and the same call as the raw reply, whose `results` you can inspect
yourself:

``` r

raw <- close$block_summary(geoid = "440070008001068", mode = "walk", output = "raw")
str(raw$results, max.level = 2, list.len = 3)
#> List of 33
#>  $ :List of 3
#>   ..$ dest_type_id: int 1
#>   ..$ mode        : chr "walk"
#>   ..$ travel_time : num 10
#>  $ :List of 3
#>   ..$ dest_type_id: int 5
#>   ..$ mode        : chr "walk"
#>   ..$ travel_time : num 26
#>  $ :List of 3
#>   ..$ dest_type_id: int 6
#>   ..$ mode        : chr "walk"
#>   ..$ travel_time : num 22
#>   [list output truncated]
```

## The client methods

Every data-getting method lives on the client. Follow any name to its
arguments and return value on the
[`CloseClient`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.md)
reference page.

Catalog and lookups (free, no key):

- [`$modes()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-modes)
  — the travel modes: walk, bike, transit.
- [`$destination_types()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-destination_types)
  — the catalog of amenity categories and their numeric ids.
- [`$places()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-places)
  — a city name to its GEOID and centre point.
- [`$place_boundary()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-place_boundary)
  — the boundary polygon of a census place.
- [`$vintage()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-vintage)
  — the data vintage.
- [`$last_updated()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-last_updated)
  — when the data was last refreshed.
- [`$isochrone_meta()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-isochrone_meta)
  — isochrone modes, directions, and assumptions.
- [`$health()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-health)
  — a service health check.

Travel times from a block or a point:

- [`$block_summary()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-block_summary)
  — walk/bike/transit time from a block to each amenity type.
- [`$point_summary()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-point_summary)
  — the same, from a `lat`/`lon` point.
- [`$block_pois()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-block_pois)
  — the individual POIs reachable from a block, each with its travel
  time.
- [`$point_pois()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-point_pois)
  — the same, from a `lat`/`lon` point.

Points of interest:

- [`$pois_search()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-pois_search)
  — search POIs by radius or bounding box.
- [`$poi()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-poi)
  — the details of one POI.
- [`$poi_catchment()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-poi_catchment)
  — the blocks that can walk to a POI (its catchment).

Whole areas:

- [`$blocks_query()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-blocks_query)
  — per-block travel times for a polygon, or a centre and radius.
- [`$place_blocks()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-place_blocks)
  — per-block travel times for every block in a place.
- [`$place_pois()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-place_pois)
  — every POI within a place’s boundary.
- [`$isochrone()`](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.html#method-CloseClient-isochrone)
  — travel-time contours from a block or a point.

## Handle errors

Failed requests raise a classed condition. Catch the base
`close_api_error`, or a specific one.

``` r

tryCatch(
  close$block_summary(geoid = "000000000000000"),
  close_api_error = function(e) message(sprintf("%s (%d)", e$slug, e$status))
)
#> block-not-found (404)
```
