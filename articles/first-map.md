# Your first walkability map

The quickest way to feel what Close gives you: read the walk times from
a starting point, map the supermarkets you can reach on foot, then draw
how far a 30-minute walk takes you. The example city is Providence,
Rhode Island.

*Running this tutorial uses about 90 tokens.*

## Set up

Build a client, then read what you need from the free catalog.

``` r

library(closecity)
close <- closecity::close_client(api_key = "ck_live_your_key")   # use your own key here
```

``` r

amenity_types <- close$destination_types()
supermarket_type <- amenity_types[amenity_types$label == "grocery_stores", ]$dest_type_id

providence_ri <- close$places(q = "Providence")[1, ]
start_lon <- providence_ri$lon
start_lat <- providence_ri$lat
```

## Read travel times from a starting point

Pick a starting point — here the centre of Providence — and ask how long
it takes to walk to each kind of amenity. `$point_summary()` takes a
`lat`/`lon` instead of a block GEOID. Join the catalog’s readable `name`
and sort by time, so the nearest things are on top.

``` r

walk_times <- close$point_summary(lat = start_lat, lon = start_lon, mode = "walk")
walk_times <- merge(
  walk_times,
  amenity_types[, c("dest_type_id", "name")],
  by = "dest_type_id"
)
walk_times[order(walk_times$travel_time), c("name", "travel_time")]
#>                                name travel_time
#> 18                All transit stops           0
#> 27       Non-frequent transit stops           0
#> 28 Non-frequent other transit stops           0
#> 29              Other transit stops           0
#> 5                       Restaurants           1
#> 9            Cafes and coffee shops           1
#> 19                            Parks           2
#> 23               Parks (<0.5 acres)           2
#> 6                              Bars           3
#> 17                        Libraries           3
#> 32                 Public libraries           3
#> 8                    Grocery stores           6
#> 20              Parks (0.5–1 acres)           6
#> 21               Parks (1–10 acres)           6
#> 30               Parks (>0.5 acres)           6
#> 31                  Parks (>1 acre)           6
#> 12                       Pharmacies           7
#> 15                       Bookstores           8
#> 16                       Bike shops           8
#> 7                Convenience stores           9
#> 24                      Playgrounds           9
#> 33     University/private libraries           9
#> 1                    Public schools          11
#> 4                      High schools          11
#> 22                Parks (>10 acres)          12
#> 13                       Preschools          13
#> 25                         Bakeries          13
#> 14                Community centers          14
#> 10                         Dentists          15
#> 11        Gyms and exercise studios          18
#> 3                    Middle schools          21
#> 2                Elementary schools          25
#> 26                  Hardware stores          25
```

## Map the supermarkets within a 30-minute walk

A 30-minute walk is a travel-time question, not a distance one, so let
the routing answer it directly: `$point_pois()` returns every POI
reachable from the starting point within `max_minutes`, each carrying
its walk time — no isochrone to overlay.
[`close_map()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_map.md)
draws the result on an interactive basemap in one line, with the city
boundary behind it for context.

``` r

nearby_supermarkets <- close$point_pois(
  lat = start_lat,
  lon = start_lon,
  mode = "walk",
  type = supermarket_type,
  max_minutes = 30
)

city_boundary <- close$place_boundary(geoid = providence_ri$geoid)
closecity::close_map(
  x = nearby_supermarkets,
  color = "#e8590c",
  boundary = city_boundary,
  label = "name",
  mark = c(start_lon, start_lat)
)
```

## Draw how far you can walk

An isochrone is the headline map: the area you can reach on foot in 10,
20, and 30 minutes. Shade it by the `contour` minutes; blue marks the
nearest, most-reachable ring.

``` r

rings <- close$isochrone(
  lon = start_lon,
  lat = start_lat,
  mode = "walk",
  direction = "from",
  contours = c(10, 20, 30),
  format = "geojson"
)
closecity::close_map(x = rings, fill = "contour", reverse = TRUE)
```

## Walk versus transit

The same starting point and the same 30-minute budget, on foot and by
bus — the clearest way to see what transit buys you.

``` r

walk <- close$isochrone(
  lon = start_lon,
  lat = start_lat,
  mode = "walk",
  direction = "from",
  minutes = 30,
  format = "geojson"
)
transit <- close$isochrone(
  lon = start_lon,
  lat = start_lat,
  mode = "transit",
  direction = "from",
  minutes = 30,
  format = "geojson"
)

closecity::close_map(x = walk, color = "#058040")
```

``` r

closecity::close_map(x = transit, color = "#202a5b")
```

## Where to next

- **Looking for a home**: find blocks near several amenities at once,
  then narrow to a commute.
- **The amenity basket**: population-weighted walkability coverage
  across a whole city.
- **Competitor walksheds**: who else draws from your neighbourhood.
  \`\`\`
