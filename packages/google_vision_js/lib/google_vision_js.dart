/// dart2js entry point for the google_vision_js npm package.
///
/// When this module is loaded in a JavaScript environment, `main()` installs
/// a `globalThis.GoogleVisionJs` namespace with a minimal, interop-friendly
/// surface. The rich, typed API is layered on top in TypeScript
/// (see `src/index.ts`).
library;

import 'package:google_vision_js/src/js_bindings.dart' as bindings;

void main() {
  bindings.install();
}
