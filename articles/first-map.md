# Your first walkability map

The quickest way to feel what Close gives you: read one block’s travel
times, map the supermarkets around it, then draw how far you can walk
from it. The example city is Providence, Rhode Island.

*Running this tutorial uses about 85 tokens.*

## Set up

Build a client, then read what you need from the free catalog.

``` r

library(closecity)
close <- close_client("ck_live_your_key")   # use your own key here
```

``` r

types <- close$destination_types()
supermarket_dest_type <- types[types$label == "grocery_stores", ]$dest_type_id

providence_ri <- close$places("Providence")[1, ]
```

## Read one block’s travel times

Pick a block and ask how long it takes to walk to each kind of amenity.
Join the catalog’s readable `name` and sort by time, so the nearest
things are on top.

``` r

walk_times <- close$block_summary("440070008001068", mode = "walk")
walk_times <- merge(walk_times, types[, c("dest_type_id", "name")],
                    by = "dest_type_id")
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

## Map the supermarkets nearby

[`close_map()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_map.md)
draws the result on an interactive basemap in one line — bright,
hoverable points here.

``` r

supermarkets <- close$pois_search(lat = providence_ri$lat, lon = providence_ri$lon,
                                  radius_m = 1200, type = supermarket_dest_type)
close_map(supermarkets, color = "#e8590c")
```

## Draw how far you can walk

An isochrone is the headline map: the area you can reach on foot in 10,
20, and 30 minutes. Shade it by the `contour` minutes and the nearer
times stand out.

``` r

rings <- close$isochrone(block = "440070008001068", mode = "walk",
                         direction = "from", contours = c(10, 20, 30))
close_map(rings, fill = "contour")
```

## Walk versus transit

The same block and the same 30-minute budget, on foot and by bus — the
clearest way to see what transit buys you.

``` r

walk <- close$isochrone(block = "440070008001068", mode = "walk",
                        direction = "from", minutes = 30)
transit <- close$isochrone(block = "440070008001068", mode = "transit",
                           direction = "from", minutes = 30)

close_map(walk, color = "#058040")
```

``` r

close_map(transit, color = "#202a5b")
```

## Where to next

- **Looking for a home**: find blocks near several amenities at once,
  then narrow to a commute.
- **The amenity basket**: population-weighted walkability coverage
  across a whole city.
- **Competitor walksheds**: who else draws from your neighbourhood.
