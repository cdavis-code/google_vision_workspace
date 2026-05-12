# Google Vision JS

![banner](https://raw.githubusercontent.com/cdavis-code/google_vision_workspace/main/packages/google_vision_js/images/banner.svg)

[![Pub Version](https://img.shields.io/pub/v/google_vision_js)](https://pub.dev/packages/google_vision_js)
[![npm Version](https://img.shields.io/npm/v/@unngh%2Fgoogle-vision)](https://www.npmjs.com/package/@unngh/google-vision)

JavaScript interop wrapper for the Google Vision API. Enables Vision AI features — image labeling, face detection, OCR, safe search, and more — in Node.js and browser environments.

This package wraps the [google_vision](https://pub.dev/packages/google_vision) Dart library using `dart:js_interop` and compiles to JavaScript via `dart compile js`.

## Features

- Label Detection
- Face Detection
- Text Detection (OCR)
- Document Text Detection
- Safe Search Detection
- Landmark Detection
- Logo Detection
- Image Properties
- Crop Hints
- Web Detection
- Object Localization
- API Key and JWT authentication

## Installation

### npm

```bash
npm install @unngh/google-vision
```

### pub.dev

```bash
dart pub add google_vision_js
```

## Prerequisites

### 1. Enable the Vision API

Go to the [Google Cloud Console](https://console.cloud.google.com/), select or create a project, and enable the [Vision API](https://console.cloud.google.com/apis/library/vision.googleapis.com).

### 2. Get an API key

1. In the Cloud Console, go to **APIs & Services > Credentials**.
2. Click **Create Credentials > API Key**.
3. Copy the generated API key.
4. (Optional but recommended) Restrict the key to the Vision API to prevent unauthorized usage.

> **Tip:** For production use, consider [service account authentication](#authentication) with JWT instead of an API key. Service accounts provide more granular permissions and are the recommended approach for server-side applications.

### 3. Set the API key

```sh
export GOOGLE_VISION_API_KEY="your-api-key-here"
```

## Usage

```javascript
import { GoogleVisionJs } from '@unngh/google-vision';

const vision = new GoogleVisionJs();

// Authenticate with API key
vision.withApiKey(process.env.GOOGLE_VISION_API_KEY);

// Detect labels in an image
const labels = await vision.image.labelDetection({
  imageUri: 'https://example.com/image.jpg'
});

console.log(labels);
```

## Authentication

### API Key

The simplest way to authenticate. Best for quick starts and testing.

```javascript
vision.withApiKey('YOUR_API_KEY');
```

### JWT (Service Account)

The recommended approach for production. Uses a Google Cloud service account JSON key file.

```javascript
const credentials = fs.readFileSync('./service-account.json', 'utf-8');
await vision.withJwt(credentials);
```

## Building from source

```bash
# Install Dart dependencies
dart pub get

# Compile to JavaScript
dart run tool/compile_js.dart
```

## License

MIT
