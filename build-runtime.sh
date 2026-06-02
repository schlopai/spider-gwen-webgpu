#!/usr/bin/env bash
# Build the gpu-featured tish wasm runtime (the JS-interop FFI + rAF + start()),
# wasm-bindgen it into vendor/, then size-optimize with wasm-opt. Run this only when
# the Rust runtime (~/Projects/tish/tish) changes. The output (vendor/tish_vm.js +
# vendor/tish_vm_bg.wasm) is committed; Vite fingerprints it at build time.
#
# Uses a dedicated CARGO_TARGET_DIR so this `--features gpu` build doesn't thrash with
# other tish wasm builds in the workspace's default target/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
TISH_SRC="${TISH_SRC:-$HOME/Projects/tish/tish}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$TISH_SRC/target-gpu}"

echo "Building gpu wasm runtime (target: $CARGO_TARGET_DIR) ..."
( cd "$TISH_SRC" && cargo build -p tishlang_wasm_runtime \
    --target wasm32-unknown-unknown --release --features gpu )

echo "wasm-bindgen -> vendor/ ..."
wasm-bindgen --target web --no-typescript \
  --out-dir "$ROOT/vendor" --out-name tish_vm \
  "$CARGO_TARGET_DIR/wasm32-unknown-unknown/release/tishlang_wasm_runtime.wasm"

echo "wasm-opt -Oz ..."
before=$(wc -c < "$ROOT/vendor/tish_vm_bg.wasm")
# reference-types + bulk-memory are emitted by wasm-bindgen; wasm-opt must allow them.
npx --no-install wasm-opt -Oz --enable-reference-types --enable-bulk-memory \
  "$ROOT/vendor/tish_vm_bg.wasm" -o "$ROOT/vendor/tish_vm_bg.wasm"
after=$(wc -c < "$ROOT/vendor/tish_vm_bg.wasm")

echo "Runtime ready: vendor/tish_vm.js  (wasm ${before} -> ${after} bytes)"
