# Available Feature Types

## AnnotationType enum

| Value | Method | Return type | Description |
|-------|--------|-------------|-------------|
| LABEL_DETECTION | labelDetection | List<EntityAnnotation> | Objects, locations, activities, species |
| FACE_DETECTION | faceDetection | List<FaceAnnotation> | Faces with emotions, landmarks, attributes |
| TEXT_DETECTION | textDetection | List<EntityAnnotation> | Sparse OCR (signs, captions) |
| DOCUMENT_TEXT_DETECTION | documentTextDetection | FullTextAnnotation? | Dense OCR with page/word structure |
| LANDMARK_DETECTION | landmarkDetection | List<EntityAnnotation> | Famous places and monuments |
| LOGO_DETECTION | logoDetection | List<EntityAnnotation> | Brand logos and trademarks |
| OBJECT_LOCALIZATION | objectLocalization | List<LocalizedObjectAnnotation> | Objects with bounding boxes |
| SAFE_SEARCH_DETECTION | safeSearchDetection | SafeSearchAnnotation? | Adult, violence, racy content likelihoods |
| IMAGE_PROPERTIES | imageProperties | ImagePropertiesAnnotation? | Dominant colors, color info |
| CROP_HINTS | cropHints | CropHintsAnnotation? | Suggested crop regions |
| WEB_DETECTION | webDetection | WebDetection? | Web references and visually similar images |
| PRODUCT_SEARCH | productSearch | ProductSearchResults? | Product matches |

## Likelihood values

Used by FaceAnnotation emotions and SafeSearchDetection:

```dart
enum Likelihood {
  veryUnlikely,  // Very low confidence
  unlikely,      // Low confidence  
  possible,      // Moderate confidence
  likely,        // High confidence
  veryLikely,    // Very high confidence
}
```
