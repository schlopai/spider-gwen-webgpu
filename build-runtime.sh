#!/usr/bin/env bash
# Build the gpu-featured tish wasm runtime (the JS-interop FFI + rAF + start())
# and wasm-bindgen it into dist/runtime/. Run this only when the Rust runtime
# (~/Projects/tish/tish) changes.
#
# Uses a dedicated CARGO_TARGET_DIR so this `--features gpu` build doesn't
# thrash with `tish build --target wasm`'s `--features browser` build that
# build.sh triggers in the workspace's default target/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
TISH_SRC="${TISH_SRC:-$HOME/Projects/tish/tish}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$TISH_SRC/target-gpu}"

echo "Building gpu wasm runtime (target: $CARGO_TARGET_DIR) ..."
( cd "$TISH_SRC" && cargo build -p tishlang_wasm_runtime \
    --target wasm32-unknown-unknown --release --features gpu )

echo "wasm-bindgen -> dist/runtime ..."
wasm-bindgen --target web \
  --out-dir "$ROOT/dist/runtime" --out-name tish_vm \
  "$CARGO_TARGET_DIR/wasm32-unknown-unknown/release/tishlang_wasm_runtime.wasm"

echo "Runtime ready: dist/runtime/tish_vm.js"
