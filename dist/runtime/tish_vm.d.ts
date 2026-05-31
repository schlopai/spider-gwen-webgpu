/* tslint:disable */
/* eslint-disable */

export function run(chunk: Uint8Array): void;

export function start(chunk: Uint8Array, env: any): void;

/**
 * Browser entry: run a tish bytecode `chunk` with the JS-interop FFI installed
 * and the host environment object (device/queue/context/format/canvas/assets,
 * built by the page's async startup glue) exposed as the `host` global.
 *
 * Returns after top-level tish runs; the `requestAnimationFrame` loop keeps
 * the captured globals alive via the stored callback, so the VM state persists
 * across frames even though this call returns.
 * Invoke the registered frame callback exactly once, without re-scheduling.
 * For driving frames deterministically from JS when `requestAnimationFrame` is
 * throttled (e.g. a hidden/offscreen preview tab) — verification & debugging.
 */
export function tick_once(ts: number): void;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
    readonly memory: WebAssembly.Memory;
    readonly run: (a: number, b: number) => [number, number];
    readonly start: (a: number, b: number, c: any) => [number, number];
    readonly tick_once: (a: number) => void;
    readonly wasm_bindgen__closure__destroy__hd83f8264c89f7964: (a: number, b: number) => void;
    readonly wasm_bindgen__convert__closures_____invoke__h7e886d19b3b52f5b: (a: number, b: number, c: number) => void;
    readonly __wbindgen_malloc: (a: number, b: number) => number;
    readonly __wbindgen_realloc: (a: number, b: number, c: number, d: number) => number;
    readonly __wbindgen_exn_store: (a: number) => void;
    readonly __externref_table_alloc: () => number;
    readonly __wbindgen_externrefs: WebAssembly.Table;
    readonly __externref_table_dealloc: (a: number) => void;
    readonly __wbindgen_start: () => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;

/**
 * Instantiates the given `module`, which can either be bytes or
 * a precompiled `WebAssembly.Module`.
 *
 * @param {{ module: SyncInitInput }} module - Passing `SyncInitInput` directly is deprecated.
 *
 * @returns {InitOutput}
 */
export function initSync(module: { module: SyncInitInput } | SyncInitInput): InitOutput;

/**
 * If `module_or_path` is {RequestInfo} or {URL}, makes a request and
 * for everything else, calls `WebAssembly.instantiate` directly.
 *
 * @param {{ module_or_path: InitInput | Promise<InitInput> }} module_or_path - Passing `InitInput` directly is deprecated.
 *
 * @returns {Promise<InitOutput>}
 */
export default function __wbg_init (module_or_path?: { module_or_path: InitInput | Promise<InitInput> } | InitInput | Promise<InitInput>): Promise<InitOutput>;
