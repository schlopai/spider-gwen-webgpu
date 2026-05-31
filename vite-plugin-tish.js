// Compiles the tish engine (src/main.tish + imports) to a raw bytecode chunk via the
// tish CLI, so boot.js can `import '../gen/chunk.bin?url'` and Vite fingerprints it.
// In dev it watches src/**/*.tish and full-reloads on change (the wasm VM holds all
// engine state, so there is nothing to hot-swap — a fresh chunk needs a fresh VM).
import { execFileSync } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const ROOT = path.dirname(fileURLToPath(import.meta.url));
const TISH = process.env.TISH || path.join(process.env.HOME, '.cargo/bin/tish');
const WORKSPACE = process.env.TISHLANG_WORKSPACE || path.join(process.env.HOME, 'Projects/tish/tish');
const ENTRY = path.join(ROOT, 'src/main.tish');
const OUT = path.join(ROOT, 'gen/chunk.bin');

function compile() {
  mkdirSync(path.dirname(OUT), { recursive: true });
  execFileSync(TISH, ['build', ENTRY, '--target', 'bytecode', '-o', OUT], {
    stdio: 'inherit',
    env: { ...process.env, TISHLANG_WORKSPACE: WORKSPACE },
  });
}

export default function tishPlugin() {
  return {
    name: 'vite-plugin-tish',
    enforce: 'pre',

    // Runs before the module graph is built for both `vite` (dev) and `vite build`,
    // so gen/chunk.bin exists before boot.js's `?url` import is resolved.
    buildStart() {
      compile();
    },

    configureServer(server) {
      server.watcher.add(path.join(ROOT, 'src/**/*.tish'));
    },

    handleHotUpdate(ctx) {
      if (!ctx.file.endsWith('.tish')) return;
      compile();
      ctx.server.ws.send({ type: 'full-reload' });
      return []; // handled — suppress Vite's default HMR for .tish
    },
  };
}
