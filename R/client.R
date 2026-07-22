# The client is an R6 object that holds your connection settings and gives you one
# method per public route. Build it with close_client(), then make calls through
# its methods, e.g. close$block_summary('440070008001068', mode = 'walk').
#
# By default every route returns tabular data: an sf object where geometry applies
# (points, isochrone and block polygons) and a plain data frame otherwise. The
# output argument (on the client, or per call) switches between 'spatial',
# 'tabular' (a data frame everywhere, no boundary download), and 'raw' (the
# close_reply).

DEFAULT_BASE_URL <- 'https://api.close.city'
PROBLEM_SLUG_PREFIX <- 'https://api.close.city/problems/'
OUTPUT_MODES <- c('spatial', 'tabular', 'raw')

#' Create a Close API client
#'
#' Builds a [CloseClient]. The catalog and health routes are free, so a key is
#' optional. Every data route needs one (a `ck_live_` key), created at
#' https://account.close.city (5,000 free tokens on signup, no card).
#'
#' @param api_key (`character(1)`, default NULL)\cr Your API key, or NULL for the
#'   free routes. When NULL, the `CLOSECITY_KEY` environment variable is used if
#'   set.
#' @param base_url (`character(1)`)\cr API base URL.
#' @param timeout (`numeric(1)`, default 30)\cr Request timeout, in seconds.
#' @param output (`character(1)`, default `'spatial'`)\cr How results come back:
#'   `'spatial'` returns an [sf][sf::sf] object where geometry applies and a data
#'   frame otherwise; `'tabular'` returns a data frame for every route and never
#'   downloads block boundaries; `'raw'` returns the [close_reply].
#' @return A [CloseClient]. Make calls through its methods.
#' @examples
#' \dontrun{
#' close <- close_client('ck_live_your_key')   # use your own key here
#' close$block_summary('440070008001068', mode = 'walk')
#' }
#' @export
close_client <- function(
  api_key = NULL, base_url = DEFAULT_BASE_URL, timeout = 30, output = 'spatial'
){
  CloseClient$new(
    api_key = api_key, base_url = base_url, timeout = timeout, output = output
  )
}

#' Close API client
#'
#' An R6 object that holds your connection settings and gives you one method per
#' public route. Create it with [close_client()] rather than calling `$new()`.
#' Results come back per the `output` field: an [sf][sf::sf] object where geometry
#' applies, a data frame otherwise, or a [close_reply] when `output` is `'raw'`.
#'
#' @importFrom R6 R6Class
#' @export
CloseClient <- R6::R6Class(
  'CloseClient',
  public = list(

    #' @field output (`character(1)`)\cr
    #' How results come back: `'spatial'`, `'tabular'`, or `'raw'`. Change it any
    #' time, or override it per call with the method's `output` argument.
    output = 'spatial',

    #' @description Create a client. Prefer [close_client()].
    #' @param api_key Your API key, or NULL for the free routes. When NULL, the
    #'   `CLOSECITY_KEY` environment variable is used if set.
    #' @param base_url API base URL.
    #' @param timeout Request timeout, in seconds.
    #' @param output One of `'spatial'`, `'tabular'`, or `'raw'`.
    initialize = function(
      api_key = NULL, base_url = DEFAULT_BASE_URL, timeout = 30,
      output = 'spatial'
    ){
      if(is.null(api_key)){
        env_key <- Sys.getenv('CLOSECITY_KEY', unset = '')
        if(nzchar(env_key)) api_key <- env_key
      }
      private$api_key <- api_key
      private$has_key <- !is.null(api_key)
      private$base_url <- sub('/$', '', base_url)
      private$timeout <- timeout
      self$output <- match.arg(output, OUTPUT_MODES)
    },

    #' @description Liveness check (free). Always a raw [close_reply].
    #' @return A [close_reply].
    health = function() private$get('/v1/health'),

    #' @description Publication time of the newest data (free). Always a raw reply.
    #' @return A [close_reply].
    last_updated = function() private$get('/v1/last-updated'),

    #' @description Travel modes and their numeric ids (free).
    #' @param output Override the client's output mode for this call.
    #' @return A data frame, or a [close_reply] when `output` is `'raw'`.
    modes = function(output = NULL){
      private$deliver(
        private$get('/v1/meta/modes'), geometry = FALSE, key = 'modes',
        output = output
      )
    },

    #' @description Destination-type taxonomy (free). Use it to look up the numeric
    #'   `type` ids the data routes filter on; a parent type expands to its
    #'   `leaf_ids`.
    #' @param output Override the client's output mode for this call.
    #' @return A data frame, or a [close_reply] when `output` is `'raw'`.
    destination_types = function(output = NULL){
      private$deliver(
        private$get('/v1/meta/destination-types'), geometry = FALSE,
        key = 'destination_types', output = output
      )
    },

    #' @description Active version of each dataset component (free).
    #' @param output Override the client's output mode for this call.
    #' @return A data frame, or a [close_reply] when `output` is `'raw'`.
    vintage = function(output = NULL){
      private$deliver(
        private$get('/v1/meta/vintage'), geometry = FALSE, key = 'components',
        output = output
      )
    },

    #' @description Look up a city or town by name (free). Each match carries its
    #'   census place GEOID and centre point.
    #' @param q Name to search for, such as "Providence".
    #' @param limit Most matches to return (1 to 20).
    #' @param output Override the client's output mode for this call.
    #' @return An [sf][sf::sf] of points (a data frame in tabular mode, a
    #'   [close_reply] when `output` is `'raw'`).
    places = function(q, limit = NULL, output = NULL){
      private$deliver(
        private$get('/v1/places', list(q = q, limit = limit)),
        geometry = TRUE, key = 'places', output = output
      )
    },

    #' @description Fastest travel time from a census block to each destination
    #'   category, by mode.
    #' @param geoid 15-digit census block GEOID.
    #' @param mode Travel mode(s) to keep: "walk", "bike", "transit".
    #' @param type Destination type id(s) to keep.
    #' @param if_none_match An ETag from an earlier reply, to revalidate for free.
    #' @param output Override the client's output mode for this call.
    #' @return A data frame with a broadcast `geoid` column, or a [close_reply]
    #'   when `output` is `'raw'`.
    block_summary = function(
      geoid, mode = NULL, type = NULL, if_none_match = NULL, output = NULL
    ){
      private$deliver(
        private$get(
          sprintf('/v1/blocks/%s/summary', geoid),
          list(mode = mode, type = type), if_none_match
        ),
        geometry = FALSE, key = 'results', output = output
      )
    },

    #' @description Nearby points of interest and their travel time from a block,
    #'   one row per (POI, mode). Reads every page by default.
    #' @param geoid 15-digit census block GEOID.
    #' @param mode Travel mode(s) to keep.
    #' @param type Destination type id(s) to keep.
    #' @param dest_id Specific destination id(s) to keep.
    #' @param max_minutes Upper bound on travel time (up to 30).
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor from a previous reply's `next_cursor`; supplying
    #'   one fetches only that page.
    #' @param paginate Follow `next_cursor` and return every page (the default);
    #'   set `FALSE` for the first page only.
    #' @param output Override the client's output mode for this call.
    #' @return An [sf][sf::sf] of points (a data frame in tabular mode, a
    #'   [close_reply] when `output` is `'raw'`).
    block_pois = function(
      geoid, mode = NULL, type = NULL, dest_id = NULL, max_minutes = NULL,
      limit = NULL, cursor = NULL, paginate = TRUE, output = NULL
    ){
      fetch_page <- function(cur) private$get(
        sprintf('/v1/blocks/%s/pois', geoid),
        list(
          mode = mode, type = type, dest_id = dest_id,
          max_minutes = max_minutes, limit = limit, cursor = cur
        )
      )
      private$deliver(
        private$collect(fetch_page, paginate, cursor),
        geometry = TRUE, output = output
      )
    },

    #' @description Like `$block_summary()`, but from the block containing a
    #'   lat/lon point. The resolved block is echoed as `resolved_block` and
    #'   broadcast to a `geoid` column.
    #' @param lat Latitude.
    #' @param lon Longitude.
    #' @param mode Travel mode(s) to keep.
    #' @param type Destination type id(s) to keep.
    #' @param if_none_match An ETag to revalidate for free.
    #' @param output Override the client's output mode for this call.
    #' @return A data frame, or a [close_reply] when `output` is `'raw'`.
    point_summary = function(
      lat, lon, mode = NULL, type = NULL, if_none_match = NULL, output = NULL
    ){
      private$deliver(
        private$get(
          '/v1/point/summary',
          list(lat = lat, lon = lon, mode = mode, type = type), if_none_match
        ),
        geometry = FALSE, key = 'results', output = output
      )
    },

    #' @description Like `$block_pois()`, but from the block containing a lat/lon
    #'   point. Reads every page by default.
    #' @param lat Latitude.
    #' @param lon Longitude.
    #' @param mode Travel mode(s) to keep.
    #' @param type Destination type id(s) to keep.
    #' @param dest_id Specific destination id(s) to keep.
    #' @param max_minutes Upper bound on travel time (up to 30).
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor; supplying one fetches only that page.
    #' @param paginate Follow `next_cursor` and return every page (the default);
    #'   set `FALSE` for the first page only.
    #' @param output Override the client's output mode for this call.
    #' @return An [sf][sf::sf] of points (a data frame in tabular mode, a
    #'   [close_reply] when `output` is `'raw'`).
    point_pois = function(
      lat, lon, mode = NULL, type = NULL, dest_id = NULL, max_minutes = NULL,
      limit = NULL, cursor = NULL, paginate = TRUE, output = NULL
    ){
      fetch_page <- function(cur) private$get(
        '/v1/point/pois',
        list(
          lat = lat, lon = lon, mode = mode, type = type, dest_id = dest_id,
          max_minutes = max_minutes, limit = limit, cursor = cur
        )
      )
      private$deliver(
        private$collect(fetch_page, paginate, cursor),
        geometry = TRUE, output = output
      )
    },

    #' @description Search points of interest by bounding box, or by a circle
    #'   (`lat` + `lon` + `radius_m`). Reads every page by default.
    #' @param lat,lon Circle centre.
    #' @param radius_m Circle radius, in metres (up to 50000).
    #' @param bbox Bounding box, "min_lon,min_lat,max_lon,max_lat".
    #' @param type Destination type id(s) to keep.
    #' @param q Name text to match.
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor; supplying one fetches only that page.
    #' @param paginate Follow `next_cursor` and return every page (the default);
    #'   set `FALSE` for the first page only.
    #' @param output Override the client's output mode for this call.
    #' @return An [sf][sf::sf] of points (a data frame in tabular mode, a
    #'   [close_reply] when `output` is `'raw'`).
    pois_search = function(
      lat = NULL, lon = NULL, radius_m = NULL, bbox = NULL, type = NULL,
      q = NULL, limit = NULL, cursor = NULL, paginate = TRUE, output = NULL
    ){
      fetch_page <- function(cur) private$get(
        '/v1/pois',
        list(
          lat = lat, lon = lon, radius_m = radius_m, bbox = bbox, type = type,
          q = q, limit = limit, cursor = cur
        )
      )
      private$deliver(
        private$collect(fetch_page, paginate, cursor),
        geometry = TRUE, output = output
      )
    },

    #' @description Details for one point of interest.
    #' @param dest_id Destination id.
    #' @param if_none_match An ETag to revalidate for free.
    #' @param output Override the client's output mode for this call.
    #' @return An [sf][sf::sf] of one point (a data frame in tabular mode, a
    #'   [close_reply] when `output` is `'raw'`).
    poi = function(dest_id, if_none_match = NULL, output = NULL){
      private$deliver(
        private$get(sprintf('/v1/pois/%s', dest_id), NULL, if_none_match),
        geometry = TRUE, output = output
      )
    },

    #' @description Every census block that can reach a point of interest, one row
    #'   per (block, mode). Reads every page by default.
    #' @param dest_id Destination id.
    #' @param mode Travel mode(s) to keep.
    #' @param block Specific block id(s) to keep.
    #' @param max_minutes Upper bound on travel time (up to 30).
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor; supplying one fetches only that page.
    #' @param paginate Follow `next_cursor` and return every page (the default);
    #'   set `FALSE` for the first page only.
    #' @param output Override the client's output mode for this call.
    #' @return An [sf][sf::sf] of block polygons (a data frame in tabular mode, a
    #'   [close_reply] when `output` is `'raw'`).
    poi_catchment = function(
      dest_id, mode = NULL, block = NULL, max_minutes = NULL, limit = NULL,
      cursor = NULL, paginate = TRUE, output = NULL
    ){
      fetch_page <- function(cur) private$get(
        sprintf('/v1/pois/%s/catchment', dest_id),
        list(
          mode = mode, block = block, max_minutes = max_minutes,
          limit = limit, cursor = cur
        )
      )
      private$deliver(
        private$collect(fetch_page, paginate, cursor),
        geometry = TRUE, output = output
      )
    },

    #' @description Blocks inside a GeoJSON polygon, or a circle (`center` +
    #'   `radius_m`), one row per (block, category, mode). Rows carry the numeric
    #'   `mode_id` (join `$modes()` to label it). Reads every page by default.
    #' @param polygon A GeoJSON polygon or multipolygon (a list).
    #' @param center A circle centre, `list(lon =, lat =)`.
    #' @param radius_m Circle radius, in metres (up to 28000).
    #' @param type Destination type id(s) to keep.
    #' @param mode Travel mode(s) to keep.
    #' @param include_population Add each block's population to its rows.
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor; supplying one fetches only that page.
    #' @param paginate Follow `next_cursor` and return every page (the default);
    #'   set `FALSE` for the first page only.
    #' @param output Override the client's output mode for this call.
    #' @return An [sf][sf::sf] of block polygons (a data frame in tabular mode, a
    #'   [close_reply] when `output` is `'raw'`).
    blocks_query = function(
      polygon = NULL, center = NULL, radius_m = NULL, type = NULL, mode = NULL,
      include_population = NULL, limit = NULL, cursor = NULL, paginate = TRUE,
      output = NULL
    ){
      fetch_page <- function(cur) private$post_json(
        '/v1/blocks/query',
        list(
          polygon = polygon, center = center, radius_m = radius_m,
          type = .close_as_array(type), mode = .close_as_array(mode),
          include_population = include_population, limit = limit,
          cursor = cur
        )
      )
      private$deliver(
        private$collect(fetch_page, paginate, cursor),
        geometry = TRUE, output = output
      )
    },

    #' @description Per-block travel times for every block in a place (a city or
    #'   town), by place GEOID. Rows carry the numeric `mode_id` (join `$modes()`
    #'   to label it). Reads every page by default.
    #' @param geoid Census place GEOID.
    #' @param mode Travel mode(s) to keep.
    #' @param type Destination type id(s) to keep.
    #' @param include_population Add each block's population to its rows.
    #' @param limit Rows per page (up to 1000).
    #' @param cursor Page cursor; supplying one fetches only that page.
    #' @param paginate Follow `next_cursor` and return every page (the default);
    #'   set `FALSE` for the first page only.
    #' @param output Override the client's output mode for this call.
    #' @return An [sf][sf::sf] of block polygons (a data frame in tabular mode, a
    #'   [close_reply] when `output` is `'raw'`).
    place_blocks = function(
      geoid, mode = NULL, type = NULL, include_population = NULL, limit = NULL,
      cursor = NULL, paginate = TRUE, output = NULL
    ){
      fetch_page <- function(cur) private$get(
        sprintf('/v1/places/%s/blocks', geoid),
        list(
          mode = mode, type = type, include_population = include_population,
          limit = limit, cursor = cur
        )
      )
      private$deliver(
        private$collect(fetch_page, paginate, cursor),
        geometry = TRUE, output = output
      )
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
    #' @param output Override the client's output mode for this call.
    #' @return An [sf][sf::sf] (contour polygons for geojson, block polygons for
    #'   blocks), a data frame in tabular mode, or a [close_reply] when `output`
    #'   is `'raw'`.
    isochrone = function(
      block = NULL, lon = NULL, lat = NULL, mode = NULL, direction = NULL,
      minutes = NULL, contours = NULL, format = NULL, v = NULL,
      if_none_match = NULL, output = NULL
    ){
      if(length(contours) > 1) contours <- paste(contours, collapse = ',')
      reply <- private$get(
        '/v1/isochrone',
        list(
          block = block, lon = lon, lat = lat, mode = mode,
          direction = direction, minutes = minutes, contours = contours,
          format = format, v = v
        ),
        if_none_match
      )
      private$deliver(reply, geometry = TRUE, output = output)
    },

    #' @description Isochrone version, directions, modes, and assumptions (free).
    #'   Always a raw [close_reply].
    #' @param if_none_match An ETag to revalidate for free.
    #' @return A [close_reply].
    isochrone_meta = function(if_none_match = NULL){
      private$get('/v1/isochrone/meta', NULL, if_none_match)
    },

    #' @description Read every record from a paginated method, following the cursor
    #'   to the last page. The paginated methods now read every page by default, so
    #'   this is rarely needed; it remains for explicit control and back-compat.
    #' @param endpoint Name of a paginated method, such as "pois_search".
    #' @param ... Arguments passed on to that method.
    #' @param output Override the client's output mode for this call.
    #' @return A data frame (an [sf][sf::sf] in spatial mode), or a list of records
    #'   when `output` is `'raw'`.
    #' @examples
    #' \dontrun{
    #' close$records("pois_search", lat = 41.82, lon = -71.41, radius_m = 1500)
    #' }
    records = function(endpoint, ..., output = NULL){
      mode <- private$resolve_output(output)
      fetch <- self[[endpoint]]
      out <- list()
      cursor <- NULL
      charged <- 0
      last <- NULL
      repeat{
        page <- fetch(..., cursor = cursor, paginate = FALSE, output = 'raw')
        out <- c(out, page$results)
        if(!is.null(page$tokens_charged)) charged <- charged + page$tokens_charged
        last <- page
        cursor <- page$next_cursor
        if(is.null(cursor)) break
      }
      if(identical(mode, 'raw')) return(out)
      combined <- .close_reply(
        data = list(results = out), status = last$status %||% 200L,
        tokens_charged = if(charged > 0) charged else NULL,
        tokens_remaining = last$tokens_remaining, etag = last$etag,
        request_id = last$request_id
      )
      private$deliver(combined, geometry = TRUE, output = mode)
    }
  ),
  private = list(
    api_key = NULL,
    has_key = FALSE,
    base_url = NULL,
    timeout = NULL,

    # Resolve a per-call output against the client default, validating it.
    resolve_output = function(output){
      match.arg(output %||% self$output, OUTPUT_MODES)
    },

    # Fetch one page, or (paginate and no explicit cursor) every page, following
    # next_cursor. fetch_page(cursor) returns a close_reply. Returns a single or
    # a combined close_reply, mirroring the reply shape deliver() expects. The
    # combined reply keeps the last page's data envelope (so route-level fields
    # such as block_geoid / resolved_block / dest_id survive), swapping in every
    # page's rows and clearing the cursor.
    collect = function(fetch_page, paginate, cursor){
      if(!isTRUE(paginate) || !is.null(cursor)) return(fetch_page(cursor))
      out <- list()
      charged <- 0
      last <- NULL
      cur <- NULL
      repeat{
        page <- fetch_page(cur)
        out <- c(out, page$results)
        if(!is.null(page$tokens_charged)) charged <- charged + page$tokens_charged
        last <- page
        cur <- page$next_cursor
        if(is.null(cur)) break
      }
      data <- if(is.list(last$data)) last$data else list()
      data$results <- out
      data$next_cursor <- NULL
      .close_reply(
        data = data, status = last$status %||% 200L,
        tokens_charged = if(charged > 0) charged else NULL,
        tokens_remaining = last$tokens_remaining, etag = last$etag,
        request_id = last$request_id
      )
    },

    # Shape a reply per the resolved output mode. geometry says whether the route
    # can carry geometry in spatial mode; key names the record array for tabular.
    deliver = function(reply, geometry, key = NULL, output = NULL){
      mode <- private$resolve_output(output)
      if(identical(mode, 'raw')) return(reply)
      if(isTRUE(reply$not_modified)) return(reply)
      if(identical(mode, 'spatial') && isTRUE(geometry)){
        close_as_sf(reply, fetch = TRUE)
      } else {
        close_as_df(reply, key = key)
      }
    },

    # Build the base httr2 request for a path, with auth and our own error handling
    # (we read every status ourselves, including 304).
    req = function(method, path){
      request <- httr2::request(private$base_url) |>
        httr2::req_url_path_append(path) |>
        httr2::req_method(method) |>
        httr2::req_timeout(private$timeout) |>
        httr2::req_headers(Accept = 'application/json')
      if(!is.null(private$api_key)){
        request <- httr2::req_auth_bearer_token(request, private$api_key)
      }
      httr2::req_error(request, is_error = function(resp) FALSE)
    },

    perform = function(request){
      resp <- httr2::req_perform(request)
      status <- httr2::resp_status(resp)
      request_id <- httr2::resp_header(resp, 'X-Request-Id')
      if(status == 304L){
        return(.close_reply(
          data = NULL, status = 304L, not_modified = TRUE,
          etag = httr2::resp_header(resp, 'ETag'), request_id = request_id
        ))
      }
      if(status >= 400L) .close_abort_problem(resp, request_id, private$has_key)
      data <- if(httr2::resp_has_body(resp)) httr2::resp_body_json(resp) else NULL
      .close_reply(
        data = data, status = status,
        tokens_charged = .as_num(httr2::resp_header(resp, 'X-Tokens-Charged')),
        tokens_remaining = .as_num(httr2::resp_header(resp, 'X-Tokens-Remaining')),
        etag = httr2::resp_header(resp, 'ETag'), request_id = request_id
      )
    },

    get = function(path, query = NULL, if_none_match = NULL){
      request <- private$req('GET', path)
      query <- .drop_null(query)
      if(length(query) > 0){
        request <- rlang::inject(
          httr2::req_url_query(request, !!!query, .multi = 'explode')
        )
      }
      if(!is.null(if_none_match)){
        request <- httr2::req_headers(request, `If-None-Match` = if_none_match)
      }
      private$perform(request)
    },

    post_json = function(path, body){
      request <- private$req('POST', path) |>
        httr2::req_body_json(.drop_null(body), auto_unbox = TRUE)
      private$perform(request)
    }
  )
)

.as_num <- function(x) if(is.null(x) || is.na(x)) NULL else as.numeric(x)

# Turn a problem+json response into a classed condition and stop. When a 401
# arrives and no key was supplied, append an actionable hint about CLOSECITY_KEY.
.close_abort_problem <- function(resp, request_id, has_key = TRUE){
  body <- tryCatch(httr2::resp_body_json(resp), error = function(e) list())
  status <- httr2::resp_status(resp)
  type <- body$type %||% ''
  slug <- if(startsWith(type, PROBLEM_SLUG_PREFIX)){
    substring(type, nchar(PROBLEM_SLUG_PREFIX) + 1)
  } else if(nzchar(type)){
    type
  } else {
    paste0('http-', status)
  }
  known <- c('type', 'title', 'status', 'detail')
  retry_after <- .as_num(httr2::resp_header(resp, 'Retry-After'))
  hint <- if(status == 401L && !isTRUE(has_key)){
    paste0(
      'No API key set. Pass close_client(api_key = ...) or set the ',
      'CLOSECITY_KEY environment variable. Create a free key (5,000 tokens, ',
      'no card) at https://account.close.city.'
    )
  } else NULL
  message <- sprintf('%d %s: %s', status, slug, body$title %||% '')
  if(!is.null(hint)) message <- paste0(message, ' -- ', hint)
  rlang::abort(
    message = message,
    class = c(paste0('close_api_', slug), 'close_api_error'),
    status = status,
    slug = slug,
    title = body$title %||% '',
    detail = body$detail,
    request_id = request_id,
    retry_after = retry_after,
    hint = hint,
    extras = body[setdiff(names(body), known)]
  )
}

.close_reply <- function(
  data, status, tokens_charged = NULL, tokens_remaining = NULL, etag = NULL,
  request_id = NULL, not_modified = FALSE
){
  structure(
    list(
      data = data, status = status, tokens_charged = tokens_charged,
      tokens_remaining = tokens_remaining, etag = etag,
      request_id = request_id, not_modified = not_modified,
      results = data$results %||% list(),
      next_cursor = data$next_cursor %||% NULL
    ),
    class = 'close_reply'
  )
}

.drop_null <- function(x) x[!vapply(x, is.null, logical(1))]

# Force a value to a JSON array (so a single mode/type still serialises as [x]).
# The POST /v1/blocks/query body requires list fields, unlike the GET routes.
.close_as_array <- function(x) if(is.null(x)) NULL else as.list(x)

`%||%` <- function(a, b) if(is.null(a)) b else a

#' The reply object
#'
#' When `output` is `'raw'`, every method returns a `close_reply`: a list with the
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
#' @seealso [close_as_df()] and [close_as_sf()] to convert a reply by hand.
#' @name close_reply
NULL

#' Print a close_reply
#'
#' @param x A [close_reply].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @keywords internal
#' @export
print.close_reply <- function(x, ...){
  cat(sprintf('<close_reply> status=%d', x$status))
  if(!is.null(x$tokens_charged)){
    cat(sprintf(' charged=%g remaining=%g', x$tokens_charged, x$tokens_remaining))
  }
  if(isTRUE(x$not_modified)) cat(' [not modified]')
  cat('\n')
  invisible(x)
}
