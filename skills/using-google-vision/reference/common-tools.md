# MCP Tool Patterns for Google Vision

## Quick start: @Tool wrapper pattern

For creating MCP tools using `easy_api_annotations`:

```dart
import 'dart:convert';
import 'package:easy_api_annotations/easy_api_annotations.dart';
import 'package:google_vision/google_vision.dart';

class VisionTools {
  static GoogleVision? _vision;

  static Future<void> init(String credentialsPath) async {
    final credentials = File(credentialsPath).readAsStringSync();
    _vision = await GoogleVision().withJwt(credentials);
  }

  static GoogleVision _require() {
    if (_vision == null) throw StateError('Call init() first');
    return _vision!;
  }
  
  static JsonImage _resolveImage(String? imageUrl, String? imageBase64) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return JsonImage(imageUri: imageUrl);
    }
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      return JsonImage.fromBuffer(base64Decode(imageBase64).buffer);
    }
    throw ArgumentError('Either imageUrl or imageBase64 required');
  }
```

## Pattern: Batch detection tool (all features in one)

This is the most efficient pattern - one tool handles all 12 feature types:

```dart
@Tool(
  name: 'vision_detect',
  description: 'Run Vision API annotation detection on an image. Supports multiple feature types simultaneously.',
)
Future<String> detect({
  @Parameter(title: 'Image URL', example: 'https://storage.googleapis.com/gweb-uniblog-publish-prod/images/Google_Logo.width-117.png')
  String? imageUrl,
  @Parameter(title: 'Image Base64')
  String? imageBase64,
  @Parameter(
    title: 'Features',
    description: 'Comma-separated: LABEL_DETECTION, FACE_DETECTION, TEXT_DETECTION, LANDMARK_DETECTION, LOGO_DETECTION, OBJECT_LOCALIZATION, SAFE_SEARCH_DETECTION, DOCUMENT_TEXT_DETECTION, IMAGE_PROPERTIES, CROP_HINTS, WEB_DETECTION, PRODUCT_SEARCH',
    example: 'LABEL_DETECTION,SAFE_SEARCH_DETECTION',
  )
  required String features,
  @Parameter(title: 'Max Results', example: 10)
  int? maxResults,
}) async {
  final vision = _require();
  final image = _resolveImage(imageUrl, imageBase64);

  final featuresList = features.split(',').map((f) => Feature(
    type: AnnotationType.values.firstWhere((a) => a.type == f),
    maxResults: maxResults ?? 10,
  )).toList();

  final response = await vision.image.annotate(
    requests: [
      AnnotateImageRequest(
        jsonImage: image,
        features: featuresList,
      ),
    ],
  );

  return response.responses.map((r) => _serialize(r)).join('\n');
}
```

## Pattern: Individual detection tools

For simpler tools that do one thing well:

```dart
@Tool(
  name: 'vision_label',
  description: 'Detect general labels in an image. Returns objects, locations, activities.',
)
Future<String> label({
  @Parameter(title: 'Image URL', example: 'https://storage.googleapis.com/gweb-uniblog-publish-prod/images/Google_Logo.width-117.png')
  required String imageUrl,
  @Parameter(title: 'Max Results', example: 10)
  int? maxResults,
}) async {
  final vision = _require();
  final labels = await vision.image.labelDetection(
    JsonImage(imageUri: imageUrl),
    maxResults: maxResults ?? 10,
  );

  return jsonEncode({
    'labels': labels.map((e) => {
      'description': e.description,
      'score': e.score,
      'mid': e.mid,
      'boundingPoly': e.boundingPoly?.toJson(),
    }).toList(),
  });
}
```

## Pattern: Safe Search tool

```dart
@Tool(
  name: 'vision_safe_search',
  description: 'Analyze safe search likelihoods: adult, spoof, medical, violence, racy content',
)
Future<String> safeSearch({
  @Parameter(title: 'Image URL', example: 'https://picsum.photos/400/300')
  required String imageUrl,
}) async {
  final vision = _require();
  final result = await vision.image.safeSearchDetection(
    JsonImage(imageUri: imageUrl),
  );

  return jsonEncode({
    'adult': result?.adult,         // VERY_UNLIKELY, UNLIKELY, POSSIBLE, LIKELY, VERY_LIKELY
    'spoof': result?.spoof,
    'medical': result?.medical,
    'violence': result?.violence,
    'racy': result?.racy,
  });
}
```

## Pattern: Face Detection tool

```dart
@Tool(
  name: 'vision_face',
  description: 'Detect faces with emotions, landmarks, and attributes',
)
Future<String> face({
  @Parameter(title: 'Image URL')
  required String imageUrl,
  @Parameter(title: 'Max Results')
  int? maxResults,
}) async {
  final vision = _require();
  final faces = await vision.image.faceDetection(
    JsonImage(imageUri: imageUrl),
    maxResults: maxResults ?? 10,
  );

  return jsonEncode(faces.map((f) => {
    'boundingPoly': f.boundingPoly?.toJson(),
    'joyLikelihood': f.joyLikelihood,
    'sorrowLikelihood': f.sorrowLikelihood,
    'angerLikelihood': f.angerLikelihood,
    'surpriseLikelihood': f.surpriseLikelihood,
    'underExposedLikelihood': f.underExposedLikelihood,
    'blurredLikelihood': f.blurredLikelihood,
    'headwearLikelihood': f.headwearLikelihood,
    'landmarks': f.landmarks.map((l) => {
      'type': l.type,
      'position': {'x': l.position?.x, 'y': l.position?.y, 'z': l.position?.z},
    }).toList(),
  }).toList());
}
```

## Pattern: Landmark Detection tool

```dart
@Tool(
  name: 'vision_landmark',
  description: 'Detect famous landmarks, returns name, confidence, and GPS location',
)
Future<String> landmark({
  @Parameter(title: 'Image URL')
  required String imageUrl,
  @Parameter(title: 'Max Results')
  int? maxResults,
}) async {
  final vision = _require();
  final landmarks = await vision.image.landmarkDetection(
    JsonImage(imageUri: imageUrl),
    maxResults: maxResults ?? 10,
  );

  return jsonEncode(landmarks.map((l) => {
    'description': l.description,
    'score': l.score,
    'mid': l.mid,
    'boundingPoly': l.boundingPoly?.toJson(),
    'locations': l.locationInfo?.map((loc) => {
      'latitude': loc.latLng?.latitude,
      'longitude': loc.latLng?.longitude,
    }).toList(),
  }).toList());
}
```

## Pattern: OCR Document Text Detection

```dart
@Tool(
  name: 'vision_ocr',
  description: 'Full document OCR detection with page/block/word structure',
)
Future<String> ocr({
  @Parameter(title: 'Image URL')
  required String imageUrl,
  @Parameter(
    title: 'Language Hints',
    description: 'BCP-47 language codes comma-separated (e.g., en,es,fr)',
  )
  List<String>? languageHints,
}) async {
  final vision = _require();
  final result = await vision.image.documentTextDetection(
    JsonImage(imageUri: imageUrl),
    imageContext: languageHints != null
      ? ImageContext(languageHints: languageHints)
      : null,
  );

  return jsonEncode({
    'text': result?.text,  // Full OCR text string
    'pages': result?.pages.map((page) => {
      'blocks': page.blocks.map((block) => {
        'paragraphs': block.paragraphs.map((paragraph) => {
          'words': paragraph.words.map((word) => {
            'text': word.symbols.map((s) => s.text).join(),
            'confidence': word.confidence,
          }).toList(),
        }).toList(),
      }).toList(),
    }).toList(),
  });
}
```

## Pattern: Image Properties (Color Analysis)

```dart
@Tool(
  name: 'vision_colors',
  description: 'Get dominant colors and color properties of an image',
)
Future<String> imageProperties({
  @Parameter(title: 'Image URL')
  required String imageUrl,
}) async {
  final vision = _require();
  final result = await vision.image.imageProperties(
    JsonImage(imageUri: imageUrl),
  );

  return jsonEncode({
    'dominantColors': result?.dominantColors.colors.map((c) => {
      'color': {'red': c.color?.red, 'green': c.color?.green, 'blue': c.color?.blue},
      'score': c.score,
      'pixelFraction': c.pixelFraction,
    }).toList(),
  });
}
```

## Pattern: Web Detection (Similar Images)

```dart
@Tool(
  name: 'vision_web',
  description: 'Detect web references to an image - matching pages, visually similar images',
)
Future<String> webDetection({
  @Parameter(title: 'Image URL')
  required String imageUrl,
}) async {
  final vision = _require();
  final result = await vision.image.webDetection(
    JsonImage(imageUri: imageUrl),
  );

  return jsonEncode({
    'webEntities': result?.webEntities.map((e) => {
      'entityId': e.entityId,
      'description': e.description,
      'score': e.score,
    }).toList(),
    'fullMatchingImages': result?.fullMatchingImages?.map((i) => i.url).toList(),
    'partialMatchingImages': result?.partialMatchingImages?.map((i) => i.url).toList(),
    'pagesWithMatchingImages': result?.pagesWithMatchingImages?.map((p) => {
      'url': p.url,
      'pageTitle': p.pageTitle,
    }).toList(),
    'visuallySimilarImages': result?.visuallySimilarImages?.map((i) => i.url).toList(),
    'bestGuessLabels': result?.bestGuessLabels.map((l) => {
      'label': l.label,
      'languageCode': l.languageCode,
    }).toList(),
  });
}
```

## Pattern: File/PDF Detection

For multi-page documents (PDF, TIFF, GIF):

```dart
@Tool(
  name: 'vision_file_detect',
  description: 'Run detection on a multi-page file (PDF, TIFF, GIF) from GCS',
)
Future<String> fileDetect({
  @Parameter(
    title: 'GCS URI',
    description: 'Google Cloud Storage URI (gs://bucket-name/file.pdf)',
  )
  required String gcsUri,
  @Parameter(
    title: 'MIME Type',
    description: 'application/pdf, image/tiff, or image/gif',
  )
  required String mimeType,
  @Parameter(
    title: 'Pages',
    description: 'Page numbers to process (1-indexed), -1 for all pages',
    example: '-1',
  )
  List<int>? pages,
  @Parameter(
    title: 'Features',
    description: 'Comma-separated annotation types',
  )
  required String features,
  @Parameter(title: 'Max Results')
  int? maxResults,
}) async {
  final vision = _require();
  
  final inputConfig = InputConfig()
    ..gcsSource = GcsSource()..gcsSource?.uri = gcsUri
    ..mimeType = mimeType;

  final featuresList = features.split(',').map((f) => Feature(
    type: AnnotationType.values.firstWhere((a) => a.type == f),
    maxResults: maxResults ?? 10,
  )).toList();

  final response = await vision.file.annotate(
    requests: [
      AnnotateFileRequest(
        inputConfig: inputConfig,
        features: featuresList,
        pages: pages,
      ),
    ],
  );

  return jsonEncode(response.responses.map((r) => {
    'totalPages': r.totalPages,
    'pageResponses': r.responses?.map((pr) => _serialize(pr)).toList(),
    'error': r.error?.toJson(),
  }).toList());
}
```
