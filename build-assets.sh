#!/usr/bin/env bash
# Optimize the raw Spider-Gwen model into a single self-contained .glb. Generated
# output → gen/spider-gwen.glb (gitignored, regenerated; NOT committed). The raw
# source lives in assets-src/. `npm run dev`/`build` auto-runs this if the .glb is
# missing (see the predev/prebuild hooks); run it directly when the source changes.
#
# Pipeline is intentionally LOSSLESS and tish-transparent:
#   - resample: dedup redundant animation keyframes (the bulk — Sketchfab keys every frame)
#   - dedup / prune / weld: merge + drop unused data, minified JSON in the glb container
#   - texture-compress webp: browser-native decode, no runtime transcoder
# NO geometry compression / quantization / simplification and NO scene-graph restructuring
# (flatten/join/instance/palette), so the host loader hands tish the same plain f32 accessors
# + ImageBitmaps and the engine (tish + WGSL) is unchanged. (Meshopt/Draco/KTX2 were rejected:
# they'd add a runtime decoder + dequant for ~1MB of geometry, fighting the no-JS goal.)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/assets-src/spider-gwen_-_across_the_spider-verse/scene.gltf"
OUT="$ROOT/gen/spider-gwen.glb"

if [ ! -f "$SRC" ]; then
  echo "ERROR: raw source not found at $SRC" >&2
  echo "  (restore it from the sibling spider3/public/ to re-optimize)" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
echo "Optimizing model -> $OUT ..."
npx gltf-transform optimize "$SRC" "$OUT" \
  --compress false \
  --simplify false \
  --instance false \
  --flatten false \
  --join false \
  --palette false \
  --texture-compress webp

echo "Model ready: $(du -h "$OUT" | cut -f1)  $OUT"
