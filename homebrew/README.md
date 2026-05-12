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

- [Dart SDK](https://dart.dev/get-dart) — automatically installed by Homebrew as a build dependency when installing from source

### How It Works

1. The formula clones the `google_vision_workspace` monorepo
2. Runs `dart pub get` at the workspace root to resolve dependencies
3. Compiles `packages/google_vision_cli/bin/vision.dart` to a native binary with `dart compile exe`
4. Installs the resulting binary to `/usr/local/bin/vision`

## Releasing a Stable Version

1. Push a version tag (e.g. `git tag v2.0.0 && git push origin v2.0.0`)
2. The [homebrew-release workflow](../.github/workflows/homebrew-release.yaml) builds platform-specific binaries and attaches them to a GitHub Release
3. Update the formula's `url` and `sha256` to point to the release tarball
4. Commit and push the formula update to your tap repository

## Setting Up the Tap Repository

This `homebrew/` directory is the source for your Homebrew tap. To make it installable:

1. Create a new GitHub repository: **`homebrew-google-vision`**
2. Copy the contents of this `homebrew/` directory into that repo
3. Users can then run: `brew tap cdavis-code/google-vision && brew install vision`
