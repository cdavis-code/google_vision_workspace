#!/usr/bin/env bash
# Compiles the Dart interop entry point into JavaScript using dart2js,
# then bundles the TypeScript layer with tsup.
#
# Output: build/dart/google_vision.js  (dart2js runtime)
#         dist/                        (tsup output: ESM + CJS + .d.ts)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PKG_DIR}"

# Resolve version from pubspec.yaml for display.
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')

echo "==> google_vision_js v${VERSION}"

echo "==> Fetching Dart dependencies"
dart pub get

mkdir -p build/dart

echo "==> Compiling Dart -> JavaScript (dart2js -O4)"
dart compile js \
  -O4 \
  -o build/dart/google_vision.js \
  lib/google_vision_js.dart

# Remove the sibling .deps file that dart2js emits (not needed in dist).
rm -f build/dart/google_vision.js.deps

echo "==> Installing npm dependencies"
npm install

echo "==> Bundling TypeScript (tsup)"
npx tsup

# Copy the dart2js runtime into dist/ so dynamic imports resolve at runtime.
mkdir -p dist
cp build/dart/google_vision.js dist/google_vision.runtime.js

echo ""
echo "==> Build complete"
echo "    Dart runtime:  $(du -h build/dart/google_vision.js | cut -f1)"
echo "    Node ESM:      dist/node.js"
echo "    Node CJS:      dist/node.cjs"
echo "    Browser ESM:   dist/browser.js"
echo "    Types:         dist/index.d.ts"
