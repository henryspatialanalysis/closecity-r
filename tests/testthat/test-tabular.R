# Tests for the tabular output mode: catalog and summary routes become plain data
# frames, metering rides on attributes, and output = "tabular" never downloads
# block boundaries. Driven over httr2's response mocking, so no network is touched.

json_response <- function(status = 200, body = list(), headers = list()){
  headers[["Content-Type"]] <- "application/json"
  httr2::response(
    status_code = status,
    headers = headers,
    body = charToRaw(jsonlite::toJSON(body, auto_unbox = TRUE, null = "null"))
  )
}

tab_client <- function(output = "tabular"){
  close_client("ck_live_abc", base_url = "https://api.close.city", output = output)
}


test_that("modes() becomes a data.frame", {
  mock <- function(req){
    json_response(body = list(modes = list(
      list(mode_id = 1, mode = "walk", description = "Walking"),
      list(mode_id = 2, mode = "bike", description = "Biking")
    )))
  }
  df <- httr2::with_mocked_responses(mock, tab_client()$modes())
  expect_s3_class(df, "data.frame")
  expect_equal(df$mode, c("walk", "bike"))
  expect_equal(names(df), c("mode_id", "mode", "description"))
})


test_that("destination_types() keeps leaf_ids as a list-column", {
  mock <- function(req){
    json_response(body = list(destination_types = list(
      list(dest_type_id = 61, name = "Frequent transit",
           label = "frequent_transit", is_leaf = FALSE,
           leaf_ids = list(201, 203))
    )))
  }
  df <- httr2::with_mocked_responses(mock, tab_client()$destination_types())
  expect_true(is.list(df$leaf_ids))
  expect_equal(unlist(df$leaf_ids[[1]]), c(201, 203))
  expect_false(df$is_leaf[[1]])
})


test_that("places() in tabular mode is a plain frame with lon/lat", {
  mock <- function(req){
    json_response(body = list(places = list(
      list(name = "Providence", geoid = "4459000", lon = -71.42, lat = 41.82)
    )))
  }
  df <- httr2::with_mocked_responses(mock, tab_client()$places("Providence"))
  expect_s3_class(df, "data.frame")
  expect_false(inherits(df, "sf"))
  expect_true(all(c("name", "geoid", "lon", "lat") %in% names(df)))
})


test_that("block_summary() broadcasts geoid and stamps metering on attrs", {
  mock <- function(req){
    json_response(
      body = list(
        block = list(geoid = "440070008001068", population = 31,
                     land_area_m2 = 4.0),
        results = list(
          list(dest_type_id = 30, mode = "walk", travel_time = 6.5),
          list(dest_type_id = 31, mode = "walk", travel_time = 12.0)
        )
      ),
      headers = list(`X-Tokens-Charged` = "2", `X-Tokens-Remaining` = "998",
                     ETag = "\"e1\"", `X-Request-Id` = "r1")
    )
  }
  df <- httr2::with_mocked_responses(mock, {
    tab_client()$block_summary("440070008001068")
  })
  expect_equal(df$geoid, c("440070008001068", "440070008001068"))
  expect_equal(names(df)[1], "geoid")
  expect_equal(attr(df, "tokens_charged"), 2)
  expect_equal(attr(df, "tokens_remaining"), 998)
  expect_equal(attr(df, "block")$population, 31)
})


test_that("point_summary() stamps resolved_block on attrs", {
  mock <- function(req){
    json_response(body = list(
      resolved_block = "440070008001068",
      block = list(geoid = "440070008001068", population = 31,
                   land_area_m2 = 4.0),
      results = list(list(dest_type_id = 30, mode = "walk", travel_time = 6.5))
    ))
  }
  df <- httr2::with_mocked_responses(mock, {
    tab_client()$point_summary(41.82, -71.42)
  })
  expect_equal(df$geoid, "440070008001068")
  expect_equal(attr(df, "resolved_block"), "440070008001068")
})


test_that("block_pois() stamps block_geoid, not a geoid column", {
  mock <- function(req){
    json_response(body = list(
      block_geoid = "440070008001068",
      results = list(list(dest_id = 1, mode = "walk", travel_time = 5.0,
                          name = "Shop", lon = -71.4, lat = 41.8)),
      next_cursor = NULL
    ))
  }
  df <- httr2::with_mocked_responses(mock, {
    tab_client()$block_pois("440070008001068")
  })
  expect_false("geoid" %in% names(df))
  expect_equal(attr(df, "block_geoid"), "440070008001068")
})


test_that("blocks_query() in tabular mode needs no geometry download", {
  mock <- function(req){
    json_response(body = list(
      results = list(list(geoid = "440070008001068", dest_type_id = 30,
                          mode_id = 1, travel_time = 6.5, population = 31)),
      next_cursor = NULL
    ))
  }
  df <- httr2::with_mocked_responses(mock, {
    tab_client()$blocks_query(center = list(lon = -71.42, lat = 41.82),
                              radius_m = 1000)
  })
  expect_equal(df$geoid, "440070008001068")
  expect_equal(df$mode_id, 1)  # areal rows carry the int mode_id
})


test_that("isochrone(format = 'blocks') in tabular mode is a frame", {
  mock <- function(req){
    json_response(body = list(
      blocks = list(list(geoid = "440070008001068", travel_min = 7)),
      reachable_blocks = 1, block = "440070008001068", direction = "from",
      mode = "walk", version = "v1", assumptions = list()
    ))
  }
  df <- httr2::with_mocked_responses(mock, {
    tab_client()$isochrone(block = "440070008001068", format = "blocks")
  })
  expect_equal(df$travel_min, 7)
  expect_equal(attr(df, "reachable_blocks"), 1)
  expect_equal(attr(df, "direction"), "from")
})


test_that("isochrone geojson in tabular mode is feature properties", {
  mock <- function(req){
    json_response(body = list(
      type = "FeatureCollection",
      features = list(
        list(type = "Feature", geometry = NULL,
             properties = list(contour = 15, mode = "walk", reachable_blocks = 9)),
        list(type = "Feature", geometry = NULL,
             properties = list(contour = 30, mode = "walk", reachable_blocks = 20))
      ),
      block = "440070008001068", direction = "to", mode = "walk",
      version = "v1", assumptions = list()
    ))
  }
  df <- httr2::with_mocked_responses(mock, {
    tab_client()$isochrone(block = "440070008001068", contours = c(15, 30))
  })
  expect_equal(df$contour, c(15, 30))
  expect_equal(attr(df, "block"), "440070008001068")
})


test_that("per-call output overrides the client default", {
  mock <- function(req){
    json_response(body = list(modes = list(
      list(mode_id = 1, mode = "walk", description = "Walking")
    )))
  }
  raw <- httr2::with_mocked_responses(mock, tab_client()$modes(output = "raw"))
  expect_s3_class(raw, "close_reply")
})


test_that("a 304 stays a raw reply in every mode", {
  mock <- function(req){
    httr2::response(status_code = 304, headers = list(ETag = "\"e1\""))
  }
  reply <- httr2::with_mocked_responses(mock, {
    tab_client()$block_summary("440070008001068", if_none_match = "\"e1\"")
  })
  expect_s3_class(reply, "close_reply")
  expect_true(reply$not_modified)
})


test_that("an invalid output value is rejected", {
  expect_error(close_client("ck_live_abc", output = "geojson"))
})


test_that("empty results give an empty data.frame", {
  mock <- function(req){
    json_response(body = list(results = list(), next_cursor = NULL))
  }
  df <- httr2::with_mocked_responses(mock, {
    tab_client()$pois_search(lat = 44, lon = -123, radius_m = 1000)
  })
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0)
})


test_that("$records() in tabular mode returns one combined frame", {
  pages <- list(
    `NA` = list(results = list(list(dest_id = 1, name = "A", lat = 44, lon = -123)),
                next_cursor = "C2"),
    C2 = list(results = list(list(dest_id = 2, name = "B", lat = 44.1, lon = -123.1)),
              next_cursor = NULL)
  )
  mock <- function(req){
    cur <- httr2::url_parse(req$url)$query$cursor
    key <- if(is.null(cur)) "NA" else cur
    json_response(body = pages[[key]],
                  headers = list(`X-Tokens-Charged` = "1"))
  }
  df <- httr2::with_mocked_responses(mock, {
    tab_client()$records("pois_search", lat = 44, lon = -123, radius_m = 1000)
  })
  expect_s3_class(df, "data.frame")
  expect_equal(df$dest_id, c(1, 2))
  expect_equal(attr(df, "tokens_charged"), 2)  # summed across the two pages
})


test_that("close_as_df() works on a hand-built reply", {
  r <- structure(
    list(data = list(places = list(
      list(name = "X", geoid = "1", lon = 0, lat = 0))),
      status = 200L, results = list(), next_cursor = NULL),
    class = "close_reply"
  )
  df <- close_as_df(r, key = "places")
  expect_equal(df$name, "X")
})
