# Turn a close_reply into a data.frame. Feature and catalog methods call this for
# you in the "tabular" output mode, and close_as_df() also works by hand. The
# row-shaping here is shared with spatial.R, which adds geometry on top of the
# same frames.

# Top-level keys whose value is the per-record array for a route. "results" covers
# every list and summary route; the rest are the catalog routes.
.close_row_keys <- c(
  'results', 'places', 'modes', 'destination_types', 'components', 'blocks'
)
# Keys never worth copying onto a frame's attributes: the record arrays, the
# GeoJSON feature list, the opaque cursor, and the constant "FeatureCollection".
.close_skip_attr_keys <- c(.close_row_keys, 'features', 'next_cursor', 'type')

# TRUE for an isochrone format = "geojson" body (a custom envelope whose features
# is a list, not a bare FeatureCollection).
.close_is_isochrone <- function(data){
  is.list(data) && !is.null(data$features)
}

.close_reply_meta <- function(x){
  list(
    status = x$status, tokens_charged = x$tokens_charged,
    tokens_remaining = x$tokens_remaining, etag = x$etag,
    request_id = x$request_id
  )
}

# Split a body into rows and the surrounding envelope. The envelope is returned
# only when the rows came from a record array (so its scalar members are metadata
# worth stamping); it is NULL when the body itself is the single row (a POI
# detail) and its members are real columns.
.close_rows_and_envelope <- function(data, key = NULL){
  if(!is.list(data)) return(list(rows = list(), envelope = NULL))
  candidates <- if(is.null(key)) .close_row_keys else c(key, .close_row_keys)
  for(name in candidates){
    if(is.list(data[[name]])){
      return(list(rows = data[[name]], envelope = data))
    }
  }
  list(rows = list(data), envelope = NULL)
}

# Flatten a list of record-lists to a data.frame. Scalar fields become atomic
# columns; fields that are arrays or nested objects (leaf_ids, type_ids, address)
# become list-columns so nothing is silently dropped.
.close_rows_to_df <- function(rows){
  if(length(rows) == 0) return(data.frame())
  keys <- unique(unlist(lapply(rows, names)))
  is_scalar <- function(v) !is.null(v) && length(v) == 1 && !is.list(v)
  out <- data.frame(row.names = seq_along(rows))
  for(key in keys){
    values <- lapply(rows, function(row) row[[key]])
    if(all(vapply(values, function(v) is.null(v) || is_scalar(v), logical(1)))){
      out[[key]] <- unlist(
        lapply(values, function(v) if(is.null(v)) NA else v), use.names = FALSE
      )
    } else {
      out[[key]] <- lapply(values, function(v) if(is.null(v)) NA else v)
    }
  }
  out
}

# Give summary frames an origin "geoid" column so they are self-describing and can
# be stacked across blocks. Only the summary routes carry the origin as an
# envelope "block" list.
.close_broadcast_geoid <- function(df, envelope){
  if(nrow(df) == 0 || 'geoid' %in% names(df)) return(df)
  block <- if(is.list(envelope)) envelope$block else NULL
  geoid <- if(is.list(block)) block$geoid else NULL
  if(is.null(geoid)) return(df)
  cbind(geoid = geoid, df, stringsAsFactors = FALSE)
}

# Attach metering and leftover envelope fields as attributes. R attributes do not
# reliably survive downstream frame operations, so read them right after the call
# (or use output = "raw" when the metadata is load bearing).
.close_stamp_attrs <- function(df, envelope, meta){
  for(name in names(meta)){
    if(!is.null(meta[[name]])) attr(df, name) <- meta[[name]]
  }
  if(is.list(envelope)){
    for(name in names(envelope)){
      if(!(name %in% .close_skip_attr_keys)) attr(df, name) <- envelope[[name]]
    }
  }
  df
}

#' Convert a Close reply to a data.frame
#'
#' Turns a `close_reply` into a plain `data.frame`, one row per record. This is
#' what the client returns in the `"tabular"` output mode; [close_as_sf()] adds
#' geometry on top of the same rows. Metering and envelope metadata (token counts,
#' `block_geoid`, `assumptions`, ...) are attached as attributes.
#'
#' @param x (`close_reply`)\cr A reply, or the same list shape.
#' @param key (`character(1)`, default NULL)\cr Name of the record array to read.
#'   Detected from the body when omitted.
#' @return A `data.frame`. Summary replies gain a broadcast `geoid` column.
#' @examples
#' \dontrun{
#' close <- close_client(output = 'raw')
#' close_as_df(close$modes())
#' }
#' @export
close_as_df <- function(x, key = NULL){
  data <- x$data
  meta <- .close_reply_meta(x)
  if(.close_is_isochrone(data)){
    rows <- lapply(data$features, function(feature) feature$properties %||% list())
    envelope <- data
  } else {
    parts <- .close_rows_and_envelope(data, key)
    rows <- parts$rows
    envelope <- parts$envelope
  }
  df <- .close_rows_to_df(rows)
  df <- .close_broadcast_geoid(df, envelope)
  .close_stamp_attrs(df, envelope, meta)
}

#' @exportS3Method base::as.data.frame
as.data.frame.close_reply <- function(x, row.names = NULL, optional = FALSE, ...){
  close_as_df(x, ...)
}
