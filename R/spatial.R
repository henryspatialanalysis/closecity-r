# Turn a close_reply into an sf object. Feature methods call this for you when the
# client's spatial flag is on (the default); close_as_sf() also works by hand. sf
# is a hard dependency; tigris is Suggested and used only for the block-boundary
# join.

#' Convert a Close reply to an sf object
#'
#' Detects the geometry from the payload. POI replies (from `$pois_search()`,
#' `$block_pois()`, `$point_pois()`, `$poi()`) become points from their `lat`/`lon`.
#' An isochrone reply with `format = "geojson"` becomes polygons. Block replies
#' (`$blocks_query()`, `$place_blocks()`, `$poi_catchment()`) carry only GEOIDs, so
#' the block boundaries are joined from `block_geometry`, or downloaded with
#' `tigris` when `fetch = TRUE`.
#'
#' @param x A `close_reply` (or the same list shape).
#' @param block_geometry Optional sf of block boundaries with a `geoid_col`
#'   column, joined to block replies on the 15-digit GEOID.
#' @param geoid_col Name of the GEOID column in `block_geometry`. Default
#'   `"GEOID20"` (TIGER 2020 blocks).
#' @param crs Coordinate reference system for point and polygon geometry. Default
#'   4326.
#' @param fetch If `TRUE` and `block_geometry` is `NULL`, download the needed TIGER
#'   blocks with `tigris` (inferring state and county from the GEOIDs).
#' @return An sf data frame.
#' @examples
#' \dontrun{
#' close <- close_client(spatial = FALSE)
#' close_as_sf(close$pois_search(lat = 41.82, lon = -71.41, radius_m = 1500))
#' }
#' @export
close_as_sf <- function(x, block_geometry = NULL, geoid_col = "GEOID20",
                        crs = 4326, fetch = FALSE) {
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
# such as address (kept simple; callers wanting those can read reply$results).
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

# The isochrone body is a custom envelope, but its features are standard GeoJSON
# features, so wrap them in a FeatureCollection and let sf parse the geometry.
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
           "`geoid_col`, default \"GEOID20\"), or fetch = TRUE to download TIGER ",
           "blocks with tigris.", call. = FALSE)
    }
  }
  merge(block_geometry, df, by.x = geoid_col, by.y = "geoid", all.y = TRUE)
}

.close_fetch_blocks <- function(geoids, geoid_col) {
  if (!requireNamespace("tigris", quietly = TRUE)) {
    stop("Mapping blocks needs the tigris package; install it with ",
         "install.packages(\"tigris\"), or build the client with spatial = FALSE.",
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
