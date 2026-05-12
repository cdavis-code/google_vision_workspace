---
name: release-cli
description: Complete google_vision_cli release workflow including version bump, meta regeneration, pub.dev publish, git tagging, SHA256 computation, and Homebrew formula update. Use when releasing a new version of google_vision_cli, publishing to pub.dev, or updating the Homebrew tap.
---

# Release google_vision_cli

Step-by-step workflow for releasing a new version of the CLI to pub.dev and Homebrew.

## Prerequisites

- [Melos workspace](https://pub.dev/packages/melos) scripts available (`melos run meta`, `melos run analyze`)
- [GitHub MCP](https://github.com/cdavis-code/homebrew-google-vision) access to update the Homebrew formula
- `dart pub publish` authentication set up for pub.dev

## Release Workflow

Copy this checklist and track progress:

```
google_vision_cli Release:
- [ ] Step 1: Bump version in pubspec.yaml
- [ ] Step 2: Update CHANGELOG.md
- [ ] Step 3: Regenerate meta.dart
- [ ] Step 4: Run analysis check
- [ ] Step 5: Publish to pub.dev
- [ ] Step 6: Create and push git tag
- [ ] Step 7: Compute SHA256 for Homebrew
- [ ] Step 8: Update Homebrew formula
- [ ] Step 9: Verify installation
```

### Step 1: Bump version in pubspec.yaml

Update the version line in `packages/google_vision_cli/pubspec.yaml`:

```yaml
version: X.Y.Z
```

### Step 2: Update CHANGELOG.md

Add a new entry at the top of `packages/google_vision_cli/CHANGELOG.md`:

```markdown
## X.Y.Z

* change summary
* another change
```

### Step 3: Regenerate meta.dart

Run from the workspace root to update `lib/meta.dart` in all packages:

```bash
melos run meta
```

### Step 4: Run analysis check

```bash
melos run analyze
```

Fix any warnings or errors before continuing.

### Step 5: Publish to pub.dev

```bash
cd packages/google_vision_cli
dart pub publish --force
```

### Step 6: Create and push git tag

**IMPORTANT**: Only tag after committing all changes from steps 1-4. The tag must point to a commit that contains the version-bumped files so the `vision version` command reports correctly.

```bash
git add .
git commit -m "google_vision_cli vX.Y.Z"
git tag -a vX.Y.Z -m "google_vision_cli vX.Y.Z"
git push origin main vX.Y.Z
```

### Step 7: Compute SHA256 for Homebrew

```bash
curl -sL https://github.com/cdavis-code/google_vision_workspace/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
```

Copy the resulting hash.

### Step 8: Update Homebrew formula

**A. Update local formula** at `homebrew/vision.rb`:

```ruby
version "X.Y.Z"
url "https://github.com/cdavis-code/google_vision_workspace/archive/refs/tags/vX.Y.Z.tar.gz"
sha256 "<hash from step 7>"
```

The `install` block must include `inreplace` to remove `resolution: workspace` (avoids Flutter dependency from `google_vision_flutter` breaking the Dart-only build):

```ruby
def install
  cd "packages/google_vision_cli" do
    inreplace "pubspec.yaml", "resolution: workspace\n", ""
    system "dart", "pub", "get"
    system "dart", "compile", "exe", "bin/vision.dart", "-o", "vision"
    bin.install "vision"
  end
end
```

**B. Push formula update to GitHub tap repo** using the GitHub MCP `create_or_update_file` tool:

| Field | Value |
|-------|-------|
| `owner` | `cdavis-code` |
| `repo` | `homebrew-google-vision` |
| `path` | `Formula/vision.rb` |
| `branch` | `main` |

The `sha` parameter must match the current file SHA on the repo. Read it first with `get_file_contents` if unknown.

### Step 9: Verify installation

```bash
brew update
brew reinstall vision
vision version
```

Expected output: `google_vision_cli vX.Y.Z`

## Files modified

| File | Action |
|------|--------|
| `packages/google_vision_cli/pubspec.yaml` | Bump `version` |
| `packages/google_vision_cli/CHANGELOG.md` | Add new version entry |
| `packages/google_vision_cli/lib/meta.dart` | Auto-generated via `melos run meta` |
| `homebrew/vision.rb` | Update `version`, `url`, `sha256` |
| GitHub `cdavis-code/homebrew-google-vision` | Push updated `Formula/vision.rb` |

## Common issues

### Version mismatch in `vision version`

Caused by tagging before committing version changes. The tarball reflects the tagged commit, so `meta.dart` must be updated AND committed before the tag is created. Follow step 6 exactly.

### `brew install vision` fails with Flutter SDK error

Caused by `resolution: workspace` in `pubspec.yaml`. The `inreplace` in the formula's `install` block removes this line before running `dart pub get`. Ensure this is present in the formula.

### `brew install vision` is HEAD-only

The formula must have a `url` and `sha256` pointing to a tagged tarball. If these are commented out, uncomment them with correct values from step 7.
