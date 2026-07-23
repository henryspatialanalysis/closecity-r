# A one-line interactive map for the sf objects the client methods return, so
# tutorials (and users) can see results without wiring up a plotting stack.
# Built on plotly over a CARTO Positron basemap: points become bright hoverable
# markers, block polygons are filled and can highlight the features that meet a
# criterion. The view auto-zooms to the data, hover shows every attribute, and a
# city boundary outline or semi-transparent background layers can sit underneath.
# GDAL-free (plotly + geojsonsf), unlike leaflet/mapgl.

# "YlGnBu" truncated to its 10-90% range — the extreme dark-blue and pale-yellow
# look jarring on the pale basemap. Ordered to match plotly's named "YlGnBu" in a
# trace (position 0 is the blue end), so `reverse` behaves the same as before.
.close_ylgnbu <- list(
  list(0.000, "rgb(31, 47, 136)"), list(0.125, "rgb(35, 77, 160)"),
  list(0.250, "rgb(32, 114, 178)"), list(0.375, "rgb(36, 152, 193)"),
  list(0.500, "rgb(65, 182, 196)"), list(0.625, "rgb(115, 200, 189)"),
  list(0.750, "rgb(170, 222, 183)"), list(0.875, "rgb(214, 239, 179)"),
  list(1.000, "rgb(241, 249, 185)")
)
.close_scale <- function(palette) {
  if (identical(palette, "YlGnBu")) .close_ylgnbu else palette
}

# hex + alpha -> "rgba(r, g, b, a)" for plotly fill/line colours.
.close_rgba <- function(hex, alpha) {
  v <- grDevices::col2rgb(hex)
  sprintf("rgba(%d, %d, %d, %s)", v[1], v[2], v[3], format(alpha))
}

# A centre and zoom that frame every layer's bounding box, plus a margin.
.close_center_zoom <- function(boxes, buffer) {
  minx <- min(vapply(boxes, function(b) b[["xmin"]], numeric(1)))
  miny <- min(vapply(boxes, function(b) b[["ymin"]], numeric(1)))
  maxx <- max(vapply(boxes, function(b) b[["xmax"]], numeric(1)))
  maxy <- max(vapply(boxes, function(b) b[["ymax"]], numeric(1)))
  span <- max(maxx - minx, maxy - miny, 0.005) * (1 + 2 * buffer)
  list(
    center = list(lon = mean(c(minx, maxx)), lat = mean(c(miny, maxy))),
    zoom = max(1, min(16, log2(360 / span) - 0.5))
  )
}

# Exterior/ring coordinates of a polygon layer as one lon/lat path, NA-split so
# plotly draws each ring as its own subpath.
.close_polygon_lines <- function(x) {
  co <- sf::st_coordinates(sf::st_geometry(x))
  grp_cols <- setdiff(colnames(co), c("X", "Y"))
  key <- do.call(paste, c(as.data.frame(co)[grp_cols], sep = "-"))
  lon <- numeric(0); lat <- numeric(0)
  for (k in unique(key)) {
    idx <- key == k
    lon <- c(lon, co[idx, "X"], NA)
    lat <- c(lat, co[idx, "Y"], NA)
  }
  list(lon = lon, lat = lat)
}

# One hover string per row: every non-geometry attribute, `label` first (bold).
# Robust to list/nested columns (e.g. a POI `address`), which get flattened to a
# single comma-joined string.
.close_hover <- function(x, label) {
  df <- sf::st_drop_geometry(x)
  cols <- names(df)
  if (!is.null(label) && label %in% cols) cols <- c(label, setdiff(cols, label))
  vapply(seq_len(nrow(df)), function(i) {
    parts <- vapply(cols, function(c) {
      val <- df[[c]][[i]]
      if (is.numeric(val)) val <- round(val, 5)
      val <- toString(unlist(val))
      if (!is.null(label) && c == label) sprintf("<b>%s</b>", val)
      else sprintf("%s: %s", c, val)
    }, character(1))
    paste(parts, collapse = "<br>")
  }, character(1))
}

#' Interactive map of Close spatial results
#'
#' Draw the [sf][sf::sf] object a client method returns as an interactive map on
#' a CARTO Positron basemap. Points (POIs, places) render as bright hoverable
#' markers; polygons (census blocks) are filled, optionally greying the features
#' that do not meet a criterion so the ones that matter stand out. The view
#' auto-zooms to fit every layer with a margin, and hover shows all attributes.
#'
#' @param x An [sf][sf::sf] from a client method: points or polygons.
#' @param color Marker/fill colour for flat features (or for highlighted ones).
#' @param highlight Optional. A logical vector (length `nrow(x)`) or the name of
#'   a logical/0-1 column in `x`. When supplied, features that do not meet it
#'   render grey (`#888`) and the rest use `color`, so you can show every block
#'   in a study area and pick out the matches, rather than dropping the others.
#' @param fill Optional. The name of a numeric column to shade features by, on a
#'   continuous ColorBrewer scale with a legend (e.g. travel time, or an access
#'   score). Use this OR `highlight`, not both.
#' @param palette A plotly ColorBrewer colorscale name for `fill` (default
#'   `"YlGnBu"`).
#' @param reverse Which end of the `YlGnBu` scale is blue. `FALSE` (default) puts
#'   blue at the low values, `TRUE` at the high values. Choose so blue marks the
#'   most-accessible end: `FALSE` for travel time (low is best), `TRUE` for a score.
#' @param label Optional. A column shown first (bold) in the hover; the rest of
#'   the attributes follow.
#' @param size Marker size, for point maps.
#' @param opacity Fill opacity, for polygon maps.
#' @param boundary Optional. A polygon [sf][sf::sf] drawn as a grey outline
#'   underneath the data, e.g. a city boundary from `place_boundary()`.
#' @param background Optional. A polygon [sf][sf::sf], or a list of them, drawn
#'   as semi-transparent fills underneath the data, e.g. commute isochrones, or
#'   a walkshed under its POIs.
#' @param background_color Fill colour(s) for `background`, recycled across the
#'   layers.
#' @param background_opacity Fill opacity for `background` layers.
#' @param background_fill Fill the `background` layers (default `TRUE`); `FALSE`
#'   draws them as outlines only.
#' @param points Optional. A point [sf][sf::sf] drawn as markers on top of the
#'   main layer, e.g. POI locations over a block map.
#' @param points_color Marker colour for `points`.
#' @param mark Optional. A point to mark on top with an X, either a
#'   `c(lon, lat)` pair or a point [sf][sf::sf]/`sfc` (e.g. a starting point).
#' @param buffer Fraction of the data extent to pad the view by (default 0.15).
#' @param zoom Deprecated/ignored; the view auto-zooms to the data.
#' @return A plotly map object.
#' @examples
#' \dontrun{
#' close <- close_client()
#' close_map(close$place_pois(geoid = "4459000", type = 30), color = "#e8590c")
#' }
#' @export
close_map <- function(x, color = "#e8590c", highlight = NULL, fill = NULL,
                      palette = "YlGnBu", reverse = FALSE, label = NULL,
                      size = 15, opacity = 0.65, boundary = NULL,
                      background = NULL, background_color = "#3b6fb0",
                      background_opacity = 0.3, background_fill = TRUE,
                      points = NULL, points_color = "#e8590c",
                      mark = NULL, buffer = 0.15, zoom = NULL) {
  if (!requireNamespace("plotly", quietly = TRUE)) {
    stop("close_map() needs the plotly package: install.packages('plotly')")
  }
  x <- sf::st_transform(x, 4326)
  boxes <- list(sf::st_bbox(x))
  p <- plotly::plot_ly()

  # Semi-transparent background fills, drawn first (underneath everything).
  if (!is.null(background)) {
    if (inherits(background, c("sf", "sfc", "sfg"))) background <- list(background)
    cols <- rep(background_color, length.out = length(background))
    for (i in seq_along(background)) {
      geom <- sf::st_transform(sf::st_geometry(background[[i]]), 4326)
      boxes <- c(boxes, list(sf::st_bbox(geom)))
      xy <- .close_polygon_lines(geom)
      if (background_fill) {
        p <- plotly::add_trace(
          p, type = "scattermapbox", mode = "lines", lon = xy$lon, lat = xy$lat,
          fill = "toself", fillcolor = .close_rgba(cols[i], background_opacity),
          line = list(color = .close_rgba(cols[i], min(1, background_opacity + 0.3)),
                      width = 1),
          hoverinfo = "skip", showlegend = FALSE
        )
      } else {
        p <- plotly::add_trace(
          p, type = "scattermapbox", mode = "lines", lon = xy$lon, lat = xy$lat,
          line = list(color = cols[i], width = 2),
          hoverinfo = "skip", showlegend = FALSE
        )
      }
    }
  }

  # City-boundary outline (no fill), above the background fills. It is context, so
  # it does not drive the zoom — the view frames the data, not the whole city.
  if (!is.null(boundary)) {
    geom <- sf::st_transform(sf::st_geometry(boundary), 4326)
    xy <- .close_polygon_lines(geom)
    p <- plotly::add_trace(
      p, type = "scattermapbox", mode = "lines", lon = xy$lon, lat = xy$lat,
      line = list(color = "#666666", width = 1.5),
      hoverinfo = "skip", showlegend = FALSE
    )
  }

  hover <- .close_hover(x, label)
  hl <- NULL
  if (!is.null(highlight)) {
    hl <- if (is.character(highlight) && length(highlight) == 1L &&
              highlight %in% names(x)) as.logical(x[[highlight]])
          else as.logical(highlight)
  }
  fv <- if (!is.null(fill) && fill %in% names(x)) as.numeric(x[[fill]]) else NULL

  if (any(grepl("POINT", as.character(sf::st_geometry_type(x))))) {
    xy <- sf::st_coordinates(x)
    # Hairline black border: a slightly larger black marker underneath
    # (scattermapbox markers have no line/stroke of their own).
    p <- plotly::add_trace(
      p, type = "scattermapbox", mode = "markers",
      lon = xy[, 1], lat = xy[, 2],
      marker = list(size = size + 2, color = "#000000"),
      hoverinfo = "skip", showlegend = FALSE
    )
    if (!is.null(fv)) {
      marker <- list(size = size, color = fv, colorscale = .close_scale(palette),
                     reversescale = reverse, showscale = TRUE,
                     colorbar = list(title = fill))
    } else {
      cols <- if (is.null(hl)) color else ifelse(hl, color, "#888888")
      marker <- list(size = size, color = cols)
    }
    p <- plotly::add_trace(
      p, type = "scattermapbox", mode = "markers",
      lon = xy[, 1], lat = xy[, 2], marker = marker,
      text = hover, hoverinfo = "text", showlegend = FALSE
    )
  } else {
    x[["feature_id"]] <- as.character(seq_len(nrow(x)))
    # Outline the polygons in black when there are few of them (e.g. isochrone
    # contours); skip it on dense block maps, where every border would clutter.
    poly_line <- list(color = "#000000", width = if (nrow(x) <= 12) 1.5 else 0)
    if (!is.null(fv) && nrow(x) <= 12) {
      # Filled polygons that may overlap (nested isochrone contours): one trace
      # each, largest first, so every one stays hoverable; a shared coloraxis
      # gives them a single colorbar.
      for (i in order(as.numeric(sf::st_area(x)), decreasing = TRUE)) {
        gj <- jsonlite::fromJSON(
          geojsonsf::sf_geojson(x[i, "feature_id"]), simplifyVector = FALSE
        )
        p <- plotly::add_trace(
          p, type = "choroplethmapbox", geojson = gj,
          locations = x[["feature_id"]][i], z = fv[i], coloraxis = "coloraxis",
          featureidkey = "properties.feature_id",
          marker = list(opacity = opacity, line = poly_line),
          text = hover[i], hoverinfo = "text", showlegend = FALSE
        )
      }
      p <- plotly::layout(p, coloraxis = list(
        colorscale = .close_scale(palette), reversescale = reverse,
        cmin = min(fv), cmax = max(fv), colorbar = list(title = fill)
      ))
    } else if (is.null(fv) && is.null(hl) &&
               length(color) == nrow(x) && nrow(x) > 1) {
      # Per-polygon categorical colours (e.g. blocks by their closest POI): one
      # flat trace per distinct colour.
      for (col in unique(color)) {
        idx <- which(color == col)
        gj <- jsonlite::fromJSON(
          geojsonsf::sf_geojson(x[idx, "feature_id"]), simplifyVector = FALSE
        )
        p <- plotly::add_trace(
          p, type = "choroplethmapbox", geojson = gj,
          locations = x[["feature_id"]][idx], z = rep(1, length(idx)),
          colorscale = list(list(0, col), list(1, col)), showscale = FALSE,
          featureidkey = "properties.feature_id",
          marker = list(opacity = opacity, line = poly_line),
          text = hover[idx], hoverinfo = "text", showlegend = FALSE
        )
      }
    } else {
      gj <- jsonlite::fromJSON(
        geojsonsf::sf_geojson(x[, "feature_id"]), simplifyVector = FALSE
      )
      common <- list(
        type = "choroplethmapbox", geojson = gj, locations = x[["feature_id"]],
        featureidkey = "properties.feature_id",
        marker = list(opacity = opacity, line = poly_line),
        text = hover, hoverinfo = "text", showlegend = FALSE
      )
      if (!is.null(fv)) {
        args <- c(common, list(z = fv, colorscale = .close_scale(palette), reversescale = reverse,
                               showscale = TRUE, colorbar = list(title = fill)))
      } else {
        z <- if (is.null(hl)) rep(1, nrow(x)) else as.integer(hl)
        scale <- if (is.null(hl)) list(list(0, color), list(1, color))
                 else list(list(0, "#888888"), list(1, color))
        args <- c(common, list(z = z, colorscale = scale, showscale = FALSE))
      }
      p <- do.call(function(...) plotly::add_trace(p, ...), args)
    }
  }

  # Extra POI points drawn on top of the main layer (e.g. library locations),
  # with the same black hairline border as the main point markers.
  if (!is.null(points)) {
    pgeo <- sf::st_transform(points, 4326)
    pxy <- sf::st_coordinates(pgeo)
    boxes <- c(boxes, list(sf::st_bbox(pgeo)))
    p <- plotly::add_trace(
      p, type = "scattermapbox", mode = "markers", lon = pxy[, 1], lat = pxy[, 2],
      marker = list(size = size + 2, color = "#000000"),
      hoverinfo = "skip", showlegend = FALSE
    )
    p <- plotly::add_trace(
      p, type = "scattermapbox", mode = "markers", lon = pxy[, 1], lat = pxy[, 2],
      marker = list(size = size, color = points_color),
      text = .close_hover(pgeo, label), hoverinfo = "text", showlegend = FALSE
    )
  }

  # A point marked with an X (two crossing line segments \u2014 mapbox text glyphs do
  # not render on the raster basemap), drawn last so it sits on top of everything.
  if (!is.null(mark)) {
    if (inherits(mark, c("sf", "sfc", "sfg"))) {
      mc <- sf::st_coordinates(sf::st_transform(sf::st_geometry(mark), 4326))
      mlon <- mc[, 1]; mlat <- mc[, 2]
    } else {
      mlon <- mark[[1]]; mlat <- mark[[2]]
    }
    boxes <- c(boxes, list(c(xmin = min(mlon), ymin = min(mlat),
                             xmax = max(mlon), ymax = max(mlat))))
    sx <- range(vapply(boxes, function(b) c(b[["xmin"]], b[["xmax"]]), numeric(2)))
    sy <- range(vapply(boxes, function(b) c(b[["ymin"]], b[["ymax"]]), numeric(2)))
    hs <- max(diff(sx), diff(sy)) * 0.02
    lons <- numeric(0); lats <- numeric(0)
    for (j in seq_along(mlon)) {
      dlat <- hs * cos(mlat[j] * pi / 180)   # square the X against the Mercator stretch
      lons <- c(lons, mlon[j] - hs, mlon[j] + hs, NA, mlon[j] - hs, mlon[j] + hs, NA)
      lats <- c(lats, mlat[j] - dlat, mlat[j] + dlat, NA, mlat[j] + dlat, mlat[j] - dlat, NA)
    }
    p <- plotly::add_trace(
      p, type = "scattermapbox", mode = "lines", lon = lons, lat = lats,
      line = list(color = "#111111", width = 3),
      hoverinfo = "skip", showlegend = FALSE
    )
  }

  cz <- .close_center_zoom(boxes, buffer)
  plotly::layout(
    p,
    mapbox = list(style = "carto-positron", zoom = cz$zoom, center = cz$center),
    margin = list(l = 0, r = 0, t = 0, b = 0)
  )
}
