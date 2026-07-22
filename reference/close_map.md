# Interactive map of Close spatial results

Draw the [sf](https://r-spatial.github.io/sf/reference/sf.html) object a
client method returns as an interactive map on a CARTO Positron basemap.
Points (POIs, places) render as bright hoverable markers; polygons
(census blocks) are filled, optionally greying the features that do not
meet a criterion so the ones that matter stand out.

## Usage

``` r
close_map(
  x,
  color = "#e8590c",
  highlight = NULL,
  fill = NULL,
  palette = "Viridis",
  reverse = TRUE,
  label = "name",
  size = 9,
  zoom = 10,
  opacity = 0.65
)
```

## Arguments

- x:

  An [sf](https://r-spatial.github.io/sf/reference/sf.html) from a
  client method — points or polygons.

- color:

  Marker/fill colour for flat features (or for highlighted ones).

- highlight:

  Optional. A logical vector (length `nrow(x)`) or the name of a
  logical/0-1 column in `x`. When supplied, features that do not meet it
  render grey (`#888`) and the rest use `color` — so you can show every
  block in a study area and pick out the matches, rather than dropping
  the others.

- fill:

  Optional. The name of a numeric column to shade features by, on a
  continuous scale with a legend (e.g. travel time, or an access score).
  Use this OR `highlight`, not both.

- palette:

  A plotly colorscale name for `fill` (default `"Viridis"`).

- reverse:

  Reverse the `fill` colorscale (default `TRUE`, so smaller values —
  e.g. shorter travel times — are the bright end).

- label:

  Column shown on hover (default `"name"`).

- size:

  Marker size, for point maps.

- zoom:

  Initial zoom level.

- opacity:

  Fill opacity, for polygon maps.

## Value

A [plotly](https://rdrr.io/pkg/plotly/man/plot_ly.html) htmlwidget.

## Examples

``` r
if (FALSE) { # \dontrun{
close <- close_client()
close_map(close$place_pois("4459000", type = 30), color = "#e8590c")
} # }
```
