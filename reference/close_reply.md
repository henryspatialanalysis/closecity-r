# The reply object

When `spatial` is FALSE, every method returns a `close_reply`: a list
with the parsed body plus the metering and caching information as named
fields.

## Fields

- `data`:

  The parsed body (a list), or `NULL` for a 304.

- `results`:

  The `results` array for list routes (else an empty list).

- `next_cursor`:

  The cursor for the next page, or `NULL`.

- `tokens_charged`, `tokens_remaining`:

  Token counts; `NULL` on free routes.

- `etag`:

  The response ETag, to pass back as `if_none_match`.

- `status`:

  HTTP status code.

- `not_modified`:

  `TRUE` for a 304 (`data` is `NULL`).

- `request_id`:

  Server request id, handy for support.

## See also

[`close_as_sf()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_sf.md)
to turn a reply into an sf object by hand.
