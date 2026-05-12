# npm Publishing Setup

## Quick publish

After the package builds and smoke-tests clean:

```bash
cd packages/google_vision_js

# Bug fix
./scripts/publish-npm.sh patch

# New feature
./scripts/publish-npm.sh minor

# Breaking change
./scripts/publish-npm.sh major

# Push the tag to trigger CI
git push origin main --tags
```

## CI workflow

When you push a tag matching `google_vision_js-v*`, GitHub Actions runs:

1. **google_vision_js** — installs npm deps, builds via `npm run build` (dart2js + tsup)
2. **publish-google-vision-js** — if step 1 passes, publishes to npm

```yaml
  google_vision_js:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install npm deps
        working-directory: packages/google_vision_js
        run: npm install
      - name: Build (dart2js + tsup)
        working-directory: packages/google_vision_js
        run: npm run build

  publish-google-vision-js:
    needs: [google_vision_js]
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/google_vision_js-v')
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://registry.npmjs.org'
      - name: Install npm deps
        working-directory: packages/google_vision_js
        run: npm install
      - name: Build (dart2js + tsup)
        working-directory: packages/google_vision_js
        run: npm run build
      - name: Publish to npm
        working-directory: packages/google_vision_js
        run: npm publish --access=public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## NPM Token Setup

1. Generate an npm access token (Automation type, Publish permission):
   ```bash
   npm token create
   ```
2. Add to GitHub:
   - Repository → Settings → Secrets and variables → Actions
   - New repository secret: `NPM_TOKEN`
   - Paste the token

## Verification

After publishing, verify:
- npm: https://www.npmjs.com/package/@unngh/google-vision
- GitHub Actions: check the publish-google-vision-js job
- Install test: `npm install @unngh/google-vision`

## Troubleshooting

| Problem | Fix |
|---------|-----|
| CI doesn't trigger on tag | Tag must match pattern `google_vision_js-v*` |
| `npm publish` auth error | Verify `NPM_TOKEN` secret is set and hasn't expired |
| Version already exists | npm doesn't allow overwrites — bump version |
| Scoped package private error | Always use `--access public` for scoped packages |
