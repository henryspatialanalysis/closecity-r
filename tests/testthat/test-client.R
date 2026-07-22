# Driven over httr2's response mocking, so no network is touched. Pins the same
# mechanics as the Python suite: bearer auth, token-header surfacing, opaque
# cursor pagination, ETag/304 revalidation, and problem+json -> condition.

json_response <- function(status = 200, body = list(), headers = list()) {
  headers[["Content-Type"]] <- "application/json"
  httr2::response(
    status_code = status,
    headers = headers,
    body = charToRaw(jsonlite::toJSON(body, auto_unbox = TRUE, null = "null"))
  )
}

problem_response <- function(status, slug, title, extra = list()) {
  body <- c(list(type = paste0("https://api.close.city/problems/", slug),
                 title = title, status = status), extra)
  httr2::response(
    status_code = status,
    headers = list(`Content-Type` = "application/problem+json",
                   `X-Request-Id` = "req-123"),
    body = charToRaw(jsonlite::toJSON(body, auto_unbox = TRUE))
  )
}

client <- close_client("ck_test_abc", base_url = "https://api.close.city")


test_that("bearer auth is sent and token headers surface", {
  captured <- NULL
  mock <- function(req) {
    captured <<- req
    json_response(
      body = list(block = list(geoid = "1"), results = list()),
      headers = list(`X-Tokens-Charged` = "1", `X-Tokens-Remaining` = "4999",
                     ETag = "\"abc\"", `X-Request-Id` = "r1")
    )
  }
  reply <- httr2::with_mocked_responses(mock, {
    close_block_summary(client, "410390020001010")
  })
  # httr2 redacts the Authorization value for safety, so assert presence (the
  # free-route test below asserts it is absent without a key).
  expect_false(is.null(captured$headers$Authorization))
  expect_equal(reply$tokens_charged, 1)
  expect_equal(reply$tokens_remaining, 4999)
  expect_equal(reply$etag, "\"abc\"")
  expect_equal(reply$status, 200)
})


test_that("free routes need no key", {
  mock <- function(req) {
    expect_null(req$headers$Authorization)
    json_response(body = list(status = "ok", version = "0.1.0"))
  }
  reply <- httr2::with_mocked_responses(mock, close_health(close_client()))
  expect_equal(reply$data$status, "ok")
  expect_null(reply$tokens_charged)
})


test_that("close_records follows the cursor across pages", {
  pages <- list(
    `NA` = list(results = list(list(dest_id = 1), list(dest_id = 2)),
                next_cursor = "CUR2"),
    CUR2 = list(results = list(list(dest_id = 3)), next_cursor = NULL)
  )
  seen <- c()
  mock <- function(req) {
    cur <- httr2::url_parse(req$url)$query$cursor
    key <- if (is.null(cur)) "NA" else cur
    seen <<- c(seen, key)
    json_response(body = pages[[key]])
  }
  got <- httr2::with_mocked_responses(mock, {
    close_records(close_pois_search, client, lat = 44, lon = -123, radius_m = 1000)
  })
  expect_equal(vapply(got, function(r) r$dest_id, numeric(1)), c(1, 2, 3))
  expect_equal(seen, c("NA", "CUR2"))
})


test_that("blocks_query is a POST carrying the cursor in the body", {
  bodies <- list()
  methods <- c()
  mock <- function(req) {
    methods <<- c(methods, req$method)
    # req_body_json stores the pre-serialised R object at req$body$data.
    parsed <- req$body$data
    bodies[[length(bodies) + 1]] <<- parsed
    nxt <- if (is.null(parsed$cursor)) "C2" else NULL
    json_response(body = list(results = list(list(geoid = "g")), next_cursor = nxt))
  }
  got <- httr2::with_mocked_responses(mock, {
    close_records(close_blocks_query, client,
                  center = list(lon = -123, lat = 44), radius_m = 1000,
                  include_population = TRUE)
  })
  expect_equal(methods, c("POST", "POST"))
  expect_equal(length(got), 2)
  expect_true(bodies[[1]]$include_population)
  expect_equal(bodies[[2]]$cursor, "C2")
})


test_that("If-None-Match yields a free 304 not-modified reply", {
  mock <- function(req) {
    expect_equal(req$headers$`If-None-Match`, "\"etag-1\"")
    httr2::response(status_code = 304, headers = list(ETag = "\"etag-1\""))
  }
  reply <- httr2::with_mocked_responses(mock, {
    close_block_summary(client, "410390020001010", if_none_match = "\"etag-1\"")
  })
  expect_true(reply$not_modified)
  expect_null(reply$data)
  expect_null(reply$tokens_charged)
})


test_that("problem+json becomes a classed condition", {
  cases <- list(
    list(401, "invalid-key"), list(404, "block-not-found"),
    list(429, "tokens-exhausted"), list(400, "invalid-parameters")
  )
  for (case in cases) {
    status <- case[[1]]; slug <- case[[2]]
    mock <- function(req) problem_response(status, slug, "boom")
    err <- tryCatch(
      httr2::with_mocked_responses(mock, close_poi(client, 999)),
      close_api_error = function(e) e
    )
    expect_s3_class(err, "close_api_error")
    expect_s3_class(err, paste0("close_api_", slug))
    expect_equal(err$slug, slug)
    expect_equal(err$status, status)
    expect_equal(err$request_id, "req-123")
  }
})


test_that("rate-limited exposes retry_after and validation extras", {
  mock <- function(req) {
    resp <- httr2::response(
      status_code = 429,
      headers = list(`Content-Type` = "application/problem+json",
                     `Retry-After` = "30", `X-Request-Id` = "req-9"),
      body = charToRaw(jsonlite::toJSON(list(
        type = "https://api.close.city/problems/rate-limited",
        title = "Slow down", status = 429), auto_unbox = TRUE))
    )
    resp
  }
  err <- tryCatch(
    httr2::with_mocked_responses(mock, close_modes(client)),
    close_api_error = function(e) e
  )
  expect_equal(err$retry_after, 30)
})


test_that("isochrone contours vector is collapsed to CSV", {
  seen <- NULL
  mock <- function(req) {
    seen <<- httr2::url_parse(req$url)$query$contours
    json_response(body = list(type = "FeatureCollection", features = list()))
  }
  httr2::with_mocked_responses(mock, {
    close_isochrone(client, block = "410390020001010", contours = c(15, 30, 45))
  })
  expect_equal(seen, "15,30,45")
})

`%||%` <- function(a, b) if (is.null(a)) b else a
