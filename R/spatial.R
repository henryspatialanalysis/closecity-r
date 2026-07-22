# Optional spatial conversion: turn a `close_reply` into an `sf` object. `sf` (and
# `tigris`, for the block-boundary join) are Suggested, loaded only on demand, so
# the base client stays httr2 + jsonlite + rlang. The default reply is unchanged;
# spatial output is strictly opt-in via close_as_sf() / sf::st_as_sf().

#' Convert a Close reply to an `sf` object
#'
#' Detects the geometry from the payload: POI replies (`close_pois_search`,
#' `close_block_pois`, `close_point_pois`, `close_poi`) become **points** from
#' their `lat`/`lon`; an isochrone `close_isochrone(format = "geojson")` reply
#' becomes **polygons**; block replies (`close_block_summary`, `close_blocks_query`,
#' `close_place_blocks`, `close_poi_catchment`) carry only GEOIDs, so you join
#' census-block boundaries via `block_geometry` (an `sf` keyed on `geoid_col`) or
#' let it fetch them with `tigris` when `fetch = TRUE`.
#'
#' @param x A `close_reply` (or the same list shape).
#' @param block_geometry Optional `sf` of block boundaries with a `geoid_col`
#'   column, joined to block replies on the 15-digit GEOID.
#' @param geoid_col Name of the GEOID column in `block_geometry`. Default
#'   `"GEOID20"` (TIGER 2020 blocks).
#' @param crs Coordinate reference system for point/polygon geometry. Default 4326.
#' @param fetch If `TRUE` and `block_geometry` is `NULL`, pull the needed TIGER
#'   blocks with `tigris` (inferring state/county from the GEOIDs).
#' @return An `sf` data frame.
#' @examples
#' \dontrun{
#' close_as_sf(close_pois_search(client, lat = 41.82, lon = -71.41, radius_m = 1500))
#' close_as_sf(close_isochrone(client, block = "440070036001010", minutes = 15))
#' }
#' @export
close_as_sf <- function(x, block_geometry = NULL, geoid_col = "GEOID20",
                        crs = 4326, fetch = FALSE) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("`sf` is required for spatial conversion; install it with ",
         "install.packages(\"sf\").", call. = FALSE)
  }
  data <- x$data
  if (is.list(data) && !is.null(data$features)) {
    return(.close_sf_isochrone(data, crs))
  }
  rows <- x$results %||% list()
  if (length(rows) == 0 && !is.null(data$lat) && !is.null(data$lon)) {
    rows <- list(data)
  }
  if (length(rows) == 0 && !is.null(data$block$geoid)) {
    rows <- list(data$block)
  }
  if (length(rows) == 0) {
    stop("This reply has no rows to build geometry from.", call. = FALSE)
  }
  first <- rows[[1]]
  if (!is.null(first$lat) && !is.null(first$lon)) {
    return(.close_sf_points(rows, crs))
  }
  if (!is.null(first$geoid)) {
    return(.close_sf_blocks(rows, block_geometry, geoid_col, crs, fetch))
  }
  stop("Reply rows carry no lat/lon or geoid to build geometry from.", call. = FALSE)
}

# Flatten a list of record-lists to a data.frame, dropping nested (list) fields
# such as `address` (kept simple; callers wanting those can read `reply$results`).
.close_rows_to_df <- function(rows) {
  keys <- unique(unlist(lapply(rows, names)))
  cols <- lapply(keys, function(k) {
    vals <- lapply(rows, function(r) {
      v <- r[[k]]
      if (is.null(v) || length(v) != 1 || is.list(v)) NA else v
    })
    unlist(vals, use.names = FALSE)
  })
  names(cols) <- keys
  as.data.frame(cols, stringsAsFactors = FALSE)
}

.close_sf_points <- function(rows, crs) {
  df <- .close_rows_to_df(rows)
  sf::st_as_sf(df, coords = c("lon", "lat"), crs = crs, remove = FALSE)
}

# The isochrone body is a custom envelope, but its `features` are standard GeoJSON
# features — wrap them in a FeatureCollection and let sf/GDAL parse the geometry.
.close_sf_isochrone <- function(data, crs) {
  fc <- list(type = "FeatureCollection", features = data$features)
  txt <- jsonlite::toJSON(fc, auto_unbox = TRUE, null = "null", digits = NA)
  gj <- sf::read_sf(txt)
  if (is.na(sf::st_crs(gj))) sf::st_crs(gj) <- crs
  gj
}

.close_sf_blocks <- function(rows, block_geometry, geoid_col, crs, fetch) {
  df <- .close_rows_to_df(rows)
  if (is.null(block_geometry)) {
    if (isTRUE(fetch)) {
      block_geometry <- .close_fetch_blocks(df$geoid, geoid_col)
    } else {
      stop("Block replies carry only GEOIDs. Pass block_geometry = <sf> (joined on ",
           "`geoid_col`, default \"GEOID20\"), or fetch = TRUE to pull TIGER blocks ",
           "with tigris.", call. = FALSE)
    }
  }
  merge(block_geometry, df, by.x = geoid_col, by.y = "geoid", all.y = TRUE)
}

.close_fetch_blocks <- function(geoids, geoid_col) {
  if (!requireNamespace("tigris", quietly = TRUE)) {
    stop("fetch = TRUE needs `tigris`; install it with install.packages(\"tigris\").",
         call. = FALSE)
  }
  geoids <- geoids[!is.na(geoids)]
  pairs <- unique(data.frame(state = substr(geoids, 1, 2),
                             county = substr(geoids, 3, 5), stringsAsFactors = FALSE))
  frames <- Map(function(s, c) {
    tigris::blocks(state = s, county = c, year = 2020, progress_bar = FALSE)
  }, pairs$state, pairs$county)
  do.call(rbind, frames)
}

#' @exportS3Method sf::st_as_sf
st_as_sf.close_reply <- function(x, ...) close_as_sf(x, ...)
