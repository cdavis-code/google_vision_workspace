# Changelog

## 1.0.2

* fix: sync runtime version string in `js_bindings.dart` to match package version

## 1.0.1

* chore: bumped `google_vision` dependency to `^2.2.1`
* docs: removed `withGenerator()` section (not implemented in JS bindings)
* docs: corrected Dart SDK requirement to `^3.12.0`

## 1.0.0

* Initial release of the Google Vision JS interop package
* Dart `dart:js_interop` wrapper for the google_vision core library
* Supports API key and JWT authentication
* Image annotation: label detection, face detection, text detection, safe search, and more
* Compiles to JavaScript via `dart compile js` for Node.js and browser usage
* Publishable to npm
