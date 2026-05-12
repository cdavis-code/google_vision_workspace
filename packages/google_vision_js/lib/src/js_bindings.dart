/// JS-interop bindings that expose a minimal `google_vision` surface to
/// JavaScript. The TypeScript wrapper layer (src/index.ts) consumes these to
/// provide a typed, Promise-based API.
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:google_vision/google_vision.dart';

@JS('globalThis')
external JSObject get _globalThis;

/// Installs the interop namespace on `globalThis.GoogleVisionJs`.
/// Called once from the dart2js `main()`.
void install() {
  final ns = JSObject();
  ns.setProperty('create'.toJS, _createVisionHandle.toJS);
  ns.setProperty('version'.toJS, '1.0.0'.toJS);
  _globalThis.setProperty('GoogleVisionJs'.toJS, ns);
}

/// Creates a new Vision handle (opaque JS object).
///
/// Usage: `const handle = GoogleVisionJs.create();`
///
/// Each method on the handle is a closure that captures the underlying
/// [GoogleVision] Dart instance, avoiding @JSExport() tree-shaking and
/// dart2js name-mangling problems.
JSObject _createVisionHandle() {
  final vision = GoogleVision();

  final handle = JSObject();

  // -- Auth methods ----------------------------------------------------------

  handle.setProperty(
    'withApiKey'.toJS,
    ((JSString apiKey) {
      vision.withApiKey(apiKey.toDart);
      return handle;
    }).toJS,
  );

  handle.setProperty(
    'withJwt'.toJS,
    ((JSString credentialsJson, JSString? scope) {
      final future = () async {
        await vision.withJwt(
          credentialsJson.toDart,
          scope?.toDart ?? 'https://www.googleapis.com/auth/cloud-platform',
        );
        return handle;
      }();
      return future.toJS;
    }).toJS,
  );

  // -- Image detection methods -----------------------------------------------

  handle.setProperty(
    'imageLabelDetection'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final results = await vision.image.labelDetection(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(results.map((e) => e.toJson()).toList());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'imageTextDetection'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final results = await vision.image.textDetection(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(results.map((e) => e.toJson()).toList());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'imageFaceDetection'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final results = await vision.image.faceDetection(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(results.map((e) => e.toJson()).toList());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'imageSafeSearchDetection'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final result = await vision.image.safeSearchDetection(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(result?.toJson());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'imageCropHints'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final result = await vision.image.cropHints(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(result?.toJson());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'imageDocumentTextDetection'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final result = await vision.image.documentTextDetection(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(result?.toJson());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'imageProperties'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final result = await vision.image.imageProperties(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(result?.toJson());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'imageLandmarkDetection'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final results = await vision.image.landmarkDetection(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(results.map((e) => e.toJson()).toList());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'imageLogoDetection'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final results = await vision.image.logoDetection(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(results.map((e) => e.toJson()).toList());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'imageObjectLocalization'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final results = await vision.image.objectLocalization(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(results.map((e) => e.toJson()).toList());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'imageWebDetection'.toJS,
    ((JSAny? imageSource, JSNumber? maxResults) {
      final future = () async {
        final jsonImage = _jsToJsonImage(imageSource);
        final result = await vision.image.webDetection(
          jsonImage,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(result?.toJson());
      }();
      return future.toJS;
    }).toJS,
  );

  // -- File detection methods ------------------------------------------------

  handle.setProperty(
    'fileLabelDetection'.toJS,
    ((JSString gcsUri, JSNumber? maxResults) {
      final future = () async {
        final inputConfig = InputConfig.fromGsUri(gcsUri.toDart);
        final results = await vision.file.labelDetection(
          inputConfig,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(results.map((e) => e.toJson()).toList());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'fileTextDetection'.toJS,
    ((JSString gcsUri, JSNumber? maxResults) {
      final future = () async {
        final inputConfig = InputConfig.fromGsUri(gcsUri.toDart);
        final results = await vision.file.textDetection(
          inputConfig,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(results.map((e) => e.toJson()).toList());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'fileDocumentTextDetection'.toJS,
    ((JSString gcsUri, JSNumber? maxResults) {
      final future = () async {
        final inputConfig = InputConfig.fromGsUri(gcsUri.toDart);
        final results = await vision.file.documentTextDetection(
          inputConfig,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(results.map((e) => e.toJson()).toList());
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'fileFaceDetection'.toJS,
    ((JSString gcsUri, JSNumber? maxResults) {
      final future = () async {
        final inputConfig = InputConfig.fromGsUri(gcsUri.toDart);
        final results = await vision.file.faceDetection(
          inputConfig,
          maxResults: maxResults?.toDartInt ?? 10,
        );
        return _dartToJs(results.map((e) => e.toJson()).toList());
      }();
      return future.toJS;
    }).toJS,
  );

  return handle;
}

// -------------------------------------------------------------------------
// JSON <-> JS value conversion (round-trip via JSON for fidelity)
// -------------------------------------------------------------------------

JSObject get _json => _globalThis.getProperty<JSObject>('JSON'.toJS);

/// Converts a plain Dart value (from `dart:convert` JSON) to a JS value.
JSAny? _dartToJs(Object? value) {
  if (value == null) return null;
  final encoded = jsonEncode(value);
  return _json.callMethod<JSAny?>('parse'.toJS, encoded.toJS);
}

/// Converts a JS value into a [JsonImage].
///
/// Accepts:
/// - A string (treated as an image URI)
/// - An object with `imageUri` (String) or `content` (base64 String)
JsonImage _jsToJsonImage(JSAny? source) {
  if (source == null) {
    throw ArgumentError('Image source must not be null');
  }

  // String: treat as image URI.
  if (source is JSString) {
    return JsonImage(imageUri: source.toDart);
  }

  // Object: convert via JSON round-trip and check for imageUri / content.
  final map = _jsToDartMap(source);
  if (map.containsKey('imageUri') && map['imageUri'] is String) {
    return JsonImage(imageUri: map['imageUri'] as String);
  }
  if (map.containsKey('content') && map['content'] is String) {
    return JsonImage.fromJson({'content': map['content']});
  }

  throw ArgumentError(
    'Image source must be a string URI or an object with '
    '"imageUri" or "content" (base64)',
  );
}

/// Converts a JS value into a Dart `Map<String, dynamic>` via JSON round-trip.
Map<String, dynamic> _jsToDartMap(JSAny value) {
  final stringified = _json.callMethod<JSString>('stringify'.toJS, value);
  final decoded = jsonDecode(stringified.toDart);
  if (decoded is Map<String, dynamic>) return decoded;
  throw ArgumentError('Expected object, got ${decoded.runtimeType}');
}
