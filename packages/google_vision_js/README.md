# @unngh/google-vision

![google_vision banner](https://raw.githubusercontent.com/cdavis-code/google_vision_workspace/main/packages/google_vision_js/images/banner.svg)

**Google Vision API client for Node.js and browsers** — image labeling, face detection, OCR, safe search, and more with Promise-based API and full type safety.

Built on the battle-tested [`google_vision`](https://pub.dev/packages/google_vision) Dart SDK, compiled to JavaScript via `dart2js`. Every request is parsed and validated by the same codebase that powers the official Dart package and CLI tools.

[![npm version](https://img.shields.io/npm/v/@unngh/google-vision.svg)](https://www.npmjs.com/package/@unngh/google-vision)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.4-blue.svg)](https://www.typescriptlang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Why @unngh/google-vision?

| Feature | @unngh/google-vision | @google-cloud/vision |
|---------|---------------------|----------------------|
| **Protocol Core** | Shared Dart SDK → dart2js | Node.js native |
| **Type Safety** | Full TypeScript declarations | TypeScript support |
| **Promise-based API** | ✅ Modern async/await | ✅ Promise-based |
| **Dual Entrypoints** | ✅ Separate `node` and `browser` builds | Node.js only |
| **Browser Support** | ✅ Native `fetch` + `XMLHttpRequest` | ❌ |
| **Node.js Support** | ✅ Auto-polyfills browser APIs via `xhr2` | ✅ |
| **Bundle Size** | ~150–300 KB gzipped (dart2js runtime) | ~2–5 MB (gRPC + proto) |
| **API Key Auth** | ✅ `withApiKey()` | ✅ |
| **JWT Auth** | ✅ `withJwt()` | ✅ |
| **Image API** | ✅ URL, base64, buffers | ✅ |
| **File API (GCS)** | ✅ Text + Document text detection | ✅ |
| **Shared Protocol Core** | ✅ Same logic as Dart/CLI packages | Standalone implementation |

### Key Advantages

✨ **Universal Runtime** — One package works everywhere: Node.js 18+, modern browsers (Chrome, Firefox, Safari, Edge), and all major bundlers (Vite, Webpack, Rollup).

🔒 **Zero Protocol Drift** — Feature parity guaranteed with the [google_vision](https://pub.dev/packages/google_vision) Dart package. Protocol fixes benefit all platforms simultaneously.

📦 **Minimal Dependencies** — Only one runtime dependency: `xhr2` (Node.js only, < 10 KB). No gRPC, no protobuf, no native bindings.

---

## Quick Start

### Installation

```bash
npm install @unngh/google-vision
```

### Basic Usage (Node.js / TypeScript)

```typescript
import { GoogleVision } from '@unngh/google-vision';

// Create and authenticate
const vision = await GoogleVision.create();
vision.withApiKey(process.env.GOOGLE_VISION_API_KEY!);

// Detect labels in an image
const labels = await vision.image.labelDetection('https://example.com/photo.jpg');
labels.forEach((label) => {
  console.log(`${label.description}: ${(label.score * 100).toFixed(1)}%`);
});

// OCR text detection
const texts = await vision.image.textDetection('https://example.com/document.png');
console.log('Extracted text:', texts[0]?.description);

// Safe search
const safeSearch = await vision.image.safeSearchDetection('https://example.com/photo.jpg');
console.log('Adult content:', safeSearch?.adult);

// Face detection
const faces = await vision.image.faceDetection('https://example.com/portrait.jpg');
console.log(`Found ${faces.length} face(s)`);
```

### Browser Usage

```typescript
import { GoogleVision } from '@unngh/google-vision/browser';

const vision = await GoogleVision.create();
vision.withApiKey('YOUR_API_KEY');

// Analyze images directly from the browser
const logos = await vision.image.logoDetection('https://example.com/brand.png');
console.log('Detected logos:', logos.map((l) => l.description));
```

### Choosing an Import Path

This package supports both Node.js and browser environments. Use the appropriate import for your target:

| Import Path | Environment | API Transport | Typical Use Case |
|---|---|---|---|
| `@unngh/google-vision` | **Auto-detected** | `fetch` / polyfilled `XMLHttpRequest` | Universal code, libraries |
| `@unngh/google-vision/node` | **Node.js** (explicit) | Polyfilled `XMLHttpRequest` via `xhr2` | Server-side apps, CLI tools, automation scripts |
| `@unngh/google-vision/browser` | **Browser** (explicit) | Native `fetch` | Web dashboards, browser extensions, client-side analysis |

---

## API Reference

### Creating a Client

```typescript
import { GoogleVision } from '@unngh/google-vision';

const vision = await GoogleVision.create();
```

The factory loads the dart2js runtime and returns a configured client. No arguments needed when using the `node` or `browser` entrypoints — the loader is pre-configured.

### Authentication

#### API Key (Synchronous)

```typescript
vision.withApiKey('YOUR_API_KEY');
```

Chainable — returns `this` for fluent usage.

#### JWT / Service Account (Asynchronous)

```typescript
const credentials = fs.readFileSync('./service-account.json', 'utf-8');
await vision.withJwt(credentials);
// Optional scope:
await vision.withJwt(credentials, 'https://www.googleapis.com/auth/cloud-vision');
```

### Image API (`vision.image`)

All image methods accept an image source (URL string or `{ imageUri, content }` object) and an optional `maxResults` cap.

| Method | Returns | Description |
|--------|---------|-------------|
| `labelDetection(source, maxResults?)` | `Label[]` | General object and scene labels |
| `textDetection(source, maxResults?)` | `TextAnnotation[]` | OCR text detection |
| `documentTextDetection(source, maxResults?)` | `TextAnnotation \| null` | Dense document OCR |
| `faceDetection(source, maxResults?)` | `FaceAnnotation[]` | Face landmark and emotion detection |
| `safeSearchDetection(source, maxResults?)` | `SafeSearch \| null` | Explicit content detection (adult, violence, etc.) |
| `landmarkDetection(source, maxResults?)` | `EntityAnnotation[]` | Geographic landmark recognition |
| `logoDetection(source, maxResults?)` | `EntityAnnotation[]` | Brand logo recognition |
| `cropHints(source, maxResults?)` | `CropHint \| null` | Suggested image crop regions |
| `imageProperties(source, maxResults?)` | `ImageProperties \| null` | Dominant colors and image stats |
| `objectLocalization(source, maxResults?)` | `LocalizedObject[]` | Bounding boxes for objects |
| `webDetection(source, maxResults?)` | `WebDetection \| null` | Web entities, similar images, pages |

```typescript
// URL string
const labels = await vision.image.labelDetection('https://example.com/photo.jpg');

// Limit results
const top3 = await vision.image.labelDetection('https://example.com/photo.jpg', 3);

// Base64 content
const results = await vision.image.textDetection({
  content: fs.readFileSync('./document.jpg').toString('base64'),
});
```

### File API (`vision.file`)

Process PDFs and images stored in Google Cloud Storage. Accepts a GCS URI and optional `maxResults` cap.

| Method | Returns | Description |
|--------|---------|-------------|
| `labelDetection(gcsUri, maxResults?)` | `Label[]` | Labels for GCS objects |
| `textDetection(gcsUri, maxResults?)` | `TextAnnotation[]` | OCR from GCS files/PDFs |
| `documentTextDetection(gcsUri, maxResults?)` | `TextAnnotation[]` | Dense OCR from GCS files/PDFs |
| `faceDetection(gcsUri, maxResults?)` | `FaceAnnotation[]` | Face detection from GCS images |

```typescript
const labels = await vision.file.labelDetection('gs://my-bucket/document.pdf');
const texts = await vision.file.textDetection('gs://my-bucket/scanned-form.pdf');
```

---

## Builds

| Build | Import Path | API Transport | Use Case |
|-------|-------------|---------------|----------|
| **Node.js (ESM)** | `@unngh/google-vision` or `@unngh/google-vision/node` | Polyfilled `XMLHttpRequest` | Server-side apps, CLI tools |
| **Node.js (CommonJS)** | `require('@unngh/google-vision')` | Same as above | Legacy Node.js projects |
| **Browser** | `@unngh/google-vision/browser` | Native `fetch` | Web apps, browser extensions |

### Automatic Polyfills (Node.js)

On Node.js, the package automatically polyfills browser globals that dart2js expects:

- `self` → `globalThis`
- `window` → `globalThis`
- `XMLHttpRequest` → dynamically loaded `xhr2` package

No configuration needed — just import and use.

---

## Configuration Options

### Authentication Methods

| Method | Signature | Use Case |
|--------|-----------|----------|
| `withApiKey(key)` | `(apiKey: string) => this` | Quick starts, testing, client-side apps |
| `withJwt(credentials, scope?)` | `(json: string, scope?: string) => Promise<this>` | Production server-side apps |

### Prerequisites

1. **Enable the Vision API** in the [Google Cloud Console](https://console.cloud.google.com/apis/library/vision.googleapis.com).
2. **Create credentials** — API key (simplest) or service account (recommended for production).
3. **Set your API key** as `GOOGLE_VISION_API_KEY` environment variable, or pass it directly to `withApiKey()`.

---

## Examples

### Complete Workflow: Label + Safe Search + OCR

```typescript
import { GoogleVision } from '@unngh/google-vision';

const vision = await GoogleVision.create();
vision.withApiKey(process.env.GOOGLE_VISION_API_KEY!);

const imageUrl = 'https://example.com/analysis-target.jpg';

// Run multiple detections
const [labels, safeSearch, texts] = await Promise.all([
  vision.image.labelDetection(imageUrl),
  vision.image.safeSearchDetection(imageUrl),
  vision.image.textDetection(imageUrl),
]);

console.log('Labels:', labels.map((l) => l.description));
console.log('Safe:', safeSearch);
console.log('OCR:', texts[0]?.description?.slice(0, 200));
```

### Face Detection with Emotion Analysis

```typescript
const faces = await vision.image.faceDetection('https://example.com/group-photo.jpg');
console.log(`Found ${faces.length} face(s)`);

faces.forEach((face, i) => {
  console.log(`Face ${i + 1}:`);
  console.log(`  Joy:     ${face.joyLikelihood}`);
  console.log(`  Sorrow:  ${face.sorrowLikelihood}`);
  console.log(`  Anger:   ${face.angerLikelihood}`);
  console.log(`  Surprise: ${face.surpriseLikelihood}`);
});
```

### File Processing from Google Cloud Storage

```typescript
// Analyze a PDF stored in GCS
const labels = await vision.file.labelDetection('gs://my-bucket/reports/annual.pdf');
console.log('Document labels:', labels.map((l) => l.description));

// Full document OCR
const ocr = await vision.file.documentTextDetection('gs://my-bucket/scans/form.pdf');
console.log('Document text:', ocr[0]?.description);
```

---

## Caveats & Limitations

1. **Bundle Size**: The dart2js runtime ships as a self-contained ES module. Expect ~150–300 KB gzipped. Tree-shaking is limited since dart2js emits a monolithic runtime.

2. **Exception Handling**: dart2js boxes Dart exceptions. In catch blocks, unwrap with:
   ```typescript
   catch (error) {
     const boxSym = error?.error
       ? Object.getOwnPropertySymbols(error.error)
           .find(s => s.toString().includes('jsBoxed'))
       : null;
     const realError = boxSym ? error.error[boxSym] : error;
     console.error(realError?.message ?? String(error));
   }
   ```

3. **Browser CORS**: The Vision API does not send CORS headers. Browser usage requires a proxy or is best suited for local development. For production browser apps, proxy requests through your own backend.

4. **Node Version Support**: Requires Node 18+. On older versions, the `xhr2` polyfill handles API transport transparently.

---

## Building from Source

```bash
# Install dependencies
npm install

# Build everything (dart2js + tsup)
npm run build

# Or with the build script directly
bash scripts/build.sh
```

### Build Outputs

- `build/dart/google_vision.js` — Raw dart2js runtime (~1–2 MB uncompressed)
- `dist/browser.js` — Browser ESM bundle
- `dist/node.js` — Node.js ESM bundle
- `dist/node.cjs` — Node.js CommonJS bundle
- `dist/*.d.ts` — TypeScript declaration files
- `dist/google_vision.runtime.js` — dart2js runtime (copied for dynamic import)

**Requirements**: Dart SDK ^3.8.0 for `dart2js` compilation.

---

## Relation to the Dart Package

All protocol logic lives in [`packages/google_vision/`](../google_vision/). This package is a thin JS/TS shim over the exact same code:

```
google_vision (Dart SDK)
    ↓ shared protocol logic
google_vision_js (JS/TS bindings)
    ↓ compiled via dart2js
google_vision_cli (CLI tool)
    ↓ uses same Dart SDK
```

**Feature parity is guaranteed** — if a Google Vision API feature exists in the Dart package, it works here.

---

## Contributing

Contributions welcome! This package is part of the [`google_vision_workspace`](https://github.com/cdavis-code/google_vision_workspace) monorepo.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Build and test: `npm run build`
5. Submit a pull request

### Publishing to npm

This package uses GitHub Actions for automated npm publishing. When you push a tag with the format `google_vision_js-v*`, it will automatically build and publish to npm.

#### Using the Publish Script (Recommended)

```bash
# Inside packages/google_vision_js/

# Bump patch version (1.0.0 -> 1.0.1)
./scripts/publish-npm.sh patch

# Bump minor version (1.0.0 -> 1.1.0)
./scripts/publish-npm.sh minor

# Bump major version (1.0.0 -> 2.0.0)
./scripts/publish-npm.sh major

# Set specific version
./scripts/publish-npm.sh 1.2.0
```

The script will:
1. Update the version in package.json
2. Build the package (dart2js + tsup)
3. Create a git commit and tag
4. Provide instructions to push and trigger the GitHub Action

#### Manual Publishing

```bash
npm run build
npm publish --access=public
```

#### GitHub Action Trigger

Push the tag to trigger automated publishing:

```bash
git push origin main --tags
```

The workflow will:
- ✅ Build the package
- ✅ Publish to npm with public access
- ✅ Available at `https://www.npmjs.com/package/@unngh/google-vision`

**Note**: You need to set `NPM_TOKEN` as a GitHub secret for the workflow to authenticate with npm.

---

## License

MIT License — see [LICENSE](./LICENSE).

---

## Resources

- **[Google Vision API Documentation](https://cloud.google.com/vision/docs)**
- **[Dart SDK (google_vision)](https://pub.dev/packages/google_vision)**
- **[CLI Tool (google_vision_cli)](../google_vision_cli)**
- **[GitHub Repository](https://github.com/cdavis-code/google_vision_workspace)**
