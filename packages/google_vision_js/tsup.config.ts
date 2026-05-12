import { defineConfig } from 'tsup';

export default defineConfig([
  // Browser bundle — ESM only.
  {
    entry: { browser: 'src/browser.ts' },
    format: ['esm'],
    dts: true,
    sourcemap: true,
    clean: false,
    platform: 'browser',
    target: 'es2022',
  },
  // Node bundle — ESM + CJS.
  {
    entry: { node: 'src/node.ts' },
    format: ['esm', 'cjs'],
    dts: true,
    sourcemap: true,
    clean: false,
    platform: 'node',
    target: 'node18',
    external: ['xhr2'],
  },
  // Shared type surface — re-exports types for `import {Type} from '@unngh/google-vision'`.
  {
    entry: { index: 'src/index.ts' },
    format: ['esm'],
    dts: true,
    sourcemap: true,
    clean: false,
    platform: 'neutral',
    target: 'es2022',
  },
]);
