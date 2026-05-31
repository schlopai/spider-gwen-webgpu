# Spider-Gwen - Across the Spider-Verse WebGPU demo

Written in tish, compiled to a bytecode chunk, run on a prebuilt wasm VM, rendering through browser **WebGPU**. An interactive, GPU-skinned, animated Spider-Gwen running through a neon
Spider-Verse city — glTF loading, GPU skeletal skinning, keyframe animation, a character
controller, post-processing (bloom / depth-of-field / ACES), and a HUD, all in tish.
Bundled with **Vite**.

## Prerequisites

- A **Chromium-based browser** (WebGPU).
- **Node** ≥ 18 + npm.
- The **`tish` CLI** on your `PATH` (`~/.cargo/bin/tish`) — compiles the engine to a
  bytecode chunk (`--target bytecode`). Override with `TISH=…` / `TISHLANG_WORKSPACE=…`.
- For **`build:runtime` only**: a **Rust toolchain** with the `wasm32-unknown-unknown`
  target, **`wasm-bindgen-cli`**, and the tish source tree (default `~/Projects/tish/tish`,
  override with `TISH_SRC=…`). This builds the `gpu`-featured tish wasm runtime (the
  WebGPU / JS-interop FFI). Its output (`vendor/`) is committed, so you normally don't
  need this.

`build:assets` uses `@gltf-transform/cli` (a dev dependency, run via `npx`) — no global install.

## Quick start

```bash
npm install
npm run build:runtime
npm run build:assets
npm run build
npm run dev          # builds the model on first run, then serves with HMR
```

Open the printed `http://localhost:…` URL in a Chromium-based browser. Editing a `.tish`
file recompiles the chunk and reloads; editing `boot.js` / shaders hot-reloads via Vite.

```bash
npm run build && npm run preview   # production bundle in dist/, then serve it
```

## Scripts

| Script | What it does |
|---|---|
| `npm run dev` | Vite dev server + HMR. `predev` builds `gen/spider-gwen.glb` if missing. |
| `npm run build` | Production bundle → `dist/` (content-hash fingerprinted). |
| `npm run preview` | Serve the built `dist/`. |
| `npm run build:runtime` | Rebuild the `gpu` tish wasm runtime → `vendor/` (rare; needs Rust + tish source). |
| `npm run build:assets` | (Re)optimize the model → `gen/spider-gwen.glb` (rare; from `assets-src/`). |
| `npm run clean` | Remove generated output (`dist/`, `gen/`). |

## Controls

- **WASD** move (camera-relative) · **Shift** run · **Space** jump
- **Right-drag** orbit camera · **Wheel** zoom · **Click / tap** move-to
- On-screen **Run / Jump / Hood** buttons · **1–9** action clips · **H** toggle hood

## How it builds

The engine is **tish source**, not JavaScript. `vite-plugin-tish.js` runs
`tish build --target bytecode` to compile `src/main.tish` (+ imports) into a raw bytecode
chunk; the prebuilt wasm VM in `vendor/` deserializes and runs it via `start(chunk, env)`.
The host loader `src/boot.js` does the irreducible browser glue — WebGPU device init, glTF
ingestion, input — then hands the VM an `env` object. Vite bundles `boot.js` + the
wasm-bindgen glue, **inlines the WGSL shaders** (`?raw`), and content-hash fingerprints the
runtime wasm, the bytecode chunk, and the model (no manual cache-busting).

## Layout

```
src/                     # SOURCE (hand-written) — nothing generated lives here
  boot.js                #   host loader: WebGPU init, GLB ingestion, start(chunk, env), input
  main.tish              #   engine entry: init, scene, 3-pass frame loop (scene→HDR, post, HUD)
  engine/*.tish          #   gpu, math, gltf, skin, animator, character, primitives, hud, buttonbar
  shaders/*.wgsl         #   WGSL (inlined into the bundle via ?raw)
vendor/                  # COMMITTED prebuilt tish wasm VM runtime (output of build:runtime)
  tish_vm.js  tish_vm_bg.wasm
assets-src/              # raw model source (input to build:assets)
gen/                     # GENERATED, gitignored: chunk.bin + spider-gwen.glb
dist/                    # GENERATED, gitignored: the Vite bundle
index.html               # entry — loads /src/boot.js
vite.config.js           # Vite config (+ the tish plugin)
vite-plugin-tish.js      # compiles src/*.tish → gen/chunk.bin; full-reloads on .tish change
build-runtime.sh         # cargo (--features gpu) + wasm-bindgen + wasm-opt → vendor/
build-assets.sh          # gltf-transform (resample/weld/prune + webp) → gen/spider-gwen.glb
```
