// src/runtime.ts
var cached;
async function getRuntime(loader) {
  if (cached) return cached;
  await loader();
  const ns = globalThis.GoogleVisionJs;
  if (!ns) {
    throw new Error(
      "google_vision_js runtime failed to initialise: globalThis.GoogleVisionJs was not installed."
    );
  }
  cached = ns;
  return ns;
}

// src/index.ts
var GoogleVisionImage = class {
  constructor(handle) {
    this.handle = handle;
  }
  handle;
  labelDetection(imageSource, maxResults) {
    return this.handle.imageLabelDetection(imageSource, maxResults);
  }
  textDetection(imageSource, maxResults) {
    return this.handle.imageTextDetection(imageSource, maxResults);
  }
  faceDetection(imageSource, maxResults) {
    return this.handle.imageFaceDetection(imageSource, maxResults);
  }
  safeSearchDetection(imageSource, maxResults) {
    return this.handle.imageSafeSearchDetection(imageSource, maxResults);
  }
  cropHints(imageSource, maxResults) {
    return this.handle.imageCropHints(imageSource, maxResults);
  }
  documentTextDetection(imageSource, maxResults) {
    return this.handle.imageDocumentTextDetection(imageSource, maxResults);
  }
  imageProperties(imageSource, maxResults) {
    return this.handle.imageProperties(imageSource, maxResults);
  }
  landmarkDetection(imageSource, maxResults) {
    return this.handle.imageLandmarkDetection(imageSource, maxResults);
  }
  logoDetection(imageSource, maxResults) {
    return this.handle.imageLogoDetection(imageSource, maxResults);
  }
  objectLocalization(imageSource, maxResults) {
    return this.handle.imageObjectLocalization(imageSource, maxResults);
  }
  webDetection(imageSource, maxResults) {
    return this.handle.imageWebDetection(imageSource, maxResults);
  }
};
var GoogleVisionFile = class {
  constructor(handle) {
    this.handle = handle;
  }
  handle;
  labelDetection(gcsUri, maxResults) {
    return this.handle.fileLabelDetection(gcsUri, maxResults);
  }
  textDetection(gcsUri, maxResults) {
    return this.handle.fileTextDetection(gcsUri, maxResults);
  }
  documentTextDetection(gcsUri, maxResults) {
    return this.handle.fileDocumentTextDetection(gcsUri, maxResults);
  }
  faceDetection(gcsUri, maxResults) {
    return this.handle.fileFaceDetection(gcsUri, maxResults);
  }
};
var GoogleVision = class _GoogleVision {
  constructor(handle) {
    this.handle = handle;
    this.image = new GoogleVisionImage(handle);
    this.file = new GoogleVisionFile(handle);
  }
  handle;
  image;
  file;
  static async create(loader) {
    if (!loader) {
      throw new Error(
        "No Dart runtime loader provided. Import from '@unngh/google-vision/node' or '@unngh/google-vision/browser' instead."
      );
    }
    const ns = await getRuntime(loader);
    const handle = ns.create();
    return new _GoogleVision(handle);
  }
  /** Authenticate using an API key (synchronous, chainable). */
  withApiKey(apiKey) {
    this.handle.withApiKey(apiKey);
    return this;
  }
  /** Authenticate using JWT credentials (asynchronous, chainable). */
  async withJwt(credentialsJson, scope) {
    await this.handle.withJwt(credentialsJson, scope);
    return this;
  }
};

// src/node.ts
var ensurePolyfills = async () => {
  const g = globalThis;
  if (!g.self) g.self = g;
  if (!g.window) g.window = g;
  if (!g.XMLHttpRequest) {
    const mod = await import("xhr2");
    g.XMLHttpRequest = mod.XMLHttpRequest ?? mod.default;
  }
};
var loadDart = async () => {
  await ensurePolyfills();
  await import("./google_vision-FY62C7II.js");
};
var GoogleVision2 = class extends GoogleVision {
  static async create() {
    return await GoogleVision.create(loadDart);
  }
};
export {
  GoogleVision2 as GoogleVision
};
//# sourceMappingURL=node.js.map