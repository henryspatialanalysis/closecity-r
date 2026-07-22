# The reply object returned by every endpoint

Every endpoint returns a `close_reply`: an S3-classed list carrying the
parsed body plus the metering and caching metadata as first-class
fields.

## Fields

- `data`:

  The parsed JSON body (a list), or `NULL` on a 304.

- `results`:

  The `results` array for list endpoints (else an empty list).

- `next_cursor`:

  Keyset cursor for the next page, or `NULL`.

- `tokens_charged`, `tokens_remaining`:

  Token accounting; `NULL` on free and member-unmetered replies.

- `etag`:

  Response ETag, to pass back as `if_none_match` for a free 304.

- `status`:

  HTTP status code.

- `not_modified`:

  `TRUE` for a free 304 revalidation (`data` is `NULL`).

- `request_id`:

  Server request id, useful for support.

## See also

[`close_as_sf()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_sf.md)
to convert a POI/isochrone/block reply to `sf`.
