# Google Vision CLI

[![pub package](https://img.shields.io/pub/v/google_vision_cli.svg)](https://pub.dartlang.org/packages/google_vision_cli)

<img src="https://raw.githubusercontent.com/cdavis-code/google_vision_workspace/main/packages/google_vision_cli/images/banner.svg" alt="Google Vision CLI banner" width="100%" />

A command-line interface for the Google Vision API. Wraps the [`google_vision`](https://pub.dev/packages/google_vision) Dart package to provide image detection and annotation from the terminal.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
  - [Homebrew](#homebrew)
  - [Dart pub](#dart-pub)
- [Prerequisites](#prerequisites)
- [Authentication](#authentication)
- [Usage](#usage)
- [Global Options](#global-options)
- [Commands](#commands)
  - [`version`](#version)
  - [`detect`](#detect)
  - [`crop_hints`](#crop_hints)
  - [`safe_search`](#safe_search)
  - [`highlight`](#highlight)
  - [`score`](#score)
- [Feature Types](#feature-types)
- [License](#license)

## Quick Start

```sh
# Install via Homebrew
brew tap faithoflifedev/google-vision
brew install vision

# Run landmark detection
vision detect --image-file photo.jpg --features LANDMARK_DETECTION
```

## Installation

### Homebrew

```sh
brew tap faithoflifedev/google-vision
brew install vision
```

### Dart pub

```sh
# Activate globally
dart pub global activate google_vision_cli

# Or run directly from the workspace
dart run vision <command> [arguments]
```

## Prerequisites

- A Google Cloud service account with the Vision API enabled
- A JSON credentials file for the service account

## Authentication

The CLI authenticates via **JWT only** using a service account key file (API keys are not supported).

```sh
# Place credentials at the default path
~/.vision/credentials.json

# Or specify a custom path
dart run vision --credential-file /path/to/credentials.json <command>
```

## Usage

```sh
dart run vision [global-options] <command> [command-options]
```

## Global Options

| Option | Default | Description |
|--------|---------|-------------|
| `--credential-file` | `~/.vision/credentials.json` | Path to JWT credentials JSON file |
| `--log-level` | `off` | Log level: `all`, `debug`, `info`, `warning`, `error`, `off` |

## Commands

### `version`

Display the package name and version.

```sh
dart run vision version
```

### `detect`

Run image detection and annotation for a batch of images or files.

| Option | Required | Description |
|--------|----------|-------------|
| `--image-file` | yes | Path to the image file to process |
| `--features` | yes | Comma-separated list of [detection types](#feature-types) |
| `--pages` | no | Comma-separated list of page numbers for PDF/TIFF/GIF (max 5) |
| `--max-results` | no | Maximum results per feature (default: 10, max: 50) |

```sh
# Label detection on an image
dart run vision detect --image-file photo.jpg --features LABEL_DETECTION

# Multiple features on a single image
dart run vision detect --image-file photo.jpg \
  --features LABEL_DETECTION,FACE_DETECTION,TEXT_DETECTION

# Process specific pages of a PDF
dart run vision detect --image-file document.pdf \
  --features DOCUMENT_TEXT_DETECTION --pages 1,2,3
```

### `crop_hints`

Get crop suggestion vertices for an image.

| Option | Required | Description |
|--------|----------|-------------|
| `--image-file` | yes | Path to the image file to process |
| `--aspect-ratios` | no | Comma-separated list of aspect ratios as floats (e.g. `1.33333` for 4:3) |
| `--pages` | no | Comma-separated list of page numbers for PDF/TIFF/GIF (max 5) |

```sh
# Get default crop hints
dart run vision crop_hints --image-file photo.jpg

# Specify desired aspect ratios
dart run vision crop_hints --image-file photo.jpg \
  --aspect-ratios 1.33333,1.77778
```

### `safe_search`

Detect explicit content (adult, violence, medical, racy) in an image.

| Option | Required | Description |
|--------|----------|-------------|
| `--image-file` | yes | Path to the image file to process |

```sh
dart run vision safe_search --image-file photo.jpg
```

### `highlight`

Draw bounding boxes around detected objects and save the result.

| Option | Required | Description |
|--------|----------|-------------|
| `--image-file` | yes | Path to the image file to process |
| `--output-file` | yes | Path to save the annotated image |
| `--features` | no | Comma-separated list of [detection types](#feature-types) |
| `--line-color` | no | Box color: `red`, `green`, `blue`, `white`, `black` (default: `red`) |
| `--max-results` | no | Maximum results per feature (default: 10, max: 50) |

```sh
# Highlight detected faces
dart run vision highlight --image-file photo.jpg \
  --output-file annotated.jpg --features FACE_DETECTION

# Highlight objects and landmarks in blue
dart run vision highlight --image-file photo.jpg \
  --output-file annotated.jpg \
  --features OBJECT_LOCALIZATION,LANDMARK_DETECTION \
  --line-color blue
```

### `score`

Get confidence scores for detected objects as a JSON array.

| Option | Required | Description |
|--------|----------|-------------|
| `--image-file` | yes | Path to the image file to process |
| `--features` | no | Comma-separated list of [detection types](#feature-types) |
| `--max-results` | no | Maximum results per feature (default: 10, max: 50) |

```sh
# Get face detection confidence scores
dart run vision score --image-file photo.jpg \
  --features FACE_DETECTION

# Get label detection scores
dart run vision score --image-file photo.jpg \
  --features LABEL_DETECTION

# Output: [0.98, 0.95, 0.87, ...]
```

## Feature Types

| Feature | Description |
|---------|-------------|
| `FACE_DETECTION` | Detect faces with facial attributes |
| `LANDMARK_DETECTION` | Detect popular landmarks |
| `LOGO_DETECTION` | Detect product logos |
| `LABEL_DETECTION` | Label image content (objects, activities, etc.) |
| `TEXT_DETECTION` | OCR — detect and extract text |
| `DOCUMENT_TEXT_DETECTION` | Dense text/document OCR with page/block/paragraph structure |
| `SAFE_SEARCH_DETECTION` | Adult/violent/explicit content likelihood |
| `IMAGE_PROPERTIES` | Dominant colors and image attributes |
| `CROP_HINTS` | Suggested crop region vertices |
| `WEB_DETECTION` | Web references and similar images |
| `PRODUCT_SEARCH` | Product search against a product set |
| `OBJECT_LOCALIZATION` | Detect and locate multiple objects |

See the [Google Vision API documentation](https://cloud.google.com/vision/docs/reference/rest/v1/Feature#Type) for details.

## License

This project is licensed under the terms included in the repository.
