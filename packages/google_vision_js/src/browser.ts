/**
 * Browser entrypoint for google_vision_js.
 *
 * Loads the dart2js runtime (which references browser globals already
 * present) and re-exports the public API.
 */

import { GoogleVision as Base } from './index.js';

export * from './index.js';

/**
 * In production builds, `../build/dart/google_vision.js` is emitted by
 * dart2js and bundled alongside the TS output by tsup. The dynamic import
 * lets bundlers (vite/webpack/rollup) split it into a separate chunk.
 */
const loadDart = async () => {
  // @ts-expect-error -- resolved at build time; present in dist/.
  await import('../build/dart/google_vision.js');
};

export class GoogleVision extends Base {
  static override async create(): Promise<GoogleVision> {
    return (await Base.create(loadDart)) as GoogleVision;
  }
}
