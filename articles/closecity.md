# Get started with closecity

`closecity` reads the Close API: travel times from every US census block
to nearby places, on foot, by bike, and by public transit. This vignette
is a short tour. The three tutorials go further.

## Key terms

A few terms come up throughout:

- **Census block.** The smallest area the Census Bureau publishes. Each
  one has a 15-digit id, its **GEOID**.
- **Destination type.** A category of place, such as grocery stores or
  libraries. Every type has a numeric id.
- **Mode.** How someone travels: walk, bike, or transit.
- **Isochrone** or **catchment.** Two views of the same reachability:
  the area reachable from a point within a time limit (an isochrone), or
  every block that can reach a given place (a catchment).

## Travel times

Times to nearby places are **capped at 30 minutes** for each mode, and
recorded in **whole minutes**. A missing time means the place is not
reachable within the cap, not that it is zero. Isochrones are the
exception: they are available for any budget up to an hour.

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

types <- close$destination_types()
supermarket_dest_type <- types[types$label == "grocery_stores", ]$dest_type_id

providence_ri <- close$places("Providence")[1, ]
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

## Make a call and map it

Routes with geometry return an [sf](https://r-spatial.github.io/sf/)
object.
[`close_map()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_map.md)
draws it on an interactive basemap in one line — bright, hoverable
points here.

``` r

supermarkets <- close$place_pois(providence_ri$geoid, type = supermarket_dest_type)
close_map(supermarkets, color = "#e8590c")
```

## Choose an output

Every route returns tabular data by default: an sf object where geometry
applies, a data frame otherwise. The `output` setting changes the shape
— `"tabular"` never downloads boundaries, and `"raw"` gives the
underlying reply with its metering and cursor fields. Set it on the
client, or pass `output =` to one call.

The same block summary as a data frame (the default):

``` r

close$block_summary("440070008001068", mode = "walk")
#>              geoid dest_type_id mode travel_time
#> 1  440070008001068            1 walk          10
#> 2  440070008001068            5 walk          26
#> 3  440070008001068            6 walk          22
#> 4  440070008001068            7 walk          10
#> 5  440070008001068           27 walk           3
#> 6  440070008001068           28 walk           3
#> 7  440070008001068           29 walk           9
#> 8  440070008001068           30 walk           6
#> 9  440070008001068           31 walk           3
#> 10 440070008001068           32 walk          15
#> 11 440070008001068           33 walk          18
#> 12 440070008001068           34 walk           9
#> 13 440070008001068           35 walk          13
#> 14 440070008001068           38 walk          17
#> 15 440070008001068           40 walk           8
#> 16 440070008001068           41 walk           9
#> 17 440070008001068           43 walk           3
#> 18 440070008001068           60 walk           2
#> 19 440070008001068           63 walk           3
#> 20 440070008001068           64 walk           4
#> 21 440070008001068           65 walk           7
#> 22 440070008001068           66 walk          13
#> 23 440070008001068           67 walk           3
#> 24 440070008001068          126 walk          10
#> 25 440070008001068          159 walk          14
#> 26 440070008001068          160 walk          24
#> 27 440070008001068          200 walk           2
#> 28 440070008001068          204 walk           2
#> 29 440070008001068          205 walk           2
#> 30 440070008001068          206 walk           4
#> 31 440070008001068          207 walk           7
#> 32 440070008001068          208 walk           3
#> 33 440070008001068          209 walk           9
```

…and as the raw reply, whose `results` you can index yourself:

``` r

raw <- close$block_summary("440070008001068", mode = "walk", output = "raw")
head(raw$results, 3)
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
