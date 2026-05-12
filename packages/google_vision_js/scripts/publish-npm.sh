#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PKG_DIR}"

BUMP="${1:?Usage: publish-npm.sh [major|minor|patch|<version>]}"
PKG_NAME="google_vision"
TAG_PREFIX="google_vision_js-v"

CURRENT="$(node -p "require('./package.json').version")"
if [ "$BUMP" = "major" ] || [ "$BUMP" = "minor" ] || [ "$BUMP" = "patch" ]; then
  NEW="$(npx semver -i "$BUMP" "$CURRENT")"
else
  NEW="$BUMP"
fi
echo "==> Bumping ${PKG_NAME} ${CURRENT} -> ${NEW}"

node -e "
  const pkg = require('./package.json');
  pkg.version = '${NEW}';
  require('fs').writeFileSync('./package.json', JSON.stringify(pkg, null, 2) + '\n');
"

bash scripts/build.sh

if grep -q '"test"' package.json; then
  npm test
fi

git add package.json
git commit -m "chore(${PKG_NAME}): release v${NEW}" || true
git tag -a "${TAG_PREFIX}${NEW}" -m "Release v${NEW}"

echo ""
echo "✅ Ready to publish. Run:"
echo "   git push origin main --tags"
