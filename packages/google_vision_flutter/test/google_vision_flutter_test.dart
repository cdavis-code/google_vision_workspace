import 'package:flutter_test/flutter_test.dart';
import 'package:google_vision/google_vision.dart' as gv;
import 'package:google_vision_flutter/google_vision_flutter.dart';

/// Compile-time smoke test: verifies that the Flutter [GoogleVision] wrapper
/// correctly implements the core [gv.GoogleVision] interface and that all
/// delegated members are callable without throwing.
void main() {
  // The wrapper is a singleton whose `late final _googleVision` field can only
  // be assigned once per isolate. Initialise it a single time here.
  final GoogleVision vision = GoogleVision();

  group('GoogleVision Flutter wrapper', () {
    test('satisfies the core gv.GoogleVision interface', () {
      // Compile-time check: if the wrapper drops an @override this will
      // fail to assign.
      final gv.GoogleVision core = vision;
      expect(core, isNotNull);
    });

    test('withApiKey sets credentials and returns this', () {
      final result = vision.withApiKey('test-key');
      expect(identical(result, vision), isTrue);
    });

    test('withApiKey rejects empty key', () {
      expect(() => vision.withApiKey(''), throwsArgumentError);
    });

    test('clearCredentials does not throw', () {
      vision.withApiKey('test-key');
      expect(() => vision.clearCredentials(), returnsNormally);
    });

    test('setAuthHeader does not throw after clearCredentials', () {
      vision.clearCredentials();
      expect(() => vision.setAuthHeader(), returnsNormally);
    });

    test('dio accessor returns a non-null Dio instance', () {
      expect(vision.dio, isNotNull);
    });

    test('image accessor returns a non-null object', () {
      expect(vision.image, isNotNull);
    });

    test('file accessor returns a non-null object', () {
      expect(vision.file, isNotNull);
    });

    test('tokenGenerator is null by default after clearCredentials', () {
      vision.clearCredentials();
      expect(vision.tokenGenerator, isNull);
    });
  });
}
