# Interactive map of Close spatial results

Draw the [sf](https://r-spatial.github.io/sf/reference/sf.html) object a
client method returns as an interactive map on a CARTO Positron basemap.
Points (POIs, places) render as bright hoverable markers; polygons
(census blocks) are filled, optionally greying the features that do not
meet a criterion so the ones that matter stand out. The view auto-zooms
to fit every layer with a margin, and hover shows all attributes.

## Usage

``` r
close_map(
  x,
  color = "#e8590c",
  highlight = NULL,
  fill = NULL,
  palette = "YlGnBu",
  reverse = FALSE,
  label = NULL,
  size = 15,
  opacity = 0.65,
  boundary = NULL,
  background = NULL,
  background_color = "#3b6fb0",
  background_opacity = 0.3,
  mark = NULL,
  buffer = 0.15,
  zoom = NULL
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
  continuous ColorBrewer scale with a legend (e.g. travel time, or an
  access score). Use this OR `highlight`, not both.

- palette:

  A plotly ColorBrewer colorscale name for `fill` (default `"YlGnBu"`).

- reverse:

  Which end of the `YlGnBu` scale is blue. `FALSE` (default) puts blue
  at the low values, `TRUE` at the high values. Choose so blue marks the
  most-accessible end: `FALSE` for travel time (low is best), `TRUE` for
  a score.

- label:

  Optional. A column shown first (bold) in the hover; the rest of the
  attributes follow.

- size:

  Marker size, for point maps.

- opacity:

  Fill opacity, for polygon maps.

- boundary:

  Optional. A polygon
  [sf](https://r-spatial.github.io/sf/reference/sf.html) drawn as a grey
  outline underneath the data — e.g. a city boundary from
  `place_boundary()`.

- background:

  Optional. A polygon
  [sf](https://r-spatial.github.io/sf/reference/sf.html), or a list of
  them, drawn as semi-transparent fills underneath the data — e.g.
  commute isochrones, or a walkshed under its POIs.

- background_color:

  Fill colour(s) for `background`, recycled across the layers.

- background_opacity:

  Fill opacity for `background` layers.

- mark:

  Optional. A point to mark on top with an X — either a `c(lon, lat)`
  pair or a point
  [sf](https://r-spatial.github.io/sf/reference/sf.html)/`sfc` (e.g. a
  starting point).

- buffer:

  Fraction of the data extent to pad the view by (default 0.15).

- zoom:

  Deprecated/ignored; the view auto-zooms to the data.

## Value

A plotly map object.

## Examples

``` r
if (FALSE) { # \dontrun{
close <- close_client()
close_map(close$place_pois(geoid = "4459000", type = 30), color = "#e8590c")
} # }
```
