# The client is an R6 object that holds your connection settings and gives you one
# method per public route. Build it with close_client(), then make calls through
# its methods, e.g. close$block_summary("250173523004004", mode = "walk").
#
# By default the feature methods (POIs, catchments, areal blocks, isochrones)
# return an sf object, ready to map. Set spatial = FALSE (on the client, or per
# call) to get the raw close_reply instead.

DEFAULT_BASE_URL <- "https://api.close.city"
PROBLEM_SLUG_PREFIX <- "https://api.close.city/problems/"

#' Create a Close API client
#'
#' Builds a [CloseClient]. The catalog and health routes are free, so a key is
#' optional. Every data route needs one (a `ck_live_` or `ck_test_` key), created
#' at https://account.close.city.
#'
#' @param api_key Your API key, or NULL for the free routes.
#' @param base_url API base URL.
#' @param timeout Request timeout, in seconds.
#' @param spatial Return feature results as [sf][sf::sf] objects? Defaults to
#'   TRUE. Set FALSE to work with the raw [close_reply] instead.
#' @return A [CloseClient]. Make calls through its methods.
#' @examples
#' \dontrun{
#' close <- close_client("ck_live_your_key")   # use your own key here
#' close$block_summary("250173523004004", mode = "walk")
#' }
#' @export
close_client <- function(api_key = NULL, base_url = DEFAULT_BASE_URL,
                         timeout = 30, spatial = TRUE) {
  CloseClient$new(
    api_key = api_key, base_url = base_url, timeout = timeout, spatial = spatial
  )
}

#' Close API client
#'
#' An R6 object that holds your connection settings and gives you one method per
#' public route. Create it with [close_client()] rather than calling `$new()`.
#' Feature methods return an [sf][sf::sf] object when `spatial` is TRUE (the
#' default), or a [close_reply] otherwise.
#'
#' @importFrom R6 R6Class
#' @export
CloseClient <- R6::R6Class(
  "CloseClient",
  public = list(

    #' @field spatial (`logical(1)`)\cr
    #' Should feature methods return an sf object? Toggle any time.
    spatial = TRUE,

    #' @description Create a client. Prefer [close_client()].
    #' @param api_key Your API key, or NULL for the free routes.
    #' @param base_url API base URL.
    #' @param timeout Request timeout, in seconds.
    #' @param spatial Return feature results as sf objects?
    initialize = function(api_key = NULL, base_url = DEFAULT_BASE_URL,
                          timeout = 30, spatial = TRUE) {
      private$api_key <- api_key
      private$base_url <- sub("/$", "", base_url)
      private$timeout <- timeout
      self$spatial <- spatial
    },

    #' @description Liveness check (free).
    #' @return A [close_reply].
    health = function() private$get("/v1/health"),

    #' @description Publication time of the newest data (free).
    #' @return A [close_reply].
    last_updated = function() private$get("/v1/last-updated"),

    #' @description Travel modes and their numeric ids (free).
    #' @return A [close_reply].
    modes = function() private$get("/v1/meta/modes"),

    #' @description Destination-type taxonomy (free). Use it to look up the
    #'   numeric `type` ids the data routes filter on.
    #' @return A [close_reply].
    destination_types = function() private$get("/v1/meta/destination-types"),

    #' @description Active version of each dataset component (free).
    #' @return A [close_reply].
    vintage = function() private$get("/v1/meta/vintage"),

    #' @description Look up a city or town by name (free). Each match carries its
    #'   census place GEOID and centre point.
    #' @param q Name to search for, such as "Providence".
    #' @param limit Most matches to return (1 to 20).
    #' @return A [close_reply].
    places = function(q, limit = NULL) {
      private$get("/v1/places", list(q = q, limit = limit))
    },

    #' @description Fastest travel time from a census block to each destination
    #'   category, by mode.
    #' @param geoid 15-digit census block GEOID.
    #' @param mode Travel mode(s) to keep: "walk", "bike", "transit".
    #' @param type Destination type id(s) to keep.
    #' @param if_none_match An ETag from an earlier reply, to revalidate for free.
    #' @return A [close_reply].
    block_summary = function(geoid, mode = NULL, type = NULL,
                             if_none_match = NULL) {
      private$get(sprintf("/v1/blocks/%s/summary", geoid),
                  list(mode = mode, type = type), if_none_match)
    },

    #' @description Nearby points of interest and their travel time from a block,
    #'   one row per (POI, mode). Read every page with `$records()`.
    #' @param geoid 15-digit census block GEOID.
    #' @param mode Travel mode(s) to keep.
    #' @param type Destination type id(s) to keep.
    #' @param dest_id Specific destination id(s) to keep.
    #' @param max_minutes Upper bound on travel time (up to 30).
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor from a previous reply's `next_cursor`.
    #' @return An [sf][sf::sf] object, or a [close_reply] when `spatial` is FALSE.
    block_pois = function(geoid, mode = NULL, type = NULL, dest_id = NULL,
                          max_minutes = NULL, limit = NULL, cursor = NULL) {
      private$as_spatial(private$get(
        sprintf("/v1/blocks/%s/pois", geoid),
        list(mode = mode, type = type, dest_id = dest_id,
             max_minutes = max_minutes, limit = limit, cursor = cursor)
      ))
    },

    #' @description Like `$block_summary()`, but from the block containing a
    #'   lat/lon point. The resolved block is echoed as `resolved_block`.
    #' @param lat Latitude.
    #' @param lon Longitude.
    #' @param mode Travel mode(s) to keep.
    #' @param type Destination type id(s) to keep.
    #' @param if_none_match An ETag to revalidate for free.
    #' @return A [close_reply].
    point_summary = function(lat, lon, mode = NULL, type = NULL,
                             if_none_match = NULL) {
      private$get("/v1/point/summary",
                  list(lat = lat, lon = lon, mode = mode, type = type),
                  if_none_match)
    },

    #' @description Like `$block_pois()`, but from the block containing a lat/lon
    #'   point. Read every page with `$records()`.
    #' @param lat Latitude.
    #' @param lon Longitude.
    #' @param mode Travel mode(s) to keep.
    #' @param type Destination type id(s) to keep.
    #' @param dest_id Specific destination id(s) to keep.
    #' @param max_minutes Upper bound on travel time (up to 30).
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor.
    #' @return An [sf][sf::sf] object, or a [close_reply] when `spatial` is FALSE.
    point_pois = function(lat, lon, mode = NULL, type = NULL, dest_id = NULL,
                          max_minutes = NULL, limit = NULL, cursor = NULL) {
      private$as_spatial(private$get(
        "/v1/point/pois",
        list(lat = lat, lon = lon, mode = mode, type = type,
             dest_id = dest_id, max_minutes = max_minutes,
             limit = limit, cursor = cursor)
      ))
    },

    #' @description Search points of interest by bounding box, or by a circle
    #'   (`lat` + `lon` + `radius_m`). Read every page with `$records()`.
    #' @param lat,lon Circle centre.
    #' @param radius_m Circle radius, in metres (up to 50000).
    #' @param bbox Bounding box, "min_lon,min_lat,max_lon,max_lat".
    #' @param type Destination type id(s) to keep.
    #' @param q Name text to match.
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor.
    #' @return An [sf][sf::sf] object, or a [close_reply] when `spatial` is FALSE.
    pois_search = function(lat = NULL, lon = NULL, radius_m = NULL, bbox = NULL,
                           type = NULL, q = NULL, limit = NULL, cursor = NULL) {
      private$as_spatial(private$get(
        "/v1/pois",
        list(lat = lat, lon = lon, radius_m = radius_m, bbox = bbox,
             type = type, q = q, limit = limit, cursor = cursor)
      ))
    },

    #' @description Details for one point of interest.
    #' @param dest_id Destination id.
    #' @param if_none_match An ETag to revalidate for free.
    #' @return An [sf][sf::sf] object, or a [close_reply] when `spatial` is FALSE.
    poi = function(dest_id, if_none_match = NULL) {
      private$as_spatial(
        private$get(sprintf("/v1/pois/%s", dest_id), NULL, if_none_match)
      )
    },

    #' @description Every census block that can reach a point of interest, one row
    #'   per (block, mode). Read every page with `$records()`.
    #' @param dest_id Destination id.
    #' @param mode Travel mode(s) to keep.
    #' @param block Specific block id(s) to keep.
    #' @param max_minutes Upper bound on travel time (up to 30).
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor.
    #' @return An [sf][sf::sf] object, or a [close_reply] when `spatial` is FALSE.
    poi_catchment = function(dest_id, mode = NULL, block = NULL,
                             max_minutes = NULL, limit = NULL, cursor = NULL) {
      private$as_spatial(private$get(
        sprintf("/v1/pois/%s/catchment", dest_id),
        list(mode = mode, block = block, max_minutes = max_minutes,
             limit = limit, cursor = cursor)
      ))
    },

    #' @description Blocks inside a GeoJSON polygon, or a circle (`center` +
    #'   `radius_m`), one row per (block, category, mode). Read every page with
    #'   `$records()`.
    #' @param polygon A GeoJSON polygon or multipolygon (a list).
    #' @param center A circle centre, `list(lon =, lat =)`.
    #' @param radius_m Circle radius, in metres (up to 28000).
    #' @param type Destination type id(s) to keep.
    #' @param mode Travel mode(s) to keep.
    #' @param include_population Add each block's population to its rows.
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor.
    #' @return An [sf][sf::sf] object, or a [close_reply] when `spatial` is FALSE.
    blocks_query = function(polygon = NULL, center = NULL, radius_m = NULL,
                            type = NULL, mode = NULL, include_population = NULL,
                            limit = NULL, cursor = NULL) {
      private$as_spatial(private$post_json(
        "/v1/blocks/query",
        list(polygon = polygon, center = center, radius_m = radius_m,
             type = type, mode = mode, include_population = include_population,
             limit = limit, cursor = cursor)
      ))
    },

    #' @description Per-block travel times for every block in a place (a city or
    #'   town), by place GEOID. Read every page with `$records()`.
    #' @param geoid Census place GEOID.
    #' @param mode Travel mode(s) to keep.
    #' @param type Destination type id(s) to keep.
    #' @param include_population Add each block's population to its rows.
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor.
    #' @return An [sf][sf::sf] object, or a [close_reply] when `spatial` is FALSE.
    place_blocks = function(geoid, mode = NULL, type = NULL,
                            include_population = NULL, limit = NULL,
                            cursor = NULL) {
      private$as_spatial(private$get(
        sprintf("/v1/places/%s/blocks", geoid),
        list(mode = mode, type = type, include_population = include_population,
             limit = limit, cursor = cursor)
      ))
    },

    #' @description Travel-time contours from a block or a lat/lon point. Give
    #'   `minutes` for one threshold, or `contours` for up to four.
    #' @param block Origin block GEOID (or give `lon` + `lat`).
    #' @param lon,lat Origin point, instead of `block`.
    #' @param mode "walk", "bike", or "transit".
    #' @param direction "to" (blocks that can reach the origin) or "from".
    #' @param minutes A single threshold (1 to 60).
    #' @param contours Up to four ascending levels, instead of `minutes`.
    #' @param format "geojson" (polygons) or "blocks" (a block list).
    #' @param v Optional cache-buster, echoed back.
    #' @param if_none_match An ETag to revalidate for free.
    #' @return An [sf][sf::sf] object of contour polygons, or a [close_reply] when
    #'   `spatial` is FALSE or `format` is "blocks".
    isochrone = function(block = NULL, lon = NULL, lat = NULL, mode = NULL,
                         direction = NULL, minutes = NULL, contours = NULL,
                         format = NULL, v = NULL, if_none_match = NULL) {
      if (length(contours) > 1) contours <- paste(contours, collapse = ",")
      reply <- private$get(
        "/v1/isochrone",
        list(block = block, lon = lon, lat = lat, mode = mode,
             direction = direction, minutes = minutes, contours = contours,
             format = format, v = v),
        if_none_match
      )
      if (identical(format, "blocks")) reply else private$as_spatial(reply)
    },

    #' @description Isochrone version, directions, modes, and assumptions (free).
    #' @param if_none_match An ETag to revalidate for free.
    #' @return A [close_reply].
    isochrone_meta = function(if_none_match = NULL) {
      private$get("/v1/isochrone/meta", NULL, if_none_match)
    },

    #' @description Read every record from a paginated method, following the
    #'   cursor to the last page.
    #' @param endpoint Name of a paginated method, such as "pois_search".
    #' @param ... Arguments passed on to that method.
    #' @return An [sf][sf::sf] object, or a list of records when `spatial` is
    #'   FALSE.
    #' @examples
    #' \dontrun{
    #' close$records("pois_search", lat = 41.82, lon = -71.41, radius_m = 1500)
    #' }
    records = function(endpoint, ...) {
      fetch <- self[[endpoint]]
      want_spatial <- self$spatial
      self$spatial <- FALSE                 # collect the raw pages first
      on.exit(self$spatial <- want_spatial)
      out <- list()
      cursor <- NULL
      repeat {
        page <- fetch(..., cursor = cursor)
        out <- c(out, page$results)
        cursor <- page$next_cursor
        if (is.null(cursor)) break
      }
      if (isTRUE(want_spatial)) {
        close_as_sf(.close_reply(data = list(results = out), status = 200L),
                    fetch = TRUE)
      } else {
        out
      }
    }
  ),
  private = list(
    api_key = NULL,
    base_url = NULL,
    timeout = NULL,

    # Convert a feature reply to sf when spatial is on, otherwise pass it through.
    as_spatial = function(reply) {
      if (isTRUE(self$spatial)) close_as_sf(reply, fetch = TRUE) else reply
    },

    # Build the base httr2 request for a path, with auth and our own error
    # handling (we read every status ourselves, including 304).
    req = function(method, path) {
      request <- httr2::request(private$base_url)
      request <- httr2::req_url_path_append(request, path)
      request <- httr2::req_method(request, method)
      request <- httr2::req_timeout(request, private$timeout)
      request <- httr2::req_headers(request, Accept = "application/json")
      if (!is.null(private$api_key)) {
        request <- httr2::req_auth_bearer_token(request, private$api_key)
      }
      httr2::req_error(request, is_error = function(resp) FALSE)
    },

    perform = function(request) {
      resp <- httr2::req_perform(request)
      status <- httr2::resp_status(resp)
      request_id <- httr2::resp_header(resp, "X-Request-Id")
      if (status == 304L) {
        return(.close_reply(
          data = NULL, status = 304L, not_modified = TRUE,
          etag = httr2::resp_header(resp, "ETag"), request_id = request_id
        ))
      }
      if (status >= 400L) .close_abort_problem(resp, request_id)
      data <- if (httr2::resp_has_body(resp)) {
        httr2::resp_body_json(resp)
      } else {
        NULL
      }
      .close_reply(
        data = data, status = status,
        tokens_charged = .as_num(httr2::resp_header(resp, "X-Tokens-Charged")),
        tokens_remaining = .as_num(httr2::resp_header(resp, "X-Tokens-Remaining")),
        etag = httr2::resp_header(resp, "ETag"), request_id = request_id
      )
    },

    get = function(path, query = NULL, if_none_match = NULL) {
      request <- private$req("GET", path)
      query <- .drop_null(query)
      if (length(query) > 0) {
        request <- rlang::inject(
          httr2::req_url_query(request, !!!query, .multi = "explode")
        )
      }
      if (!is.null(if_none_match)) {
        request <- httr2::req_headers(request, `If-None-Match` = if_none_match)
      }
      private$perform(request)
    },

    post_json = function(path, body) {
      request <- private$req("POST", path)
      request <- httr2::req_body_json(request, .drop_null(body), auto_unbox = TRUE)
      private$perform(request)
    }
  )
)

.as_num <- function(x) if (is.null(x) || is.na(x)) NULL else as.numeric(x)

# Turn a problem+json response into a classed condition and stop.
.close_abort_problem <- function(resp, request_id) {
  body <- tryCatch(httr2::resp_body_json(resp), error = function(e) list())
  status <- httr2::resp_status(resp)
  type <- body$type %||% ""
  slug <- if (startsWith(type, PROBLEM_SLUG_PREFIX)) {
    substring(type, nchar(PROBLEM_SLUG_PREFIX) + 1)
  } else if (nzchar(type)) {
    type
  } else {
    paste0("http-", status)
  }
  known <- c("type", "title", "status", "detail")
  retry_after <- .as_num(httr2::resp_header(resp, "Retry-After"))
  rlang::abort(
    message = sprintf("%d %s: %s", status, slug, body$title %||% ""),
    class = c(paste0("close_api_", slug), "close_api_error"),
    status = status,
    slug = slug,
    title = body$title %||% "",
    detail = body$detail,
    request_id = request_id,
    retry_after = retry_after,
    extras = body[setdiff(names(body), known)]
  )
}

.close_reply <- function(data, status, tokens_charged = NULL,
                         tokens_remaining = NULL, etag = NULL,
                         request_id = NULL, not_modified = FALSE) {
  structure(
    list(
      data = data, status = status, tokens_charged = tokens_charged,
      tokens_remaining = tokens_remaining, etag = etag,
      request_id = request_id, not_modified = not_modified,
      results = data$results %||% list(),
      next_cursor = data$next_cursor %||% NULL
    ),
    class = "close_reply"
  )
}

.drop_null <- function(x) x[!vapply(x, is.null, logical(1))]

`%||%` <- function(a, b) if (is.null(a)) b else a

#' The reply object
#'
#' When `spatial` is FALSE, every method returns a `close_reply`: a list with the
#' parsed body plus the metering and caching information as named fields.
#'
#' @section Fields:
#' \describe{
#'   \item{`data`}{The parsed body (a list), or `NULL` for a 304.}
#'   \item{`results`}{The `results` array for list routes (else an empty list).}
#'   \item{`next_cursor`}{The cursor for the next page, or `NULL`.}
#'   \item{`tokens_charged`, `tokens_remaining`}{Token counts; `NULL` on free
#'     routes.}
#'   \item{`etag`}{The response ETag, to pass back as `if_none_match`.}
#'   \item{`status`}{HTTP status code.}
#'   \item{`not_modified`}{`TRUE` for a 304 (`data` is `NULL`).}
#'   \item{`request_id`}{Server request id, handy for support.}
#' }
#' @seealso [close_as_sf()] to turn a reply into an sf object by hand.
#' @name close_reply
NULL

#' Print a close_reply
#'
#' @param x A [close_reply].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @keywords internal
#' @export
print.close_reply <- function(x, ...) {
  cat(sprintf("<close_reply> status=%d", x$status))
  if (!is.null(x$tokens_charged)) {
    cat(sprintf(" charged=%g remaining=%g", x$tokens_charged, x$tokens_remaining))
  }
  if (isTRUE(x$not_modified)) cat(" [not modified]")
  cat("\n")
  invisible(x)
}
