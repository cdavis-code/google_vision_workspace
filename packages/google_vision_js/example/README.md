# Google Vision JS Examples

Node.js example scripts that demonstrate how to use the Google Vision
JS library for image analysis.

## Prerequisites

- [Dart SDK](https://dart.dev/get-dart) 3.8.0 or later (for building the JS output)
- [Node.js](https://nodejs.org/) 18.0.0 or later
- A Google Cloud API key with the [Vision API](https://console.cloud.google.com/apis/library/vision.googleapis.com) enabled

## Setup

### 1. Get a Google Vision API key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project (or select an existing one)
3. Enable the [Vision API](https://console.cloud.google.com/apis/library/vision.googleapis.com)
4. Go to **APIs & Services > Credentials**
5. Click **Create Credentials > API Key**
6. Copy your API key

### 2. Build the JavaScript output

From the `packages/google_vision_js` directory:

```sh
npm install
bash scripts/build.sh
```

This produces the compiled Dart runtime in `build/dart/` and the bundled TypeScript output in `dist/`.

### 3. Set your API key

```sh
export GOOGLE_VISION_API_KEY="your-api-key-here"
```

## Running the Example

### Label, Safe Search, Text, and Face Detection

Runs multiple detection types on a sample image:

```sh
node example/vision_example.mjs
```

The example imports from `../dist/node.js` (the built output). Run the build first.

To use your own image, pass a URL:

```sh
node example/vision_example.mjs "https://example.com/your-photo.jpg"
```

### Expected Output

```
Initializing Google Vision...

Analyzing image: https://storage.googleapis.com/...

--- Label Detection ---
  1. Sky (score: 94.2%)
  2. Building (score: 89.7%)
  3. Tower (score: 85.1%)
  ...

--- Safe Search Detection ---
  Adult:    VERY_UNLIKELY
  Spoof:    VERY_UNLIKELY
  Medical:  VERY_UNLIKELY
  Violence: VERY_UNLIKELY
  Racy:     VERY_UNLIKELY

--- Text Detection (OCR) ---
  Detected 3 text element(s).
  First text: "WELCOME TO..."

--- Face Detection ---
  Detected 2 face(s).
  Face 1: joy=VERY_LIKELY, sorrow=VERY_UNLIKELY
  Face 2: joy=LIKELY, sorrow=VERY_UNLIKELY

Analysis complete!
```

## Single-Feature Examples

### Label Detection Only

```js
import { GoogleVision } from '@unngh/google-vision/node';

const vision = await GoogleVision.create();
vision.withApiKey('YOUR_API_KEY');

const labels = await vision.image.labelDetection(
  'https://example.com/photo.jpg',
  10, // max results
);

labels.forEach((label) =>
  console.log(`${label.description}: ${(label.score * 100).toFixed(1)}%`),
);
```

### Face Detection

```js
const faces = await vision.image.faceDetection(
  'https://example.com/photo.jpg',
);

console.log(`Detected ${faces.length} face(s)`);
faces.forEach((face, i) => {
  console.log(`Face ${i + 1}: joy=${face.joyLikelihood}`);
});
```

### OCR / Text Detection

```js
const texts = await vision.image.textDetection(
  'https://example.com/document.jpg',
);

texts.forEach((text) => console.log(text.description));
```

### Using Base64-Encoded Images

```js
import { readFileSync } from 'fs';

const imageBuffer = readFileSync('./path/to/photo.jpg');
const base64Image = imageBuffer.toString('base64');

const labels = await vision.image.labelDetection({ content: base64Image });
```

## Using JWT Authentication (Service Account)

For server-to-server authentication with a Google service account:

```js
import { readFileSync } from 'fs';
import { GoogleVision } from '@unngh/google-vision/node';

const credentials = readFileSync('./credentials.json', 'utf-8');
const vision = await GoogleVision.create();
await vision.withJwt(credentials);

const labels = await vision.image.labelDetection(
  'gs://your-bucket/image.jpg',
);
```

## Running from the Project Root

From the repository root:

```sh
cd packages/google_vision_js
node example/vision_example.mjs
```
