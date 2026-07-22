# Create a Close API client

Create a Close API client

## Usage

``` r
close_client(api_key = NULL, base_url = DEFAULT_BASE_URL, timeout = 30)
```

## Arguments

- api_key:

  API key (ck_live\_ / ck_test\_), created at
  https://account.close.city. Optional: the catalog and health routes
  are free.

- base_url:

  API base URL.

- timeout:

  Request timeout in seconds.

## Value

A `close_client` object to pass to the endpoint functions.
