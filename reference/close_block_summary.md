# Fastest travel time from a block to each destination category

Fastest travel time to each destination category from a census block, by
mode. Metered: one token per returned (category, mode) row.

## Usage

``` r
close_block_summary(
  client,
  geoid,
  mode = NULL,
  type = NULL,
  if_none_match = NULL
)
```

## Arguments

- client:

  A
  [`close_client()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_client.md).

- geoid:

  15-digit census block GEOID.

- mode:

  Mode label(s) to filter by (`"walk"`, `"bike"`, `"transit"`).

- type:

  Destination type id(s) to filter by (see
  [`close_destination_types()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_destination_types.md)).

- if_none_match:

  An ETag to revalidate; returns a free HTTP 304 on a match.

## Value

A
[close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

## See also

Other block endpoints:
[`close_block_pois()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_block_pois.md)

## Examples

``` r
if (FALSE) { # \dontrun{
cl <- close_client("ck_live_...")
close_block_summary(cl, "250173523004004", mode = "walk")
} # }
```
