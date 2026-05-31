# spider3-tish

The **spider3** WebGPU engine, ported to [tish](https://tishlang.com): written in tish,
compiled to WebAssembly, rendering through browser **WebGPU**. An interactive,
GPU-skinned, animated Spider-Gwen running through a neon Spider-Verse city —
glTF loading, GPU skeletal skinning, keyframe animation, a character controller,
post-processing (bloom / depth-of-field / ACES), and a HUD, all in tish.

## Prerequisites

- A **Chromium-based browser** (WebGPU).
- **Node** ≥ 18 (for the dev server).
- The **`tish` CLI** on your `PATH` (`~/.cargo/bin/tish`) — used to compile the
  engine to a bytecode chunk. Override its location with `TISH=…` if needed.
- For `build:runtime` only: a **Rust toolchain** with the `wasm32-unknown-unknown`
  target and **`wasm-bindgen-cli`**, plus the tish source tree (default
  `~/Projects/tish/tish`, override with `TISH_SRC=…`). This builds the
  `gpu`-featured tish wasm runtime that provides the WebGPU/JS-interop FFI.

## Scripts

| Script | What it does |
|---|---|
| `npm run build:runtime` | Build the `gpu` tish wasm runtime → `dist/runtime/` (only when the Rust runtime changes). |
| `npm run build` | Compile the tish engine (`src/main.tish`) → `dist/chunk.b64`. |
| `npm run build:all` | `build:runtime` then `build`. |
| `npm start` (or `serve`) | Static dev server on `http://localhost:8080` (`PORT=…` to change). |
| `npm run dev` | `build` then `start`. |
| `npm run setup` | First-time: `build:runtime` + `build` + `start`. |
| `npm run clean` | Remove build intermediates. |

First time:

```bash
npm run setup        # builds the runtime + engine, then serves
```

Day to day (after the runtime is built):

```bash
npm run dev          # rebuild the engine + serve
```

Then open `http://localhost:8080` in a Chromium-based browser.

## Controls

- **WASD** — move (camera-relative) · **Shift** — run
- **Space** — jump
- **Right-drag** — orbit camera · **Mouse wheel** — zoom

## Layout

```
src/
  main.tish              # init, scene, 3-pass frame loop (scene→HDR, post, HUD)
  engine/
    gpu.tish             # the WebGPU surface (wraps the runtime's JS-interop FFI)
    math.tish            # mat4 / quat / vec3 on number[] (gl-matrix conventions)
    gltf.tish            # glTF loader (geometry, materials)
    skin.tish            # GPU skinning compute (skinning.wgsl)
    animator.tish        # glTF keyframe playback
    character.tish       # controller: movement, physics, camera
    primitives.tish      # box geometry (ground + neon towers)
    hud.tish             # OffscreenCanvas 2D → texture overlay (hud.wgsl)
  shaders/*.wgsl         # original WGSL, reused unchanged
public/                  # glTF character + textures
index.html               # host loader: async device init + start(chunk, env)
serve.mjs                # zero-dependency static dev server
```
