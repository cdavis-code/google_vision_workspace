/// Validation utilities for Google Vision API requests
class RequestValidator {
  /// Validate maxResults parameter
  static void validateMaxResults(int maxResults, String paramName) {
    if (maxResults < 1 || maxResults > 100) {
      throw ArgumentError.value(
        maxResults,
        paramName,
        'Must be between 1 and 100',
      );
    }
  }

  /// Validate that JsonImage has either content or source
  static void validateJsonImage(dynamic jsonImage) {
    if (jsonImage == null) {
      throw ArgumentError('JsonImage cannot be null');
    }

    // Check if it has content or source (using reflection-free approach)
    final hasContent = jsonImage.content != null;
    final hasSource = jsonImage.source != null;
    final hasGcsUri = jsonImage.gcsImageUri != null;

    if (!hasContent && !hasSource && !hasGcsUri) {
      throw ArgumentError(
        'JsonImage must have either content, source, or gcsImageUri',
      );
    }
  }

  /// Validate InputConfig for file-based operations
  static void validateInputConfig(dynamic inputConfig) {
    if (inputConfig == null) {
      throw ArgumentError('InputConfig cannot be null');
    }

    if (inputConfig.gcsSource == null && inputConfig.content == null) {
      throw ArgumentError('InputConfig must have either gcsSource or content');
    }
  }

  /// Validate annotation type
  static void validateAnnotationType(dynamic annotationType) {
    if (annotationType == null) {
      throw ArgumentError('AnnotationType cannot be null');
    }
  }
}
