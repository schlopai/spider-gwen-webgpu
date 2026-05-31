import { defineConfig } from 'vite';
import tish from './vite-plugin-tish.js';

// The engine is written in tish (src/*.tish), compiled to a bytecode chunk by the
// tish plugin, and run by the prebuilt wasm VM in vendor/. Vite bundles the boot
// loader + wasm-bindgen glue, inlines the WGSL shaders (?raw), and fingerprints the
// runtime wasm / bytecode chunk / model as content-hashed assets — replacing the old
// ?v=Date.now() cache-busting and the ~20 separate runtime fetches.
export default defineConfig({
  plugins: [tish()],
  build: {
    target: 'esnext', // modern WebGPU app; no syntax downleveling
    sourcemap: true,
  },
});
