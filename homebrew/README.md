# Homebrew Tap for google_vision_cli

This directory contains the Homebrew formula for installing the `vision` CLI tool.

## Quick Start

```bash
# Add the tap
brew tap cdavis-code/google-vision

# Install the latest development version (HEAD build from source)
brew install --head vision

# Or, once a stable release is tagged:
brew install vision
```

## Formula Details

The formula at [`vision.rb`](vision.rb) installs the `vision` command-line tool — a CLI for making API requests to the Google Vision API (image labeling, face/logo/landmark detection, OCR, explicit content detection, and more).

### Requirements

| Requirement | Notes |
|-------------|-------|
| [Dart SDK](https://dart.dev/get-dart) | Automatically installed by Homebrew as a build dependency |

### How It Works

1. The formula clones the `google_vision_workspace` monorepo at the tagged version
2. `cd`s into `packages/google_vision_cli` and strips `resolution: workspace` from `pubspec.yaml` (avoids pulling in the Flutter dependency from `google_vision_flutter`)
3. Runs `dart pub get` to resolve only the CLI package's dependencies
4. Compiles `bin/vision.dart` to a native binary with `dart compile exe`
5. Installs the resulting binary to Homebrew's `bin` directory

## Releasing a Stable Version

### Steps 1–4: Manual (run locally)

| Step | Action |
|------|--------|
| 1 | Bump `version` in `packages/google_vision_cli/pubspec.yaml` |
| 2 | Add a new entry to `packages/google_vision_cli/CHANGELOG.md` |
| 3 | Run `melos run meta` from the workspace root to regenerate `lib/meta.dart` |
| 4 | Run `melos run analyze` and commit all changes |

### Steps 5–9: Automated (triggered by tag)

Run the **[create-tag](../.github/workflows/create-tag.yaml)** workflow (`workflow_dispatch`) with the new version number — this creates and pushes the git tag.

The tag push triggers three workflows in parallel:

| Workflow | Step | What it does |
|----------|------|-------------|
| [publish-pub-dev](../.github/workflows/publish-pub-dev.yaml) | 5 | Publishes the package to pub.dev (OIDC auth, no token needed) |
| [homebrew-release](../.github/workflows/homebrew-release.yaml) | — | Builds native binaries for macOS (arm64/x64), Linux (x64/arm64), and Windows (x64), attaches them to a GitHub Release |
| [homebrew-formula-update](../.github/workflows/homebrew-formula-update.yaml) | 7–9 | Computes tarball SHA256, updates `Formula/vision.rb` in the tap repo, runs `brew audit` |

### Secrets Required

| Secret | Purpose |
|--------|---------|
| `HOMEBREW_TAP_TOKEN` | GitHub PAT with `repo` scope for pushing to `cdavis-code/homebrew-google-vision` |

> **Note:** No pub.dev token is needed — `publish-pub-dev.yaml` uses OIDC authentication via the `dart-lang/setup-dart` reusable workflow.

## Setting Up the Tap Repository

This `homebrew/` directory is the source for your Homebrew tap. The formula is automatically pushed to the tap repo by the `homebrew-formula-update` workflow on each release.

**One-time setup:**

1. Create a new GitHub repository: **`homebrew-google-vision`**
2. Push the initial formula manually (subsequent updates are automated)
3. Users can then run: `brew tap cdavis-code/google-vision && brew install vision`
