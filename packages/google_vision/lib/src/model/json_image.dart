import 'dart:convert';
import 'dart:typed_data';

/// A class that holds the details of an image that can be converted to/from JSON.
class JsonImage {
  /// Maximum image size supported by the Google Vision API (20 MB).
  static const int maxImageBytes = 20 * 1024 * 1024;

  final String? imageUri;

  final ByteBuffer? byteBuffer;

  JsonImage({this.imageUri, this.byteBuffer}) {
    if (imageUri == null && byteBuffer == null) {
      throw Exception('Invalid JsonImage');
    }
  }

  factory JsonImage.fromBuffer(ByteBuffer buffer) {
    if (buffer.lengthInBytes > maxImageBytes) {
      throw ArgumentError(
        'Image size (${buffer.lengthInBytes} bytes) exceeds '
        'the maximum allowed size of $maxImageBytes bytes.',
      );
    }
    return JsonImage(byteBuffer: buffer);
  }

  factory JsonImage.fromGsUri(String gsUri) => JsonImage(imageUri: gsUri);

  factory JsonImage.fromJson(Map<String, dynamic> json) => JsonImage(
    byteBuffer: json.containsKey('content')
        ? base64.decode(json['content']).buffer
        : null,
    imageUri:
        json.containsKey('source') && json['source'].containsKey('imageUri')
        ? json['source']['imageUri']
        : null,
  );

  Map<String, dynamic> toJson() => byteBuffer != null
      ? {'content': base64Encode(byteBuffer!.asUint8List())}
      : {
          'source': {'imageUri': imageUri},
        };

  @override
  String toString() => json.encode(toJson());
}
