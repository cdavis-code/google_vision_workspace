# Google Vision Workspace

Melos-managed Dart/Flutter monorepo for the [Google Vision API](https://cloud.google.com/vision).

[![pub package](https://img.shields.io/pub/v/google_vision.svg)](https://pub.dartlang.org/packages/google_vision)
[![pub package](https://img.shields.io/pub/v/google_vision_flutter.svg)](https://pub.dartlang.org/packages/google_vision_flutter)

## Packages

| Package | Description | Pub |
|---------|-------------|-----|
| [google_vision](packages/google_vision) | Core Dart REST client for image annotation, OCR, and document analysis | [![pub](https://img.shields.io/pub/v/google_vision.svg)](https://pub.dartlang.org/packages/google_vision) |
| [google_vision_cli](packages/google_vision_cli) | CLI tool for running Vision API requests from the terminal | [![pub](https://img.shields.io/pub/v/google_vision_cli.svg)](https://pub.dartlang.org/packages/google_vision_cli) |
| [google_vision_flutter](packages/google_vision_flutter) | Flutter widget wrapping the core library | [![pub](https://img.shields.io/pub/v/google_vision_flutter.svg)](https://pub.dartlang.org/packages/google_vision_flutter) |

## Features

- **Image Labeling** — identify objects, locations, activities, and more
- **Face Detection** — detect faces and facial attributes (emotion, headwear, etc.)
- **Logo Detection** — recognize popular brand logos
- **Landmark Detection** — identify natural and man-made landmarks
- **Optical Character Recognition (OCR)** — extract text from images and documents
- **Safe Search** — detect explicit content across multiple categories
- **Crop Hints** — suggest optimal image crops
- **Web Detection** — find matching images and pages on the web

## Quick Start

### Dart (core library)

```dart
import 'package:google_vision/google_vision.dart';

final googleVision = await GoogleVision.withApiKey('YOUR_API_KEY');
final response = await googleVision.image.labelDetection(
  jsonImage: JsonImage.fromPath('path/to/image.jpg'),
);
```

### CLI

```bash
# Install via Homebrew
brew tap cdavis-code/google-vision
brew install vision

# Run landmark detection
vision detect --image-file photo.jpg --features LANDMARK_DETECTION
```

### Flutter

```dart
GoogleVisionFlutter(
  apiKey: 'YOUR_API_KEY',
  imagePath: 'assets/photo.jpg',
  features: [FeatureType.labelDetection],
)
```

## Authentication

The core library supports three auth strategies:

| Method | Use Case |
|--------|----------|
| `withApiKey(key)` | Quick start, development |
| `withJwt(credentialsJson)` | Service accounts, production |
| `withGenerator(generator)` | Custom token refresh logic |

## Workspace Commands

This project uses [Melos](https://melos.invertase.dev/) for monorepo management.

| Action | Command |
|--------|---------|
| Get dependencies | `melos run dep` |
| Analyze | `melos run analyze` |
| Format | `melos run format` |
| Build (codegen) | `melos run build` |
| Generate docs | `melos run doc` |
| Pana score check | `melos run pana` |
| Publish prep | `melos run prep` |



## CI / CD

GitHub Actions workflows run on every push:

- [dart.yaml](.github/workflows/dart.yaml) — Dart package analysis
- [flutter.yaml](.github/workflows/flutter.yaml) — Flutter package analysis
- [pana-dart.yaml](.github/workflows/pana-dart.yaml) — Dart pub score audit
- [pana-flutter.yaml](.github/workflows/pana-flutter.yaml) — Flutter pub score audit

## License

MIT