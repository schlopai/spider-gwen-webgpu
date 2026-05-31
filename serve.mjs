// Zero-dependency static dev server for spider3-tish.
// Serves the project root so index.html can reach ./dist, ./src/shaders, ./public.
// Sets application/wasm + model/gltf+json MIME types and disables caching for the
// build outputs (so reloads always pick up a fresh `npm run build`).
//
//   PORT=8080 node serve.mjs   (default port 8080)
//
// WebGPU requires a Chromium-based browser.

import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

// Strip any trailing separator so the `root + sep` traversal guard below works.
const root = fileURLToPath(new URL('.', import.meta.url)).replace(/[\\/]+$/, '');
const port = Number(process.env.PORT) || 8080;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.gltf': 'model/gltf+json',
  '.bin': 'application/octet-stream',
  '.b64': 'text/plain; charset=utf-8',
  '.wgsl': 'text/plain; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
};

// Build outputs change every rebuild → never cache. Big assets (glTF/bin/images)
// don't change → cache so reloads stay fast.
const NO_CACHE = new Set(['.html', '.js', '.mjs', '.wasm', '.b64', '.wgsl']);

const server = createServer(async (req, res) => {
  try {
    let urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
    if (urlPath === '/' || urlPath === '') urlPath = '/index.html';
    const filePath = normalize(join(root, urlPath));
    if (filePath !== root && !filePath.startsWith(root + sep)) {
      res.writeHead(403).end('Forbidden');
      return;
    }
    const data = await readFile(filePath);
    const ext = extname(filePath).toLowerCase();
    res.writeHead(200, {
      'Content-Type': MIME[ext] || 'application/octet-stream',
      'Cache-Control': NO_CACHE.has(ext) ? 'no-store' : 'public, max-age=3600',
    });
    res.end(data);
  } catch (err) {
    const code = err && err.code === 'ENOENT' ? 404 : 500;
    res.writeHead(code).end(`${code} ${err && err.message ? err.message : err}`);
  }
});

server.listen(port, () => {
  console.log(`spider3-tish  →  http://localhost:${port}`);
  console.log('Open in a Chromium-based browser (WebGPU). Ctrl+C to stop.');
});
