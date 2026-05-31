#!/usr/bin/env bash
# Compile the tish engine to a bytecode chunk for the wasm VM, and expose it as
# window.__CHUNK_B64 for index.html. (The wasm *runtime* is built separately by
# build-runtime.sh; here we only need the serialized bytecode.)
#
# `tish build --target wasm` embeds the chunk as base64 in its generated loader
# HTML; we harvest that and ignore the rest (we ship our own runtime + loader).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
TISH="${TISH:-$HOME/.cargo/bin/tish}"
# `tish build --target wasm` rebuilds the wasm runtime, so it needs the tish
# workspace. We ignore that runtime (we ship build-runtime.sh's gpu build) and
# only harvest the embedded bytecode chunk from its generated loader.
export TISHLANG_WORKSPACE="${TISHLANG_WORKSPACE:-$HOME/Projects/tish/tish}"

mkdir -p "$ROOT/dist/_gen"
echo "Compiling $ROOT/src/main.tish -> bytecode chunk ..."
"$TISH" build "$ROOT/src/main.tish" -o "$ROOT/dist/_gen/spider" --target wasm

B64="$(grep -o 'CHUNK_B64 = "[^"]*"' "$ROOT/dist/_gen/spider.html" | sed 's/CHUNK_B64 = "//; s/"$//')"
if [ -z "$B64" ]; then echo "ERROR: could not extract CHUNK_B64" >&2; exit 1; fi
printf '%s' "$B64" > "$ROOT/dist/chunk.b64"
echo "Wrote dist/chunk.b64 ($(printf '%s' "$B64" | wc -c | tr -d ' ') base64 chars)"
