---
name: using-google-vision
description: Use when integrating Google Cloud Vision API in Dart/Flutter applications for image analysis, object/face/landmark/logo/label detection, OCR text extraction, safe search content moderation, or document processing from images and files (PDF/TIFF/GIF)
---

# Using Google Vision

## Overview

`google_vision` is a Dart/Flutter client for Google Cloud Vision API v1. Supports image and file annotation with 12 feature types including labeling, face detection, OCR, landmark detection, and safe search analysis.

### Auth methods

Three options, pick one:

| Method | When to use |
|--------|-------------|
| API key | Simple projects, development |
| JWT/Service account | Production, full features |
| Custom token generator | Dynamic token refresh |

```dart
// Initialize once per app session
final vision = GoogleVision().withApiKey('YOUR_API_KEY');
// or
await GoogleVision().withJwt(credentialsJson);
```

## Quick start

### Detect on images

```dart
// Detect labels from URL
final labels = await vision.image.labelDetection(
  JsonImage(imageUri: 'https://example.com/photo.jpg'),
  maxResults: 5,
);
// labels: List<EntityAnnotation> with description, score, boundingPoly

// Detect faces from file bytes
final bytes = File('face.jpg').readAsBytesSync().buffer;
final faces = await vision.image.faceDetection(JsonImage.fromBuffer(bytes));
```

### Detect on files (PDF, TIFF, GIF)

```dart
final responses = await vision.file.documentTextDetection(
  InputConfig.fromBuffer(pdfBytes.buffer, 'application/pdf'),
  pages: [0, 1],  // process first 2 pages (0-indexed)
);
// Returns List<AnnotateFileResponse>
```

## Input sources

| Source | Image API | File API |
|--------|-----------|----------|
| URL | `JsonImage(imageUri: url)` | `InputConfig.fromGsUri('gs://bucket/file.pdf')` |
| File bytes | `JsonImage.fromBuffer(buffer)` | `InputConfig.fromBuffer(buffer, mimeType)` |
| Base64 | `JsonImage.fromBuffer(base64Decode(s).buffer)` | — |
| GCS URI | `JsonImage.fromGsUri('gs://bucket/file.jpg')` | `InputConfig.fromGsUri('gs://bucket/file.pdf')` |

## Feature types

Available via `AnnotationType` enum. See [reference/features.md](reference/features.md) for the complete list and return types.

```dart
Feature(type: AnnotationType.labelDetection, maxResults: 10)
```

## Common patterns

### Batch detection (multiple features, one request)

For multiple feature types on a single image in one API call:

```dart
final response = await vision.image.annotate(
  requests: [
    AnnotateImageRequest(
      jsonImage: JsonImage(imageUri: imageUrl),
      features: [
        Feature(type: AnnotationType.labelDetection),
        Feature(type: AnnotationType.faceDetection),
        Feature(type: AnnotationType.safeSearchDetection),
      ],
    ),
  ],
);

final result = response.responses.first;
result.labelAnnotations     // List<EntityAnnotation>
result.faceAnnotations      // List<FaceAnnotation>
result.safeSearchAnnotation // SafeSearchAnnotation?
```

### Working with results

Labels, landmarks, and logos all return `List<EntityAnnotation>`:

```dart
for (final entity in labels) {
  entity.description    // String label (e.g., "Tower", "Architecture")
  entity.score          // Confidence 0-1 (.score = 0.92)
  entity.boundingPoly   // Vertices for location in image
  entity.mid           // Knowledge Graph ID (e.g., "/m/0f8l9c")
}
```

Face detection includes emotions and facial landmarks:

```dart
for (final face in faces) {
  face.joyLikelihood    // Likelihood enum: very_likely, likely, possible, unlikely, very_unlikely
  face.sorrowLikelihood
  face.angerLikelihood
  face.surpriseLikelihood
  face.detectionConfidence  // Confidence 0-1
}

// Access facial landmarks (eyes, nose, mouth positions)
for (final landmark in face.landmarks) {
  landmark.type       // e.g., left_eye, right_eye, nose_tip
  landmark.position?.x, landmark.position?.y
}
```

OCR returns full document structure:

```dart
final fullText = await vision.image.documentTextDetection(
  JsonImage.fromBuffer(imageBuffer.buffer),
);

fullText?.text        // Full extracted text string
fullText?.pages       // List<Page> with blocks, paragraphs, words, symbols
```

Safe search returns content likelihood values:

```dart
final safeSearch = await vision.image.safeSearchDetection(image);
safeSearch?.adult     // Likelihood enum
safeSearch?.violence
safeSearch?.racy
safeSearch?.spoof     // Fake/manipulated content
safeSearch?.medical
```

Web detection finds image references across the web:

```dart
final web = await vision.image.webDetection(image);
web?.webEntities               // Related concepts
web?.fullMatchingImages        // Exact image matches
web?.partialMatchingImages     // Partial matches  
web?.pagesWithMatchingImages   // Pages containing this image
web?.visuallySimilarImages     // Similar images
web?.bestGuessLabels           // Best guess labels for the image
```

### Image context

Control detection behavior per request:

```dart
// OCR with language hints
final text = await vision.image.textDetection(
  image,
  imageContext: ImageContext(languageHints: ['en', 'es']),
);

// Crop hints with aspect ratios
final hints = await vision.image.cropHints(
  image,
  imageContext: ImageContext(
    cropHintsParams: CropHintsParams(aspectRatios: [1.0, 16/9, 4/3]),
  ),
);
```

### Error handling

Check error field on response for API errors:

```dart
final result = response.responses.first;
if (result.error != null) {
  // result.error has code, message, details (protobuf status)
  log.info('API error: ${result.error!.message}');
}
```

## Dependencies

```yaml
dependencies:
  google_vision: ^2.0.0+10
```

### For MCP server @Tool annotations

```yaml
dependencies:
  google_vision: ^2.0.0+10
  easy_api_annotations: ^0.6.0
dev_dependencies:
  easy_api_generator: ^0.6.0
  build_runner: ^2.10.1
```

## Creating MCP @Tools

See [reference/tools.md](reference/tools.md) for complete `@Tool` patterns including batch detection tools and individual detection methods.
