/**
 * Node.js entrypoint for google_vision_js.
 *
 * dart2js output targets the browser runtime — it expects `self`,
 * `window`, and `XMLHttpRequest` globals. We polyfill these before
 * loading the compiled module.
 */

import { GoogleVision as Base } from './index.js';

export * from './index.js';

const ensurePolyfills = async () => {
  const g = globalThis as any;
  if (!g.self) g.self = g;
  if (!g.window) g.window = g;
  if (!g.XMLHttpRequest) {
    const mod = await import('xhr2');
    g.XMLHttpRequest = (mod as any).XMLHttpRequest ?? (mod as any).default;
  }
};

const loadDart = async () => {
  await ensurePolyfills();
  // @ts-expect-error -- resolved at build time; present in dist/.
  await import('../build/dart/google_vision.js');
};

export class GoogleVision extends Base {
  static override async create(): Promise<GoogleVision> {
    return (await Base.create(loadDart)) as GoogleVision;
  }
}
