# close_map() builds a plotly htmlwidget from an sf; no network. Skipped when the
# Suggests-only mapping packages are absent.

make_points <- function() {
  sf::st_as_sf(
    data.frame(name = c("A", "B"), lon = c(-71.41, -71.42), lat = c(41.82, 41.83)),
    coords = c("lon", "lat"), crs = 4326
  )
}

make_polys <- function() {
  sq <- function(x, y) {
    sf::st_polygon(list(rbind(
      c(x, y), c(x + 0.01, y), c(x + 0.01, y + 0.01), c(x, y + 0.01), c(x, y)
    )))
  }
  sf::st_sf(
    name = c("g1", "g2"), near = c(TRUE, FALSE),
    geometry = sf::st_sfc(sq(-71.42, 41.82), sq(-71.40, 41.82), crs = 4326)
  )
}


test_that("close_map draws a point map", {
  skip_if_not_installed("plotly")
  m <- close_map(make_points(), color = "#e8590c")
  expect_s3_class(m, "plotly")
})


test_that("close_map draws a polygon map with a highlight column", {
  skip_if_not_installed("plotly")
  skip_if_not_installed("geojsonsf")
  m <- close_map(make_polys(), color = "#2f9e44", highlight = "near")
  expect_s3_class(m, "plotly")
})
