## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* local Ubuntu 22.04, R release
* GitHub Actions: ubuntu-latest (release, oldrel-1)

## Notes

* Examples that call the live Close API are wrapped in `\dontrun{}`. The vignette
  code chunks only run when a `CLOSECITY_KEY` environment variable is set, which it
  is not during `R CMD check`, so the check makes no network requests. The unit
  tests use mocked HTTP responses via `httr2::with_mocked_responses()`.
* `sf` and `tigris` are used only in the optional `close_as_sf()` path and are
  in Suggests, guarded by `requireNamespace()`.
