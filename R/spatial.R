# Turn a close_reply into an sf object. Feature methods call this for you in the
# default "spatial" output mode; close_as_sf() also works by hand. It builds on the
# row-shaping in tabular.R and adds geometry. sf is a hard dependency; tigris is
# Suggested and used only for the block-boundary join.

#' Convert a Close reply to an sf object
#'
#' Detects the geometry from the payload. POI replies (from `$pois_search()`,
#' `$block_pois()`, `$point_pois()`, `$poi()`, `$places()`) become points from
#' their `lat`/`lon`. An isochrone reply with `format = "geojson"` becomes
#' polygons. Block replies (`$blocks_query()`, `$place_blocks()`,
#' `$poi_catchment()`, isochrone `format = "blocks"`) carry only GEOIDs, so the
#' block boundaries are joined from `block_geometry`, or downloaded with `tigris`
#' when `fetch = TRUE`.
#'
#' @param x (`close_reply`)\cr A reply, or the same list shape.
#' @param block_geometry (`sf`, default NULL)\cr Block boundaries with a
#'   `geoid_col` column, joined to block replies on the 15-digit GEOID.
#' @param geoid_col (`character(1)`, default `'GEOID20'`)\cr Name of the GEOID
#'   column in `block_geometry` (TIGER 2020 blocks).
#' @param crs (default `4326`)\cr Coordinate reference system for point and polygon
#'   geometry.
#' @param fetch (`logical(1)`, default FALSE)\cr If `TRUE` and `block_geometry` is
#'   `NULL`, download the needed TIGER blocks with `tigris` (inferring state and
#'   county from the GEOIDs).
#' @return An sf data frame. Metering and envelope metadata are attached as
#'   attributes.
#' @examples
#' \dontrun{
#' close <- close_client(output = 'raw')
#' close_as_sf(close$pois_search(lat = 41.82, lon = -71.41, radius_m = 1500))
#' }
#' @export
close_as_sf <- function(
  x, block_geometry = NULL, geoid_col = 'GEOID20', crs = 4326, fetch = FALSE
){
  data <- x$data
  meta <- .close_reply_meta(x)
  if(.close_is_isochrone(data)){
    return(.close_stamp_attrs(.close_sf_isochrone(data, crs), data, meta))
  }
  parts <- .close_rows_and_envelope(data)
  rows <- parts$rows
  envelope <- parts$envelope
  first <- if(length(rows) > 0) rows[[1]] else NULL
  if(!is.null(first) && !is.null(first$lat) && !is.null(first$lon)){
    out <- .close_sf_points(rows, crs)
  } else if(!is.null(first) && !is.null(first$geoid)){
    out <- .close_sf_blocks(rows, block_geometry, geoid_col, crs, fetch)
  } else if(!is.null(data$lat) && !is.null(data$lon)){
    out <- .close_sf_points(list(data), crs)
  } else if(!is.null(data$block$geoid)){
    out <- .close_sf_blocks(list(data$block), block_geometry, geoid_col, crs, fetch)
  } else {
    stop(
      'This reply has no lat/lon, isochrone features, or block GEOIDs to build ',
      'geometry from.', call. = FALSE
    )
  }
  .close_stamp_attrs(out, envelope, meta)
}

.close_sf_points <- function(rows, crs){
  df <- .close_rows_to_df(rows)
  sf::st_as_sf(df, coords = c('lon', 'lat'), crs = crs, remove = FALSE)
}

# The isochrone body is a custom envelope, but its features are standard GeoJSON
# features, so wrap them in a FeatureCollection and let sf parse the geometry.
.close_sf_isochrone <- function(data, crs){
  fc <- list(type = 'FeatureCollection', features = data$features)
  txt <- jsonlite::toJSON(fc, auto_unbox = TRUE, null = 'null', digits = NA)
  gj <- sf::read_sf(txt)
  if(is.na(sf::st_crs(gj))) sf::st_crs(gj) <- crs
  gj
}

.close_sf_blocks <- function(rows, block_geometry, geoid_col, crs, fetch){
  df <- .close_rows_to_df(rows)
  if(is.null(block_geometry)){
    if(isTRUE(fetch)){
      block_geometry <- .close_fetch_blocks(df$geoid, geoid_col)
    } else {
      stop(
        'Block replies carry only GEOIDs. Pass block_geometry = <sf> (joined on ',
        '`geoid_col`, default "GEOID20"), or fetch = TRUE to download TIGER ',
        'blocks with tigris.', call. = FALSE
      )
    }
  }
  # Rename the block-geometry key to "geoid" so the join keeps a "geoid" column:
  # merge() names the shared column after `by.x`, so joining GEOID20 to geoid would
  # leave only GEOID20 and drop the "geoid" that the reply's rows carry.
  names(block_geometry)[names(block_geometry) == geoid_col] <- 'geoid'
  # TIGER blocks arrive in NAD83 (EPSG:4269); reproject so they match the POI and
  # isochrone geometry (EPSG:4326) and can be combined without a CRS mismatch.
  if(!is.na(sf::st_crs(block_geometry)) &&
     sf::st_crs(block_geometry) != sf::st_crs(crs)){
    block_geometry <- sf::st_transform(block_geometry, crs)
  }
  out <- merge(block_geometry, df, by = 'geoid', all.y = TRUE)
  # Drop rows whose GEOID had no TIGER match (e.g. water blocks); they have empty
  # geometry and would break plotting and spatial joins.
  keep <- !sf::st_is_empty(sf::st_geometry(out))
  keep[is.na(keep)] <- FALSE
  out[keep, ]
}

.close_fetch_blocks <- function(geoids, geoid_col){
  if(!requireNamespace('tigris', quietly = TRUE)){
    stop(
      'Mapping blocks needs the tigris package; install it with ',
      'install.packages("tigris"), or use output = "tabular" for the same rows ',
      'without geometry.', call. = FALSE
    )
  }
  geoids <- geoids[!is.na(geoids)]
  pairs <- unique(data.frame(
    state = substr(geoids, 1, 2), county = substr(geoids, 3, 5),
    stringsAsFactors = FALSE
  ))
  frames <- Map(function(state, county){
    tigris::blocks(state = state, county = county, year = 2020, progress_bar = FALSE)
  }, pairs$state, pairs$county)
  do.call(rbind, frames)
}

#' @exportS3Method sf::st_as_sf
st_as_sf.close_reply <- function(x, ...) close_as_sf(x, ...)
