# Offline tests for the opt-in spatial converters. No network, no TIGER download:
# POI/isochrone geometry is inherent, and the block join uses a tiny in-memory sf.
# Skipped entirely when `sf` is not installed.

reply <- function(data) {
  structure(
    list(data = data, status = 200L,
         results = data$results %||% list(), next_cursor = NULL),
    class = "close_reply"
  )
}

test_that("POI rows become an sf of points", {
  skip_if_not_installed("sf")
  r <- reply(list(results = list(
    list(dest_id = 1, name = "Cafe A", lat = 41.82, lon = -71.41),
    list(dest_id = 2, name = "Cafe B", lat = 41.83, lon = -71.40)
  )))
  out <- close_as_sf(r)
  expect_s3_class(out, "sf")
  expect_equal(nrow(out), 2)
  expect_true(all(sf::st_geometry_type(out) == "POINT"))
  expect_equal(unname(sf::st_coordinates(out)[1, "X"]), -71.41)
})

test_that("single POI detail becomes one point", {
  skip_if_not_installed("sf")
  out <- close_as_sf(reply(list(dest_id = 7, name = "Library",
                                lat = 41.0, lon = -71.0, type_ids = list(43))))
  expect_equal(nrow(out), 1)
  expect_true(sf::st_geometry_type(out) == "POINT")
})

test_that("isochrone features become polygons", {
  skip_if_not_installed("sf")
  # GeoJSON Polygon coordinates: array of rings, each ring an array of [x,y].
  square <- list(list(c(-71.4, 41.8), c(-71.4, 41.9), c(-71.3, 41.9),
                      c(-71.3, 41.8), c(-71.4, 41.8)))
  r <- reply(list(
    type = "FeatureCollection",
    features = list(list(
      type = "Feature",
      geometry = list(type = "Polygon", coordinates = square),
      properties = list(contour = 15, mode = "walk", reachable_blocks = 12)
    )),
    block = "440070036001010", mode = "walk"
  ))
  out <- close_as_sf(r)
  expect_s3_class(out, "sf")
  expect_equal(nrow(out), 1)
  expect_true(grepl("POLYGON", as.character(sf::st_geometry_type(out))[1]))
  expect_equal(out$contour, 15)
})

test_that("block rows need geometry and join on a supplied sf", {
  skip_if_not_installed("sf")
  r <- reply(list(results = list(
    list(geoid = "100", dest_type_id = 30, mode_id = 1, travel_time = 6.5,
         population = 1187),
    list(geoid = "200", dest_type_id = 30, mode_id = 1, travel_time = 12.0,
         population = 640)
  )))
  # Without geometry it refuses, clearly.
  expect_error(close_as_sf(r), "block_geometry")
  # A tiny fake block frame keyed on GEOID20.
  poly <- function(x0) sf::st_polygon(list(rbind(
    c(x0, 0), c(x0, 1), c(x0 + 1, 1), c(x0 + 1, 0), c(x0, 0))))
  bg <- sf::st_sf(GEOID20 = c("100", "200"),
                  geometry = sf::st_sfc(poly(0), poly(1), crs = 4326))
  out <- close_as_sf(r, block_geometry = bg)
  expect_s3_class(out, "sf")
  expect_equal(nrow(out), 2)
  expect_true(all(grepl("POLYGON", as.character(sf::st_geometry_type(out)))))
  # The join normalises the key to "geoid" so the reply's own column survives.
  expect_true("geoid" %in% names(out))
  expect_equal(out$travel_time[out$geoid == "100"], 6.5)
})

test_that("sf::st_as_sf S3 method dispatches to close_as_sf", {
  skip_if_not_installed("sf")
  r <- reply(list(results = list(list(dest_id = 1, lat = 41.8, lon = -71.4))))
  out <- sf::st_as_sf(r)
  expect_s3_class(out, "sf")
  expect_equal(nrow(out), 1)
})

`%||%` <- function(a, b) if (is.null(a)) b else a
