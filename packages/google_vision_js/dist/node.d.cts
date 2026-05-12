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
interface VisionJsHandle {
    /** Synchronous — returns the handle for chaining. */
    withApiKey(apiKey: string): VisionJsHandle;
    /** Asynchronous — resolves with the handle after JWT auth. */
    withJwt(credentialsJson: string, scope?: string): Promise<VisionJsHandle>;
    /** Image source can be a URL string or an object with `imageUri` / `content` (base64). */
    imageLabelDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    imageTextDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    imageFaceDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    imageSafeSearchDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any> | null>;
    imageCropHints(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any> | null>;
    imageDocumentTextDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any> | null>;
    imageProperties(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any> | null>;
    imageLandmarkDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    imageLogoDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    imageObjectLocalization(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    imageWebDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any> | null>;
    fileLabelDetection(gcsUri: string, maxResults?: number): Promise<Record<string, any>[]>;
    fileTextDetection(gcsUri: string, maxResults?: number): Promise<Record<string, any>[]>;
    fileDocumentTextDetection(gcsUri: string, maxResults?: number): Promise<Record<string, any>[]>;
    fileFaceDetection(gcsUri: string, maxResults?: number): Promise<Record<string, any>[]>;
}
/**
 * Image source: either a URL string or an object with `imageUri` or `content`.
 */
interface ImageSource {
    imageUri?: string;
    content?: string;
}

/**
 * Loads the dart2js-compiled runtime and returns the `GoogleVisionJs`
 * namespace installed on `globalThis`. Dispatch is platform-specific — see
 * `browser.ts` and `node.ts` for the actual loader implementations.
 */

type DartRuntimeLoader = () => Promise<void>;

/**
 * google_vision_js — public TypeScript API.
 *
 * This facade wraps the dart2js-compiled `google_vision` core, exposing an
 * idiomatic JavaScript API: Promise-based methods, `image` and `file`
 * sub-APIs that mirror the Dart API shape.
 */

/** Sub-API for image-based Google Vision operations. */
declare class GoogleVisionImage {
    private readonly handle;
    constructor(handle: VisionJsHandle);
    labelDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    textDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    faceDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    safeSearchDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any> | null>;
    cropHints(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any> | null>;
    documentTextDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any> | null>;
    imageProperties(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any> | null>;
    landmarkDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    logoDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    objectLocalization(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any>[]>;
    webDetection(imageSource: string | ImageSource, maxResults?: number): Promise<Record<string, any> | null>;
}
/** Sub-API for file-based Google Vision operations (PDFs, GCS files). */
declare class GoogleVisionFile {
    private readonly handle;
    constructor(handle: VisionJsHandle);
    labelDetection(gcsUri: string, maxResults?: number): Promise<Record<string, any>[]>;
    textDetection(gcsUri: string, maxResults?: number): Promise<Record<string, any>[]>;
    documentTextDetection(gcsUri: string, maxResults?: number): Promise<Record<string, any>[]>;
    faceDetection(gcsUri: string, maxResults?: number): Promise<Record<string, any>[]>;
}
declare class GoogleVision$1 {
    private readonly handle;
    readonly image: GoogleVisionImage;
    readonly file: GoogleVisionFile;
    protected constructor(handle: VisionJsHandle);
    static create(loader?: DartRuntimeLoader): Promise<GoogleVision$1>;
    /** Authenticate using an API key (synchronous, chainable). */
    withApiKey(apiKey: string): this;
    /** Authenticate using JWT credentials (asynchronous, chainable). */
    withJwt(credentialsJson: string, scope?: string): Promise<this>;
}

/**
 * Node.js entrypoint for google_vision_js.
 *
 * dart2js output targets the browser runtime — it expects `self`,
 * `window`, and `XMLHttpRequest` globals. We polyfill these before
 * loading the compiled module.
 */

declare class GoogleVision extends GoogleVision$1 {
    static create(): Promise<GoogleVision>;
}

export { GoogleVision, type ImageSource };
