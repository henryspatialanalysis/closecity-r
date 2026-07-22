# Convert a Close reply to a data.frame

Turns a `close_reply` into a plain `data.frame`, one row per record.
This is what the client returns in the `"tabular"` output mode;
[`close_as_sf()`](https://henryspatialanalysis.github.io/closecity-r/reference/close_as_sf.md)
adds geometry on top of the same rows. Metering and envelope metadata
(token counts, `block_geoid`, `assumptions`, ...) are attached as
attributes.

## Usage

``` r
close_as_df(x, key = NULL)
```

## Arguments

- x:

  (`close_reply`)  
  A reply, or the same list shape.

- key:

  (`character(1)`, default NULL)  
  Name of the record array to read. Detected from the body when omitted.

## Value

A `data.frame`. Summary replies gain a broadcast `geoid` column.

## Examples

``` r
if (FALSE) { # \dontrun{
close <- close_client(output = 'raw')
close_as_df(close$modes())
} # }
```
