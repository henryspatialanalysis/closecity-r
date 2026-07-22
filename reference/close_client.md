# Create a Close API client

Builds a
[CloseClient](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.md).
The catalog and health routes are free, so a key is optional. Every data
route needs one (a `ck_live_` or `ck_test_` key), created at
https://account.close.city.

## Usage

``` r
close_client(
  api_key = NULL,
  base_url = DEFAULT_BASE_URL,
  timeout = 30,
  spatial = TRUE
)
```

## Arguments

- api_key:

  Your API key, or NULL for the free routes.

- base_url:

  API base URL.

- timeout:

  Request timeout, in seconds.

- spatial:

  Return feature results as
  [sf](https://r-spatial.github.io/sf/reference/sf.html) objects?
  Defaults to TRUE. Set FALSE to work with the raw
  [close_reply](https://henryspatialanalysis.github.io/closecity-r/reference/close_reply.md)
  instead.

## Value

A
[CloseClient](https://henryspatialanalysis.github.io/closecity-r/reference/CloseClient.md).
Make calls through its methods.

## Examples

``` r
if (FALSE) { # \dontrun{
close <- close_client("ck_live_your_key")   # use your own key here
close$block_summary("440070008001068", mode = "walk")
} # }
```
