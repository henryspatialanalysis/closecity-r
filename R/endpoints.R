# One function per public route. Each returns a `close_reply` (list of results +
# metering/ETag metadata). Paginated routes accept `cursor` and are meant to be
# looped with close_records().

# --- catalog (free) ---------------------------------------------------------

#' Liveness check
#'
#' Free, keyless health check. Touches no database.
#'
#' @param client A `close_client()`.
#' @return A [close_reply].
#' @family catalog endpoints
#' @export
close_health <- function(client) .close_get(client, "/v1/health")

#' Newest-data publication timestamp
#'
#' Publication timestamp of the newest published data (free).
#'
#' @param client A `close_client()`.
#' @return A [close_reply].
#' @family catalog endpoints
#' @export
close_last_updated <- function(client) .close_get(client, "/v1/last-updated")

#' Travel modes
#'
#' The travel modes and their numeric ids (free): walk, bike, transit.
#'
#' @param client A `close_client()`.
#' @return A [close_reply].
#' @family catalog endpoints
#' @export
close_modes <- function(client) .close_get(client, "/v1/meta/modes")

#' Destination-type taxonomy
#'
#' The destination-type taxonomy with leaf expansions (free). Use it to look up
#' the numeric `type` ids the data routes filter on (e.g. grocery, restaurants).
#'
#' @param client A `close_client()`.
#' @return A [close_reply].
#' @family catalog endpoints
#' @export
close_destination_types <- function(client) {
  .close_get(client, "/v1/meta/destination-types")
}

#' Dataset vintages
#'
#' The active version of each dataset component (free).
#'
#' @param client A `close_client()`.
#' @return A [close_reply].
#' @family catalog endpoints
#' @export
close_vintage <- function(client) .close_get(client, "/v1/meta/vintage")

#' Search census places by name
#'
#' Resolve a city/town name to its census place GEOID and WGS84 centroid. Free
#' (no API key). Feed the centroid into [close_blocks_query()] (`center` +
#' `radius_m`), or the GEOID into [close_place_blocks()].
#'
#' @param client A `close_client()`.
#' @param q Name substring, e.g. `"Providence"`.
#' @param limit Maximum matches to return (1-20).
#' @return A [close_reply].
#' @family catalog endpoints
#' @export
close_places <- function(client, q, limit = NULL) {
  .close_get(client, "/v1/places", list(q = q, limit = limit))
}

# --- origin block / point (metered) ----------------------------------------

#' Fastest travel time from a block to each destination category
#'
#' Fastest travel time to each destination category from a census block, by
#' mode. Metered: one token per returned (category, mode) row.
#'
#' @param client A `close_client()`.
#' @param geoid 15-digit census block GEOID.
#' @param mode Mode label(s) to filter by (`"walk"`, `"bike"`, `"transit"`).
#' @param type Destination type id(s) to filter by (see
#'   [close_destination_types()]).
#' @param if_none_match An ETag to revalidate; returns a free HTTP 304 on a match.
#' @return A [close_reply].
#' @family block endpoints
#' @examples
#' \dontrun{
#' cl <- close_client("ck_live_...")
#' close_block_summary(cl, "250173523004004", mode = "walk")
#' }
#' @export
close_block_summary <- function(client, geoid, mode = NULL, type = NULL,
                                if_none_match = NULL) {
  .close_get(client, sprintf("/v1/blocks/%s/summary", geoid),
             list(mode = mode, type = type), if_none_match)
}

#' Nearby POIs and their travel time from a block
#'
#' Every nearby POI and its travel time from a block, one row per (POI, mode).
#' Paginated: loop it with [close_records()]. Metered per returned row.
#'
#' @param client A `close_client()`.
#' @param geoid 15-digit census block GEOID.
#' @param mode Mode label(s) to filter by.
#' @param type Destination type id(s) to filter by.
#' @param dest_id Restrict to specific destination id(s).
#' @param max_minutes Cap travel time (<= 30).
#' @param limit Page size (<= 1000).
#' @param cursor Opaque keyset cursor from a previous page's `next_cursor`;
#'   normally you use [close_records()] instead of setting this by hand.
#' @return A [close_reply].
#' @family block endpoints
#' @export
close_block_pois <- function(client, geoid, mode = NULL, type = NULL,
                             dest_id = NULL, max_minutes = NULL, limit = NULL,
                             cursor = NULL) {
  .close_get(client, sprintf("/v1/blocks/%s/pois", geoid),
             list(mode = mode, type = type, dest_id = dest_id,
                  max_minutes = max_minutes, limit = limit, cursor = cursor))
}

#' Fastest travel time from a point to each destination category
#'
#' Like [close_block_summary()], but from the census block containing a lat/lon;
#' the resolved block GEOID is echoed as `resolved_block`. Metered per row.
#'
#' @param client A `close_client()`.
#' @param lat Latitude (WGS84).
#' @param lon Longitude (WGS84).
#' @param mode Mode label(s) to filter by.
#' @param type Destination type id(s) to filter by.
#' @param if_none_match An ETag to revalidate; returns a free HTTP 304 on a match.
#' @return A [close_reply].
#' @family point endpoints
#' @export
close_point_summary <- function(client, lat, lon, mode = NULL, type = NULL,
                                if_none_match = NULL) {
  .close_get(client, "/v1/point/summary",
             list(lat = lat, lon = lon, mode = mode, type = type), if_none_match)
}

#' Nearby POIs and their travel time from a point
#'
#' Like [close_block_pois()], but from the block containing a lat/lon. Paginated;
#' loop with [close_records()]. Metered per returned row.
#'
#' @param client A `close_client()`.
#' @param lat Latitude (WGS84).
#' @param lon Longitude (WGS84).
#' @param mode Mode label(s) to filter by.
#' @param type Destination type id(s) to filter by.
#' @param dest_id Restrict to specific destination id(s).
#' @param max_minutes Cap travel time (<= 30).
#' @param limit Page size (<= 1000).
#' @param cursor Opaque keyset cursor; normally use [close_records()] instead.
#' @return A [close_reply].
#' @family point endpoints
#' @export
close_point_pois <- function(client, lat, lon, mode = NULL, type = NULL,
                             dest_id = NULL, max_minutes = NULL, limit = NULL,
                             cursor = NULL) {
  .close_get(client, "/v1/point/pois",
             list(lat = lat, lon = lon, mode = mode, type = type,
                  dest_id = dest_id, max_minutes = max_minutes, limit = limit,
                  cursor = cursor))
}

# --- POI search / detail / catchment (metered) -----------------------------

#' Search POIs by area
#'
#' Search points of interest by bounding box (`bbox`) or radius (`lat` + `lon` +
#' `radius_m`). Spatial only (no travel times). Paginated; loop with
#' [close_records()]. Metered per returned row.
#'
#' @param client A `close_client()`.
#' @param lat,lon Circle centre (WGS84), with `radius_m`.
#' @param radius_m Search radius in metres (<= 50000).
#' @param bbox Bounding box `"min_lon,min_lat,max_lon,max_lat"`.
#' @param type Destination type id(s) to filter by.
#' @param q Name substring to match.
#' @param limit Page size (<= 1000).
#' @param cursor Opaque keyset cursor; normally use [close_records()] instead.
#' @return A [close_reply].
#' @family POI endpoints
#' @export
close_pois_search <- function(client, lat = NULL, lon = NULL, radius_m = NULL,
                              bbox = NULL, type = NULL, q = NULL, limit = NULL,
                              cursor = NULL) {
  .close_get(client, "/v1/pois",
             list(lat = lat, lon = lon, radius_m = radius_m, bbox = bbox,
                  type = type, q = q, limit = limit, cursor = cursor))
}

#' One POI's details
#'
#' Name, location, address, types, and whitelisted attributes for one POI.
#' Metered: one token per call.
#'
#' @param client A `close_client()`.
#' @param dest_id Destination id.
#' @param if_none_match An ETag to revalidate; returns a free HTTP 304 on a match.
#' @return A [close_reply].
#' @family POI endpoints
#' @export
close_poi <- function(client, dest_id, if_none_match = NULL) {
  .close_get(client, sprintf("/v1/pois/%s", dest_id), NULL, if_none_match)
}

#' A POI's catchment (blocks that can reach it)
#'
#' Every census block that can reach a POI, one row per (block, mode). Paginated;
#' loop with [close_records()]. Metered per returned row.
#'
#' @param client A `close_client()`.
#' @param dest_id Destination id.
#' @param mode Mode label(s) to filter by.
#' @param block Restrict to specific block id(s).
#' @param max_minutes Cap travel time (<= 30).
#' @param limit Page size (<= 1000).
#' @param cursor Opaque keyset cursor; normally use [close_records()] instead.
#' @return A [close_reply].
#' @family POI endpoints
#' @export
close_poi_catchment <- function(client, dest_id, mode = NULL, block = NULL,
                                max_minutes = NULL, limit = NULL, cursor = NULL) {
  .close_get(client, sprintf("/v1/pois/%s/catchment", dest_id),
             list(mode = mode, block = block, max_minutes = max_minutes,
                  limit = limit, cursor = cursor))
}

# --- areal (metered) --------------------------------------------------------

#' Per-block travel times within a polygon or radius
#'
#' Blocks within a GeoJSON `polygon` or a `center` + `radius_m`, one row per
#' (block, category, mode). Paginated with the cursor carried in the request
#' body. Metered per returned row.
#'
#' @param client A `close_client()`.
#' @param polygon A GeoJSON Polygon/MultiPolygon (as a list).
#' @param center A `list(lon =, lat =)` centre, used with `radius_m`.
#' @param radius_m Radius in metres (<= 28000).
#' @param type Destination type id(s) to filter by.
#' @param mode Mode label(s) to filter by.
#' @param include_population Add each block's population to its rows.
#' @param limit Page size (<= 1000).
#' @param cursor Opaque keyset cursor; normally use [close_records()] instead.
#' @return A [close_reply].
#' @family areal endpoints
#' @export
close_blocks_query <- function(client, polygon = NULL, center = NULL,
                               radius_m = NULL, type = NULL, mode = NULL,
                               include_population = NULL, limit = NULL,
                               cursor = NULL) {
  .close_post_json(client, "/v1/blocks/query",
                   list(polygon = polygon, center = center, radius_m = radius_m,
                        type = type, mode = mode,
                        include_population = include_population,
                        limit = limit, cursor = cursor))
}

#' Per-block travel times for a whole place
#'
#' Per-block travel times for every census block in a place (city/town), by place
#' GEOID, one row per (block, category, mode). Paginated; loop with
#' [close_records()]. Metered per returned row.
#'
#' @param client A `close_client()`.
#' @param geoid Census place GEOID.
#' @param mode Mode label(s) to filter by.
#' @param type Destination type id(s) to filter by.
#' @param include_population Add each block's population to its rows.
#' @param limit Page size (<= 1000).
#' @param cursor Opaque keyset cursor; normally use [close_records()] instead.
#' @return A [close_reply].
#' @family areal endpoints
#' @export
close_place_blocks <- function(client, geoid, mode = NULL, type = NULL,
                               include_population = NULL, limit = NULL,
                               cursor = NULL) {
  .close_get(client, sprintf("/v1/places/%s/blocks", geoid),
             list(mode = mode, type = type,
                  include_population = include_population, limit = limit,
                  cursor = cursor))
}

# --- isochrone --------------------------------------------------------------

#' Travel-time contours (isochrone)
#'
#' Travel-time contours from a `block` (GEOID) or `lon` + `lat`. Charged one
#' token per contour level (1-4), not per row. With `format = "geojson"` the
#' reply carries polygon geometry you can convert with [close_as_sf()].
#'
#' @param client A `close_client()`.
#' @param block Origin block GEOID (or give `lon` + `lat`).
#' @param lon,lat Origin point (WGS84), as an alternative to `block`.
#' @param mode `"walk"`, `"bike"`, or `"transit"`.
#' @param direction `"to"` (blocks that can reach the origin) or `"from"`.
#' @param minutes A single threshold (1-60).
#' @param contours Up to 4 ascending levels (a vector or comma string), instead
#'   of `minutes`.
#' @param format `"geojson"` (polygons) or `"blocks"` (a block list).
#' @param v Opaque cache-buster, echoed back.
#' @param if_none_match An ETag to revalidate; returns a free HTTP 304 on a match.
#' @return A [close_reply].
#' @family isochrone endpoints
#' @examples
#' \dontrun{
#' iso <- close_isochrone(cl, block = "440070036001010", mode = "walk",
#'                        minutes = 15, format = "geojson")
#' close_as_sf(iso)
#' }
#' @export
close_isochrone <- function(client, block = NULL, lon = NULL, lat = NULL,
                            mode = NULL, direction = NULL, minutes = NULL,
                            contours = NULL, format = NULL, v = NULL,
                            if_none_match = NULL) {
  if (length(contours) > 1) contours <- paste(contours, collapse = ",")
  .close_get(client, "/v1/isochrone",
             list(block = block, lon = lon, lat = lat, mode = mode,
                  direction = direction, minutes = minutes, contours = contours,
                  format = format, v = v), if_none_match)
}

#' Isochrone metadata
#'
#' The active isochrone store version, available directions/modes, and the
#' routing assumptions (free, keyless).
#'
#' @param client A `close_client()`.
#' @param if_none_match An ETag to revalidate; returns a free HTTP 304 on a match.
#' @return A [close_reply].
#' @family isochrone endpoints
#' @export
close_isochrone_meta <- function(client, if_none_match = NULL) {
  .close_get(client, "/v1/isochrone/meta", NULL, if_none_match)
}

# --- pagination -------------------------------------------------------------

#' Collect every record from a paginated endpoint
#'
#' Repeatedly calls a paginated endpoint function, following `next_cursor` until
#' it is null, and returns all records combined. Each page is metered
#' independently.
#'
#' @param fetch A paginated endpoint function (e.g. [close_pois_search()]).
#' @param ... Arguments forwarded to `fetch` (starting with the client).
#' @return A list of record lists across all pages.
#' @family pagination
#' @examples
#' \dontrun{
#' close_records(close_pois_search, client, lat = 44.05, lon = -123.09,
#'               radius_m = 2000)
#' }
#' @export
close_records <- function(fetch, ...) {
  out <- list()
  cursor <- NULL
  repeat {
    page <- fetch(..., cursor = cursor)
    out <- c(out, page$results)
    cursor <- page$next_cursor
    if (is.null(cursor)) break
  }
  out
}
