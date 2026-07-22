# Core client: construction, request performance, problem+json -> condition,
# and the reply structure that surfaces metering + caching metadata.

DEFAULT_BASE_URL <- "https://api.close.city"
PROBLEM_SLUG_PREFIX <- "https://api.close.city/problems/"

#' Create a Close API client
#'
#' @param api_key API key (ck_live_ / ck_test_), created at
#'   https://account.close.city. Optional: the catalog and health routes are free.
#' @param base_url API base URL.
#' @param timeout Request timeout in seconds.
#' @return A `close_client` object to pass to the endpoint functions.
#' @export
close_client <- function(api_key = NULL,
                         base_url = DEFAULT_BASE_URL,
                         timeout = 30) {
  structure(
    list(api_key = api_key, base_url = sub("/$", "", base_url), timeout = timeout),
    class = "close_client"
  )
}

# Build the base httr2 request for a path, with auth + our own error handling
# (we inspect every status ourselves, including 304, so disable httr2's default).
.close_req <- function(client, method, path) {
  req <- httr2::request(client$base_url)
  req <- httr2::req_url_path_append(req, path)
  req <- httr2::req_method(req, method)
  req <- httr2::req_timeout(req, client$timeout)
  req <- httr2::req_headers(req, Accept = "application/json")
  if (!is.null(client$api_key)) {
    req <- httr2::req_auth_bearer_token(req, client$api_key)
  }
  # We classify statuses ourselves (problem+json, 304); never auto-abort.
  httr2::req_error(req, is_error = function(resp) FALSE)
}

.as_num <- function(x) if (is.null(x) || is.na(x)) NULL else as.numeric(x)

# Turn a problem+json response into a classed condition and abort.
.close_abort_problem <- function(resp, request_id) {
  body <- tryCatch(httr2::resp_body_json(resp), error = function(e) list())
  status <- httr2::resp_status(resp)
  type <- body$type %||% ""
  slug <- if (startsWith(type, PROBLEM_SLUG_PREFIX)) {
    substring(type, nchar(PROBLEM_SLUG_PREFIX) + 1)
  } else if (nzchar(type)) type else paste0("http-", status)
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

# Perform a request and return a `close_reply`.
.close_perform <- function(req) {
  resp <- httr2::req_perform(req)
  status <- httr2::resp_status(resp)
  request_id <- httr2::resp_header(resp, "X-Request-Id")

  if (status == 304L) {
    return(.close_reply(
      data = NULL, status = 304L, not_modified = TRUE,
      etag = httr2::resp_header(resp, "ETag"), request_id = request_id
    ))
  }
  if (status >= 400L) {
    .close_abort_problem(resp, request_id)
  }
  data <- if (httr2::resp_has_body(resp)) httr2::resp_body_json(resp) else NULL
  .close_reply(
    data = data,
    status = status,
    tokens_charged = .as_num(httr2::resp_header(resp, "X-Tokens-Charged")),
    tokens_remaining = .as_num(httr2::resp_header(resp, "X-Tokens-Remaining")),
    etag = httr2::resp_header(resp, "ETag"),
    request_id = request_id
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

# A GET with optional query + If-None-Match.
.close_get <- function(client, path, query = NULL, if_none_match = NULL) {
  req <- .close_req(client, "GET", path)
  query <- .drop_null(query)
  if (length(query) > 0) {
    req <- rlang::inject(httr2::req_url_query(req, !!!query, .multi = "explode"))
  }
  if (!is.null(if_none_match)) {
    req <- httr2::req_headers(req, `If-None-Match` = if_none_match)
  }
  .close_perform(req)
}

# A POST with a JSON body (used by /v1/blocks/query).
.close_post_json <- function(client, path, body) {
  req <- .close_req(client, "POST", path)
  req <- httr2::req_body_json(req, .drop_null(body), auto_unbox = TRUE)
  .close_perform(req)
}

.drop_null <- function(x) x[!vapply(x, is.null, logical(1))]

`%||%` <- function(a, b) if (is.null(a)) b else a

#' The reply object returned by every endpoint
#'
#' Every endpoint returns a `close_reply`: an S3-classed list carrying the parsed
#' body plus the metering and caching metadata as first-class fields.
#'
#' @section Fields:
#' \describe{
#'   \item{`data`}{The parsed JSON body (a list), or `NULL` on a 304.}
#'   \item{`results`}{The `results` array for list endpoints (else an empty list).}
#'   \item{`next_cursor`}{Keyset cursor for the next page, or `NULL`.}
#'   \item{`tokens_charged`, `tokens_remaining`}{Token accounting; `NULL` on free
#'     and member-unmetered replies.}
#'   \item{`etag`}{Response ETag, to pass back as `if_none_match` for a free 304.}
#'   \item{`status`}{HTTP status code.}
#'   \item{`not_modified`}{`TRUE` for a free 304 revalidation (`data` is `NULL`).}
#'   \item{`request_id`}{Server request id, useful for support.}
#' }
#' @seealso [close_as_sf()] to convert a POI/isochrone/block reply to `sf`.
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
