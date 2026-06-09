# Changelog

## 2.1.1

* chore: bumped `google_vision` dependency to `^2.2.1`
* chore: added `.pubignore` to exclude `out.md`, `doc/api/`, and `.dart_tool/` from publication

## 2.1.0

* feat: new `markdown` command converts DOCUMENT_TEXT_DETECTION output to markdown (headers, lists, tables, checkboxes, image placeholders)

## 2.0.1+1

* README installation instructions updated

## 2.0.1

* Homebrew tap updated to cdavis-code

## 2.0.0+12

* version bump for publish
* security: catch-all exception handling in CLI runner
* security: null-safe image decode in highlight command
* banner SVG layout fixes

## 2.0.0+11

* security: auth header logging disabled, API key moved to headers
* security: redact private key from `toString()` output
* security: typed exceptions replace generic `Exception` throws

## 2.0.0+10

* pub.dev update

## 2.0.0+9

* pub.dev update

## 2.0.0+8

* dependency bump
* SDK bump

## 2.0.0+6

* initial CLI release
* commands: detect, crop_hints, safe_search, highlight, score, version
