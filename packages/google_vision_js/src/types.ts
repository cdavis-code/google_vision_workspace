/**
 * TypeScript type definitions for the dart2js-compiled google_vision
 * runtime and the public API surface.
 */

/**
 * Raw handle returned by `GoogleVisionJs.create()`.
 *
 * Each method on this handle is a closure that captures the underlying
 * Dart `GoogleVision` instance. Promise-returning methods use native
 * JS `Promise`, automatically converted from Dart `Future` by dart2js.
 */
export interface VisionJsHandle {
  /** Synchronous — returns the handle for chaining. */
  withApiKey(apiKey: string): VisionJsHandle;

  /** Asynchronous — resolves with the handle after JWT auth. */
  withJwt(credentialsJson: string, scope?: string): Promise<VisionJsHandle>;

  // ---- Image detection methods ----

  /** Image source can be a URL string or an object with `imageUri` / `content` (base64). */
  imageLabelDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]>;

  imageTextDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]>;

  imageFaceDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]>;

  imageSafeSearchDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any> | null>;

  imageCropHints(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any> | null>;

  imageDocumentTextDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any> | null>;

  imageProperties(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any> | null>;

  imageLandmarkDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]>;

  imageLogoDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]>;

  imageObjectLocalization(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]>;

  imageWebDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any> | null>;

  // ---- File detection methods (GCS URIs) ----

  fileLabelDetection(
    gcsUri: string,
    maxResults?: number,
  ): Promise<Record<string, any>[]>;

  fileTextDetection(
    gcsUri: string,
    maxResults?: number,
  ): Promise<Record<string, any>[]>;

  fileDocumentTextDetection(
    gcsUri: string,
    maxResults?: number,
  ): Promise<Record<string, any>[]>;

  fileFaceDetection(
    gcsUri: string,
    maxResults?: number,
  ): Promise<Record<string, any>[]>;
}

/**
 * Namespace installed on `globalThis` by the dart2js runtime.
 */
export interface VisionJsNamespace {
  create(): VisionJsHandle;
  version: string;
}

/**
 * Image source: either a URL string or an object with `imageUri` or `content`.
 */
export interface ImageSource {
  imageUri?: string;
  content?: string;
}
