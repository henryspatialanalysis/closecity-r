# Create a Close API client

Builds a
[CloseClient](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.md).
The catalog and health routes are free, so a key is optional. Every data
route needs one (a `ck_live_` key), created at
https://account.close.city (5,000 free tokens on signup, no card).

## Usage

``` r
close_client(
  api_key = NULL,
  base_url = DEFAULT_BASE_URL,
  timeout = 30,
  output = "spatial"
)
```

## Arguments

- api_key:

  (`character(1)`, default NULL)  
  Your API key, or NULL for the free routes. When NULL, the
  `CLOSECITY_KEY` environment variable is used if set.

- base_url:

  (`character(1)`)  
  API base URL.

- timeout:

  (`numeric(1)`, default 30)  
  Request timeout, in seconds.

- output:

  (`character(1)`, default `'spatial'`)  
  How results come back: `'spatial'` returns an
  [sf](https://r-spatial.github.io/sf/reference/sf.html) object where
  geometry applies and a data frame otherwise; `'tabular'` returns a
  data frame for every route and never downloads block boundaries;
  `'raw'` returns the
  [close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md).

## Value

A
[CloseClient](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.md).
Make calls through its methods.

## Examples

``` r
if (FALSE) { # \dontrun{
close <- close_client('ck_live_your_key')   # use your own key here
close$block_summary('440070008001068', mode = 'walk')
} # }
```
