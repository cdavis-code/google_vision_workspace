/**
 * google_vision_js — public TypeScript API.
 *
 * This facade wraps the dart2js-compiled `google_vision` core, exposing an
 * idiomatic JavaScript API: Promise-based methods, `image` and `file`
 * sub-APIs that mirror the Dart API shape.
 */

import type { DartRuntimeLoader } from './runtime.js';
import { getRuntime } from './runtime.js';
import type {
  ImageSource,
  VisionJsHandle,
} from './types.js';

export type { ImageSource } from './types.js';

/** Sub-API for image-based Google Vision operations. */
class GoogleVisionImage {
  constructor(private readonly handle: VisionJsHandle) {}

  labelDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]> {
    return this.handle.imageLabelDetection(imageSource, maxResults);
  }

  textDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]> {
    return this.handle.imageTextDetection(imageSource, maxResults);
  }

  faceDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]> {
    return this.handle.imageFaceDetection(imageSource, maxResults);
  }

  safeSearchDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any> | null> {
    return this.handle.imageSafeSearchDetection(imageSource, maxResults);
  }

  cropHints(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any> | null> {
    return this.handle.imageCropHints(imageSource, maxResults);
  }

  documentTextDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any> | null> {
    return this.handle.imageDocumentTextDetection(imageSource, maxResults);
  }

  imageProperties(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any> | null> {
    return this.handle.imageProperties(imageSource, maxResults);
  }

  landmarkDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]> {
    return this.handle.imageLandmarkDetection(imageSource, maxResults);
  }

  logoDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]> {
    return this.handle.imageLogoDetection(imageSource, maxResults);
  }

  objectLocalization(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any>[]> {
    return this.handle.imageObjectLocalization(imageSource, maxResults);
  }

  webDetection(
    imageSource: string | ImageSource,
    maxResults?: number,
  ): Promise<Record<string, any> | null> {
    return this.handle.imageWebDetection(imageSource, maxResults);
  }
}

/** Sub-API for file-based Google Vision operations (PDFs, GCS files). */
class GoogleVisionFile {
  constructor(private readonly handle: VisionJsHandle) {}

  labelDetection(
    gcsUri: string,
    maxResults?: number,
  ): Promise<Record<string, any>[]> {
    return this.handle.fileLabelDetection(gcsUri, maxResults);
  }

  textDetection(
    gcsUri: string,
    maxResults?: number,
  ): Promise<Record<string, any>[]> {
    return this.handle.fileTextDetection(gcsUri, maxResults);
  }

  documentTextDetection(
    gcsUri: string,
    maxResults?: number,
  ): Promise<Record<string, any>[]> {
    return this.handle.fileDocumentTextDetection(gcsUri, maxResults);
  }

  faceDetection(
    gcsUri: string,
    maxResults?: number,
  ): Promise<Record<string, any>[]> {
    return this.handle.fileFaceDetection(gcsUri, maxResults);
  }
}

export class GoogleVision {
  readonly image: GoogleVisionImage;
  readonly file: GoogleVisionFile;

  protected constructor(private readonly handle: VisionJsHandle) {
    this.image = new GoogleVisionImage(handle);
    this.file = new GoogleVisionFile(handle);
  }

  static async create(
    loader?: DartRuntimeLoader,
  ): Promise<GoogleVision> {
    if (!loader) {
      throw new Error(
        'No Dart runtime loader provided. Import from ' +
          "'@unngh/google-vision/node' or '@unngh/google-vision/browser' instead.",
      );
    }
    const ns = await getRuntime(loader);
    const handle = ns.create();
    return new GoogleVision(handle);
  }

  /** Authenticate using an API key (synchronous, chainable). */
  withApiKey(apiKey: string): this {
    this.handle.withApiKey(apiKey);
    return this;
  }

  /** Authenticate using JWT credentials (asynchronous, chainable). */
  async withJwt(
    credentialsJson: string,
    scope?: string,
  ): Promise<this> {
    await this.handle.withJwt(credentialsJson, scope);
    return this;
  }
}
