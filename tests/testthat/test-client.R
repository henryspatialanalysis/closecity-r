# Driven over httr2's response mocking, so no network is touched. Pins the
# mechanics the client exists to get right: bearer auth, token-header surfacing,
# opaque cursor pagination, ETag/304 revalidation, and problem+json -> condition.
# The client is built with output = "raw" so methods return the raw close_reply.

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

client <- close_client("ck_live_abc", base_url = "https://api.close.city",
                       output = "raw")


test_that("close_client() builds an R6 CloseClient", {
  expect_s3_class(client, "CloseClient")
  expect_s3_class(client, "R6")
  expect_equal(client$output, "raw")
})


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
    client$block_summary("250173523004004")
  })
  # httr2 redacts the Authorization value, so assert presence.
  expect_false(is.null(captured$headers$Authorization))
  expect_equal(reply$tokens_charged, 1)
  expect_equal(reply$tokens_remaining, 4999)
  expect_equal(reply$etag, "\"abc\"")
  expect_equal(reply$status, 200)
})


test_that("free routes need no key", {
  withr::local_envvar(CLOSECITY_KEY = "")
  mock <- function(req) {
    expect_null(req$headers$Authorization)
    json_response(body = list(status = "ok", version = "0.1.0"))
  }
  reply <- httr2::with_mocked_responses(mock, {
    close_client(output = "raw")$health()
  })
  expect_equal(reply$data$status, "ok")
  expect_null(reply$tokens_charged)
})


test_that("CLOSECITY_KEY supplies the key when none is passed", {
  withr::local_envvar(CLOSECITY_KEY = "ck_live_env")
  captured <- NULL
  mock <- function(req) {
    captured <<- req
    json_response(body = list(modes = list()))
  }
  httr2::with_mocked_responses(mock, {
    close_client(output = "raw")$modes()
  })
  expect_false(is.null(captured$headers$Authorization))
})


test_that("a 401 without a key carries an actionable CLOSECITY_KEY hint", {
  withr::local_envvar(CLOSECITY_KEY = "")
  mock <- function(req) problem_response(401, "missing-key", "Provide an API key.")
  err <- tryCatch(
    httr2::with_mocked_responses(mock, {
      close_client(output = "raw")$block_summary("250173523004004")
    }),
    close_api_error = function(e) e
  )
  expect_s3_class(err, "close_api_error")
  expect_false(is.null(err$hint))
  expect_true(grepl("CLOSECITY_KEY", conditionMessage(err)))
})


test_that("$records() follows the cursor across pages", {
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
    client$records("pois_search", lat = 44, lon = -123, radius_m = 1000)
  })
  expect_equal(vapply(got, function(r) r$dest_id, numeric(1)), c(1, 2, 3))
  expect_equal(seen, c("NA", "CUR2"))
})


test_that("blocks_query is a POST carrying the cursor in the body", {
  bodies <- list()
  methods <- c()
  mock <- function(req) {
    methods <<- c(methods, req$method)
    parsed <- req$body$data
    bodies[[length(bodies) + 1]] <<- parsed
    nxt <- if (is.null(parsed$cursor)) "C2" else NULL
    json_response(body = list(results = list(list(geoid = "g")), next_cursor = nxt))
  }
  got <- httr2::with_mocked_responses(mock, {
    client$records("blocks_query", center = list(lon = -123, lat = 44),
                   radius_m = 1000, mode = "walk", type = 30,
                   include_population = TRUE)
  })
  expect_equal(methods, c("POST", "POST"))
  expect_equal(length(got), 2)
  expect_true(bodies[[1]]$include_population)
  # Scalar mode/type are wrapped as arrays (the POST body needs lists).
  expect_equal(bodies[[1]]$mode, list("walk"))
  expect_equal(bodies[[1]]$type, list(30))
  expect_equal(bodies[[2]]$cursor, "C2")
})


test_that("paginated methods read every page by default", {
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
    client$pois_search(lat = 44, lon = -123, radius_m = 1000)
  })
  # output = "raw": a combined close_reply carrying every page's rows.
  expect_equal(length(got$results), 3)
  expect_equal(seen, c("NA", "CUR2"))
})


test_that("paginate = FALSE fetches only the first page", {
  seen <- c()
  mock <- function(req) {
    cur <- httr2::url_parse(req$url)$query$cursor
    seen <<- c(seen, if (is.null(cur)) "NA" else cur)
    json_response(body = list(results = list(list(dest_id = 1)),
                              next_cursor = "CUR2"))
  }
  got <- httr2::with_mocked_responses(mock, {
    client$pois_search(lat = 44, lon = -123, radius_m = 1000, paginate = FALSE)
  })
  expect_equal(length(got$results), 1)
  expect_equal(seen, "NA")
})


test_that("If-None-Match yields a free 304 not-modified reply", {
  mock <- function(req) {
    expect_equal(req$headers$`If-None-Match`, "\"etag-1\"")
    httr2::response(status_code = 304, headers = list(ETag = "\"etag-1\""))
  }
  reply <- httr2::with_mocked_responses(mock, {
    client$block_summary("250173523004004", if_none_match = "\"etag-1\"")
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
    status <- case[[1]]
    slug <- case[[2]]
    mock <- function(req) problem_response(status, slug, "boom")
    err <- tryCatch(
      httr2::with_mocked_responses(mock, client$poi(999)),
      close_api_error = function(e) e
    )
    expect_s3_class(err, "close_api_error")
    expect_s3_class(err, paste0("close_api_", slug))
    expect_equal(err$slug, slug)
    expect_equal(err$status, status)
    expect_equal(err$request_id, "req-123")
  }
})


test_that("rate-limited exposes retry_after", {
  mock <- function(req) {
    httr2::response(
      status_code = 429,
      headers = list(`Content-Type` = "application/problem+json",
                     `Retry-After` = "30", `X-Request-Id` = "req-9"),
      body = charToRaw(jsonlite::toJSON(list(
        type = "https://api.close.city/problems/rate-limited",
        title = "Slow down", status = 429), auto_unbox = TRUE))
    )
  }
  err <- tryCatch(
    httr2::with_mocked_responses(mock, client$modes()),
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
    client$isochrone(block = "250173523004004", contours = c(15, 30, 45))
  })
  expect_equal(seen, "15,30,45")
})

`%||%` <- function(a, b) if (is.null(a)) b else a
