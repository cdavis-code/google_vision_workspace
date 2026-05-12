# Google Vision Flutter Widget

<center><img src="https://github.com/cdavis-code/google_vision_workspace/blob/main/packages/google_vision_flutter/extra/google_vision_flutter.png?raw=true&amp;v1" width="320"></center>
<br/>

[![pub package](https://img.shields.io/pub/v/google_vision_flutter.svg)](https://pub.dartlang.org/packages/google_vision_flutter)
![SDK version](https://badgen.net/pub/sdk-version/google_vision_flutter?style=for-the-badge)
![Supported platforms](https://badgen.net/pub/flutter-platform/google_vision_flutter?style=for-the-badge)
![Supported SDKs](https://badgen.net/pub/dart-platform/google_vision_flutter?style=for-the-badge)

A Flutter widget package that integrates Google Cloud Vision image labeling, face, logo, landmark, text detection, and more into your Flutter applications.

[![popularity](https://img.shields.io/pub/popularity/google_vision_flutter?style=for-the-badge&logo=dart)](https://pub.dev/packages/google_vision_flutter/score)
[![Pub Score](https://img.shields.io/pub/points/google_vision_flutter?logo=dart&logoColor=00b9fc&style=for-the-badge)](https://pub.dev/packages/google_vision_flutter/score)
[![likes](https://img.shields.io/pub/likes/google_vision_flutter?style=for-the-badge&logo=dart)](https://pub.dev/packages/google_vision_flutter/score)

## Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
  - [Image Detection](#image-detection-googlevisionimagebuilder)
  - [File Detection](#file-detection-googlevisionfilebuilder)
- [Configuration](#configuration)
  - [GoogleVision Initialization](#googlevision-initialization)
  - [Builder Parameters](#builder-parameters)
- [Examples](#examples)
- [API Reference](#api-reference)
- [Contributors](#contributors)
- [Contributing](#contributing)
- [License](#license)

---

## Quick Start

### 1. Add dependency

```yaml
dependencies:
  google_vision_flutter: ^2.0.0+12
```

### 2. Authenticate

Obtain credentials via an API key or a service account JSON file:

[Authenticating to the Cloud Vision API](https://cloud.google.com/vision/product-search/docs/auth) requires an API key or a JSON file with the JWT token information. The JWT token can be obtained by [creating a service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#creating_a_service_account) in the Google API console.

```dart
// Using a service account JSON file from your Flutter assets
final googleVision = GoogleVision().withAsset('assets/service_credentials.json');
```

### 3. Use the builder widget

```dart
import 'package:flutter/material.dart';
import 'package:google_vision_flutter/google_vision_flutter.dart';

GoogleVisionImageBuilder.labelDetection(
  googleVision: googleVision,
  imageProvider: Image.asset('assets/photo.jpg').image,
  builder: (context, List<EntityAnnotation>? annotations) {
    return Column(
      children: annotations!
          .map((entity) => Text(
              '${(entity.score! * 100).toStringAsFixed(2)}% - ${entity.description}'))
          .toList(),
    );
  },
);
```

See the [example app](https://github.com/cdavis-code/google_vision_workspace/tree/main/packages/google_vision_flutter/example) for the complete working project.

---

## Features

### Image Detection (GoogleVisionImageBuilder)

Analyze images via the Cloud Vision API using declarative Flutter widgets:

| Feature | Builder Factory | Annotation Type |
|---------|----------------|-----------------|
| Label Detection | `GoogleVisionImageBuilder.labelDetection()` | `EntityAnnotation` |
| Face Detection | `GoogleVisionImageBuilder.faceDetection()` | `FaceAnnotation` |
| Landmark Detection | `GoogleVisionImageBuilder.landmarkDetection()` | `EntityAnnotation` |
| Logo Detection | `GoogleVisionImageBuilder.logoDetection()` | `EntityAnnotation` |
| Text Detection | `GoogleVisionImageBuilder.textDetection()` | `EntityAnnotation` |
| Document Text Detection | `GoogleVisionImageBuilder.documentTextDetection()` | `FullTextAnnotation` |
| Object Localization | `GoogleVisionImageBuilder.objectLocalization()` | `LocalizedObjectAnnotation` |
| Safe Search Detection | `GoogleVisionImageBuilder.safeSearchDetection()` | `SafeSearchAnnotation` |
| Image Properties | `GoogleVisionImageBuilder.imageProperties()` | `ImagePropertiesAnnotation` |
| Crop Hints | `GoogleVisionImageBuilder.cropHints()` | `CropHintsAnnotation` |
| Web Detection | `GoogleVisionImageBuilder.webDetection()` | `WebDetection` |
| Product Search | `GoogleVisionImageBuilder.productSearch()` | `ProductSearchResults` |

### File Detection (GoogleVisionFileBuilder)

Analyze PDF / TIFF files using the Cloud Vision API:

| Feature | Builder Factory |
|---------|----------------|
| Label Detection | `GoogleVisionFileBuilder.labelDetection()` |
| Face Detection | `GoogleVisionFileBuilder.faceDetection()` |
| Landmark Detection | `GoogleVisionFileBuilder.landmarkDetection()` |
| Logo Detection | `GoogleVisionFileBuilder.logoDetection()` |
| Text Detection | `GoogleVisionFileBuilder.textDetection()` |
| Document Text Detection | `GoogleVisionFileBuilder.documentTextDetection()` |
| Object Localization | `GoogleVisionFileBuilder.objectLocalization()` |
| Safe Search Detection | `GoogleVisionFileBuilder.safeSearchDetection()` |
| Image Properties | `GoogleVisionFileBuilder.imageProperties()` |
| Crop Hints | `GoogleVisionFileBuilder.cropHints()` |
| Web Detection | `GoogleVisionFileBuilder.webDetection()` |
| Product Search | `GoogleVisionFileBuilder.productSearch()` |

---

## Configuration

### GoogleVision Initialization

| Method | Description |
|--------|-------------|
| `GoogleVision().withAsset(path)` | Load JWT credentials from a Flutter asset |
| `GoogleVision().withApiKey(key)` | Authenticate using an API key |
| `GoogleVision(LogLevel.all).withAsset(path)` | Enable verbose logging |

### Builder Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `googleVision` | `FutureOr<GoogleVision>` | required | The Google Vision instance |
| `imageProvider` / `inputConfig` | varies | required | The image to analyze or file config |
| `builder` | `Widget Function(...)` | required | Widget builder for the results |
| `maxResults` | `int` | `10` | Maximum results per feature |
| `onError` | `Widget Function(Object)?` | `null` | Custom error widget |
| `onLoading` | `Widget Function()?` | `null` | Custom loading widget |
| `parent` | `String?` | `null` | Target project/location (e.g. `projects/my-project/locations/us`) |

---

## Examples

<center><img src="https://github.com/cdavis-code/google_vision_workspace/blob/main/packages/google_vision_flutter/extra/Screenshot.png?raw=true&amp;v1" width="320"></center>

Explore the [example app](https://github.com/cdavis-code/google_vision_workspace/tree/main/packages/google_vision_flutter/example) for full usage of all detection features.

---

## API Reference

This package re-exports the [google_vision](https://pub.dev/packages/google_vision) Dart package (hiding `Color`, `GoogleVision`, `JsonImage`, and `InputConfig` which have Flutter-specific replacements).

For detailed API documentation, see:
- [Google Vision Dart package](https://pub.dev/packages/google_vision)
- [Example app source](https://github.com/cdavis-code/google_vision_workspace/tree/main/packages/google_vision_flutter/example/lib)

---

## Contributors

- [hieupm2096](https://github.com/hieupm2096)

## Contributing

Any help from the open-source community is always welcome and needed:
- Found an issue? Please fill a bug report with details.
- Need a feature? Open a feature request with use cases.
- Are you using and liking the project? Promote the project or make a donation.
- Are you a developer? Fix a bug and send a pull request.

## License

[MIT](LICENSE)