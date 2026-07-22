## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* local Ubuntu 22.04, R release
* GitHub Actions: ubuntu-latest (release, oldrel-1)

## Notes

* Examples that call the live Close API are wrapped in `\dontrun{}`, and the
  vignettes are not evaluated (`eval = FALSE`), so the check makes no network
  requests. The unit tests use mocked HTTP responses (httr2 + webfakes).
* `sf` and `tigris` are used only in the optional `close_as_sf()` path and are
  in Suggests, guarded by `requireNamespace()`.
