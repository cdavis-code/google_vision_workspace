import 'package:google_vision/google_vision.dart';
import 'package:universal_io/io.dart';

void main() async {
  final googleVision = await GoogleVision().withJwt(
    File('service_credentials.json').readAsStringSync(),
  );

  final inputImage = await File('sample_image/allswell.pdf').readAsBytes();

  print('checking...');

  final fullTextAnnotation = await googleVision.image.documentTextDetection(
    JsonImage.fromBuffer(inputImage.buffer),
  );

  if (fullTextAnnotation == null) {
    print('no text detected');
    return;
  }

  // Convert the document hierarchy directly to markdown.
  final markdown = fullTextAnnotation.toMarkdown();

  print(markdown);

  print('done.');
}
