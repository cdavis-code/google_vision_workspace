/**
 * Loads the dart2js-compiled runtime and returns the `GoogleVisionJs`
 * namespace installed on `globalThis`. Dispatch is platform-specific — see
 * `browser.ts` and `node.ts` for the actual loader implementations.
 */

import type { VisionJsNamespace } from './types.js';

let cached: VisionJsNamespace | undefined;

export type DartRuntimeLoader = () => Promise<void>;

export async function getRuntime(
  loader: DartRuntimeLoader,
): Promise<VisionJsNamespace> {
  if (cached) return cached;
  await loader();
  const ns = (globalThis as any).GoogleVisionJs as
    | VisionJsNamespace
    | undefined;
  if (!ns) {
    throw new Error(
      'google_vision_js runtime failed to initialise: ' +
        'globalThis.GoogleVisionJs was not installed.',
    );
  }
  cached = ns;
  return ns;
}
