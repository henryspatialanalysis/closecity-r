# closecity (R SDK)

R client for the Close travel-time API (https://api.close.city). R6 class-based,
returns `sf` by default. pkgdown docs deploy to GitHub Pages; CRAN is the eventual
target. Public repo: `henryspatialanalysis/closecity-r`. The Python sibling is
`henryspatialanalysis/closecity-python` -- keep the two SDKs behaviourally in step.

## Conventions (these are binding -- do not re-litigate)

- **Prose:** follow the humanizer STYLE (no em dashes, no hype, short active
  sentences, Oxford comma). Beginner audience: keep the "Words you will see" glossary
  current. Explain, do not sell.
- **ASCII only** in all code and docs (no smart quotes, arrows, or non-ASCII glyphs).
- **Attribution:** copyright and funder is "Henry Spatial Analysis", never "Close".
  Maintainer email `nat@henryspatialanalysis.com` (CRAN needs a real person).
- **R style:** Nat's style, modelled on the `mbg` package -- line length 90, spaces
  around `=` even inside calls, `<-` assignment. Roxygen with `markdown = TRUE` and
  `r6 = TRUE`; run `roxygen2::roxygenise()` after touching `@` tags and commit the
  regenerated `man/*.Rd` + `NAMESPACE` together.
- **API shape:** one R6 method per route, called as `close$method()`. Build clients
  with `close_client()`, not `$new()`.
- **Spatial by default:** feature methods (POIs, catchments, areal blocks, isochrones)
  return `sf`. The client `spatial` field defaults `TRUE`; `spatial = FALSE` (on the
  client or per call) returns the raw `close_reply`. Catalog/places/summaries stay raw.
- **Dependencies:** `sf` is a hard dependency (Imports). `tigris` is Suggested and used
  only to fetch block boundaries for the GEOID-only block routes (`fetch = TRUE`).
- **Tutorials (vignettes):** dead-simple and linear, **no helper functions**. Pull
  destination-type ids from the **free catalog** (`close$destination_types()`), never
  hardcode numeric codes. Draw a **map at each stage**. **No token-cost talk.** After a
  placeholder key, inline `# use your own key here`.
- **Example cities:** Somerville MA (home search), Richmond VA (amenity basket),
  Providence RI (competitor walksheds). **No Seattle anywhere.**
- **Docs execute live** at build time (see below), guarded on `CLOSECITY_KEY` so a
  keyless / CRAN build stays green.

## Gotchas (hard-won -- do not re-hit)

- **`~/R/rlib` shadowing:** an older functional `closecity` may be installed in
  `~/R/rlib`; `library(closecity)` in a README/vignette knit picks it up and you get
  `close$method` -> "attempt to apply non-function". **Reinstall the R6 source first**
  (`R CMD INSTALL -l ~/R/rlib .`) before every local doc build. CI does this via
  `local::.` in `pkgdown.yaml`.
- **Block-join key must be `geoid`:** `.close_sf_blocks()` renames the block-geometry
  key column to `"geoid"` before `merge(..., by = "geoid")`. Do NOT go back to
  `merge(by.x = geoid_col, by.y = "geoid")` -- R names the joined column after `by.x`,
  which drops the `geoid` column the reply rows carry, and every `blocks$geoid`
  downstream silently becomes `NULL` (-> 0-row subsets -> empty-sf plot crash).
- **`blocks_query` needs JSON arrays:** the POST `/v1/blocks/query` body requires list
  fields, so scalar `mode`/`type` are wrapped with `.close_as_array()`. A scalar mode
  returns 400.
- **CRS:** TIGER blocks arrive in NAD83 (EPSG:4269); the block converter reprojects to
  4326 so they match POI/isochrone geometry. `sf` spatial ops error on mismatched CRS.
- **Blocks TIGER lacks** (e.g. water blocks) get empty geometry from the join; the
  converter drops them (NA-safe) so plotting and spatial joins work.
- **`place_blocks()` (`/v1/places/{geoid}/blocks`) is BROKEN server-side:** it times
  out (15s Lambda) for every real place. Tutorials use `blocks_query(center, radius_m)`
  instead. Leave the wrapper, but do not build examples on it until the API is fixed.

## Local live doc build (this EFS host)

```bash
export R_LIBS_USER=~/R/rlib PATH="$HOME/pandoc/bin:$PATH" RSTUDIO_PANDOC="$HOME/pandoc/bin"
export CLOSECITY_KEY=$(aws ssm get-parameter --name /wtm-api/internal-test-key \
  --with-decryption --region us-west-2 --query Parameter.Value --output text)  # do not print it
R CMD INSTALL -l ~/R/rlib .            # reinstall the R6 source FIRST (shadowing gotcha)
Rscript -e '.libPaths(c("~/R/rlib", .libPaths())); \
  rmarkdown::render("README.Rmd", quiet = TRUE); \
  pkgdown::build_site(".", new_process = FALSE, install = FALSE, preview = FALSE)'
```

Vignettes guard `eval = nzchar(Sys.getenv("CLOSECITY_KEY"))`, a hidden setup chunk
builds the real client, and a display-only ```r block shows the placeholder key. Builds
are slow (tigris downloads county blocks once, then caches). Tests: `testthat::test_local(".")`.

## Git

Read-only unless Nat says otherwise; Nat runs commit sessions (modular, single-sentence,
present-tense messages, no AI-attribution trailers). Push is a separate gate.
