# MCP @Tool Patterns for Google Vision

## Recommended: Multi-feature tool

One tool that handles all feature types, accepting features as comma-separated list:

```dart
@Tool(
  name: 'vision_detect',
  description: 'Run one or more annotation detections on an image (label, face, text, landmark, logo, safe search, etc).',
  annotations: ToolAnnotations(
    title: 'Vision Detect',
    readOnlyHint: true,
  ),
)
Future<String> detect({
  @Parameter(title: 'Image URL', example: 'https://example.com/photo.jpg')
  String? imageUrl,
  @Parameter(title: 'Image Base64', description: 'Base64-encoded image data')
  String? imageBase64,
  @Parameter(
    title: 'Features',
    description: 'Comma-separated: LABEL_DETECTION, FACE_DETECTION, TEXT_DETECTION, LANDMARK_DETECTION, LOGO_DETECTION, OBJECT_LOCALIZATION, SAFE_SEARCH_DETECTION, DOCUMENT_TEXT_DETECTION, IMAGE_PROPERTIES, CROP_HINTS, WEB_DETECTION',
    example: 'LABEL_DETECTION,SAFE_SEARCH_DETECTION',
  )
  required String features,
  @Parameter(title: 'Max Results', example: 10)
  int? maxResults,
}) async {
  final vision = GoogleVision().withApiKey('API_KEY');
  
  JsonImage image;
  if (imageBase64 != null) {
    image = JsonImage.fromBuffer(base64Decode(imageBase64).buffer);
  } else if (imageUrl != null) {
    image = JsonImage(imageUri: imageUrl);
  } else {
    throw ArgumentError('imageUrl or imageBase64 required');
  }

  final featureList = features.split(',').map((f) => Feature(
    maxResults: maxResults ?? 10,
    type: AnnotationType.values.firstWhere((a) => a.type == f.trim()),
  )).toList();

  final response = await vision.image.annotate(
    requests: [
      AnnotateImageRequest(jsonImage: image, features: featureList),
    ],
  );

  if (response.responses.isEmpty) {
    return jsonEncode({'error': 'No response from API'});
  }

  final r = response.responses.first;
  if (r.error != null) {
    return jsonEncode({'error': {'code': r.error!.code, 'message': r.error!.message}});
  }

  return jsonEncode({
    'labels': r.labelAnnotations.map((e) => e.toJson()).toList(),
    'faces': r.faceAnnotations.map((e) => e.toJson()).toList(),
    'landmarks': r.landmarkAnnotations.map((e) => e.toJson()).toList(),
    'logos': r.logoAnnotations.map((e) => e.toJson()).toList(),
    'safeSearch': r.safeSearchAnnotation?.toJson(),
    'fullText': r.fullTextAnnotation?.toJson(),
    'objects': r.localizedObjectAnnotations.map((e) => e.toJson()).toList(),
    'web': r.webDetection?.toJson(),
    'imageProperties': r.imagePropertiesAnnotation?.toJson(),
    'cropHints': r.cropHintsAnnotation?.toJson(),
  });
}
```

## Individual detection tools

For finer control, expose individual feature types:

```dart
@Tool(
  name: 'vision_label',
  description: 'Detect labels (objects, activities, concepts) in an image',
)
Future<String> detectLabels({
  @Parameter(title: 'Image URL', example: 'https://example.com/photo.jpg')
  required String imageUrl,
  @Parameter(title: 'Max Results', example: 10)
  int? maxResults,
}) async {
  final vision = GoogleVision().withApiKey('API_KEY');
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

```dart
@Tool(
  name: 'vision_face',
  description: 'Detect faces with emotions (joy, sorrow, anger, surprise) and facial landmarks',
)
Future<String> detectFaces({
  @Parameter(title: 'Image URL')
  required String imageUrl,
  @Parameter(title: 'Max Results', example: 10)
  int? maxResults,
}) async {
  final vision = GoogleVision().withApiKey('API_KEY');
  final faces = await vision.image.faceDetection(
    JsonImage(imageUri: imageUrl),
    maxResults: maxResults ?? 10,
  );
  return jsonEncode({
    'faces': faces.map((e) => {
      'joyLikelihood': e.joyLikelihood,
      'sorrowLikelihood': e.sorrowLikelihood,
      'angerLikelihood': e.angerLikelihood,
      'surpriseLikelihood': e.surpriseLikelihood,
      'detectionConfidence': e.detectionConfidence,
      'landmarks': e.landmarks.map((l) => {'type': l.type, 'position': l.position?.toJson()}).toList(),
      'boundingPoly': e.boundingPoly?.toJson(),
    }).toList(),
  });
}
```

```dart
@Tool(
  name: 'vision_safe_search',
  description: 'Detect explicit content in an image. Returns likelihood for adult, violence, racy, spoof, and medical content.',
)
Future<String> safeSearch({
  @Parameter(title: 'Image URL')
  required String imageUrl,
}) async {
  final vision = GoogleVision().withApiKey('API_KEY');
  final result = await vision.image.safeSearchDetection(JsonImage(imageUri: imageUrl));
  return jsonEncode(result?.toJson());
}
```

```dart
@Tool(
  name: 'vision_text',
  description: 'Detect and extract text from an image (OCR)',
)
Future<String> detectText({
  @Parameter(title: 'Image URL')
  required String imageUrl,
  @Parameter(
    title: 'Language Hints',
    description: 'Comma-separated BCP-47 language codes (e.g., en,zh,fr)',
  )
  List<String>? languageHints,
}) async {
  final vision = GoogleVision().withApiKey('API_KEY');
  final text = await vision.image.textDetection(
    JsonImage(imageUri: imageUrl),
    maxResults: 10,
    imageContext: languageHints != null
      ? ImageContext(languageHints: languageHints)
      : null,
  );
  return jsonEncode({
    'text': text.map((e) => e.description).join('\n'),
    'annotations': text.map((e) => e.toJson()).toList(),
  });
}
```

```dart
@Tool(
  name: 'vision_landmark',
  description: 'Detect famous landmarks with geographic location data (latitude/longitude)',
)
Future<String> detectLandmarks({
  @Parameter(title: 'Image URL')
  required String imageUrl,
  @Parameter(title: 'Max Results')
  int? maxResults,
}) async {
  final vision = GoogleVision().withApiKey('API_KEY');
  final landmarks = await vision.image.landmarkDetection(
    JsonImage(imageUri: imageUrl),
    maxResults: maxResults ?? 10,
  );
  return jsonEncode({
    'landmarks': landmarks.map((e) => {
      'description': e.description,
      'score': e.score,
      'mid': e.mid,
      'locations': e.locationInfo?.map((l) => {
        'latitude': l.latLng?.latitude,
        'longitude': l.latLng?.longitude,
      }).toList(),
    }).toList(),
  });
}
```

## File detection tool

For multi-page files (PDF, TIFF, GIF) stored in Google Cloud Storage:

```dart
@Tool(
  name: 'vision_file_detect',
  description: 'Run detection on a PDF, TIFF, or GIF file in Google Cloud Storage',
)
Future<String> fileDetect({
  @Parameter(
    title: 'GCS Uri',
    description: 'Google Cloud Storage URI (gs://bucket-name/file.pdf)',
    example: 'gs://my-bucket/document.pdf',
  )
  required String gsUri,
  @Parameter(
    title: 'Mime Type',
    description: 'File MIME type: application/pdf, image/tiff, or image/gif',
  )
  required String mimeType,
  @Parameter(
    title: 'Pages',
    description: 'Comma-separated page numbers (0-indexed). Use -1 for all pages',
  )
  String? pages,
  @Parameter(title: 'Features', example: 'DOCUMENT_TEXT_DETECTION')
  required String features,
}) async {
  final vision = GoogleVision().withApiKey('API_KEY');

  final inputConfig = InputConfig.fromGsUri(gsUri);
  inputConfig.mimeType = mimeType;

  final pagesList = pages != null && pages != '-1'
      ? pages.split(',').map(int.parse).toList()
      : null;

  final featureList = features.split(',').map((f) => Feature(
    maxResults: 10,
    type: AnnotationType.values.firstWhere((a) => a.type == f.trim()),
  )).toList();

  final response = await vision.file.annotate(
    requests: [
      AnnotateFileRequest(
        inputConfig: inputConfig,
        features: featureList,
        pages: pagesList,
      ),
    ],
  );

  return jsonEncode(response.responses.map((r) => {
    'totalPages': r.totalPages,
    'responses': r.responses?.map((p) => p.toJson()).toList(),
    'error': r.error?.toJson(),
  }).toList());
}

static Future<JsonImage> _resolveImage(String? imageUrl, String? imageBase64) async {
  if (imageBase64 != null && imageBase64.isNotEmpty) {
    return JsonImage.fromBuffer(base64Decode(imageBase64).buffer);
  }
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return JsonImage(imageUri: imageUrl);
  }
  throw ArgumentError('imageUrl or imageBase64 required');
}
```
