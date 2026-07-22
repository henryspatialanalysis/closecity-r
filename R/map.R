# A one-line interactive map for the sf objects the client methods return, so
# tutorials (and users) can see results without wiring up a plotting stack.
# Built on plotly over a CARTO Positron basemap: points become bright hoverable
# markers, block polygons are filled and can highlight the features that meet a
# criterion. GDAL-free (plotly + geojsonsf), unlike leaflet/mapgl.

#' Interactive map of Close spatial results
#'
#' Draw the [sf][sf::sf] object a client method returns as an interactive map on
#' a CARTO Positron basemap. Points (POIs, places) render as bright hoverable
#' markers; polygons (census blocks) are filled, optionally greying the features
#' that do not meet a criterion so the ones that matter stand out.
#'
#' @param x An [sf][sf::sf] from a client method — points or polygons.
#' @param color Marker/fill colour for flat features (or for highlighted ones).
#' @param highlight Optional. A logical vector (length `nrow(x)`) or the name of
#'   a logical/0-1 column in `x`. When supplied, features that do not meet it
#'   render grey (`#888`) and the rest use `color` — so you can show every block
#'   in a study area and pick out the matches, rather than dropping the others.
#' @param fill Optional. The name of a numeric column to shade features by, on a
#'   continuous scale with a legend (e.g. travel time, or an access score). Use
#'   this OR `highlight`, not both.
#' @param palette A plotly colorscale name for `fill` (default `"Viridis"`).
#' @param reverse Reverse the `fill` colorscale (default `TRUE`, so smaller
#'   values — e.g. shorter travel times — are the bright end).
#' @param label Column shown on hover (default `"name"`).
#' @param size Marker size, for point maps.
#' @param zoom Initial zoom level.
#' @param opacity Fill opacity, for polygon maps.
#' @return A [plotly][plotly::plot_ly] htmlwidget.
#' @examples
#' \dontrun{
#' close <- close_client()
#' close_map(close$place_pois("4459000", type = 30), color = "#e8590c")
#' }
#' @export
close_map <- function(x, color = "#e8590c", highlight = NULL, fill = NULL,
                      palette = "Viridis", reverse = TRUE, label = "name",
                      size = 9, zoom = 10, opacity = 0.65) {
  if (!requireNamespace("plotly", quietly = TRUE)) {
    stop("close_map() needs the plotly package: install.packages('plotly')")
  }
  x <- sf::st_transform(x, 4326)
  hl <- NULL
  if (!is.null(highlight)) {
    hl <- if (is.character(highlight) && length(highlight) == 1L &&
              highlight %in% names(x)) as.logical(x[[highlight]])
          else as.logical(highlight)
  }
  fv <- if (!is.null(fill) && fill %in% names(x)) as.numeric(x[[fill]]) else NULL
  bb <- sf::st_bbox(x)
  centre <- list(lon = mean(c(bb[["xmin"]], bb[["xmax"]])),
                 lat = mean(c(bb[["ymin"]], bb[["ymax"]])))
  hover <- if (label %in% names(x)) as.character(x[[label]]) else NULL

  if (any(grepl("POINT", as.character(sf::st_geometry_type(x))))) {
    xy <- sf::st_coordinates(x)
    if (!is.null(fv)) {
      marker <- list(size = size, color = fv, colorscale = palette,
                     reversescale = reverse, showscale = TRUE,
                     colorbar = list(title = fill))
    } else {
      cols <- if (is.null(hl)) color else ifelse(hl, color, "#888888")
      marker <- list(size = size, color = cols)
    }
    p <- plotly::plot_ly(
      lat = xy[, 2], lon = xy[, 1], type = "scattermapbox", mode = "markers",
      marker = marker, text = hover,
      hoverinfo = if (is.null(hover)) "none" else "text"
    )
  } else {
    x[["feature_id"]] <- as.character(seq_len(nrow(x)))
    gj <- jsonlite::fromJSON(
      geojsonsf::sf_geojson(x[, "feature_id"]), simplifyVector = FALSE
    )
    common <- list(
      type = "choroplethmapbox", geojson = gj, locations = x[["feature_id"]],
      featureidkey = "properties.feature_id",
      marker = list(opacity = opacity, line = list(width = 0)),
      text = hover, hoverinfo = if (is.null(hover)) "none" else "text"
    )
    if (!is.null(fv)) {
      args <- c(common, list(z = fv, colorscale = palette,
                             reversescale = reverse, showscale = TRUE,
                             colorbar = list(title = fill)))
    } else {
      z <- if (is.null(hl)) rep(1, nrow(x)) else as.integer(hl)
      scale <- if (is.null(hl)) list(list(0, color), list(1, color))
               else list(list(0, "#888888"), list(1, color))
      args <- c(common, list(z = z, colorscale = scale, showscale = FALSE))
    }
    p <- do.call(plotly::plot_ly, args)
  }
  plotly::layout(
    p,
    mapbox = list(style = "carto-positron", zoom = zoom, center = centre),
    margin = list(l = 0, r = 0, t = 0, b = 0)
  )
}
