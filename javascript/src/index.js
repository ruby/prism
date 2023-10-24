import { WASI } from "wasi";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

import { ParseResult } from "./deserialize.js";
import { parsePrism } from "./parsePrism.js";

/**
 * Load the prism wasm module and return a parse function.
 *
 * @returns {Promise<(source: string) => ParseResult>}
 */
export async function loadPrism() {
  const wasm = await WebAssembly.compile(await readFile(fileURLToPath(new URL("prism.wasm", import.meta.url))));
  const wasi = new WASI({ version: "preview1" });

  const instance = await WebAssembly.instantiate(wasm, wasi.getImportObject());
  wasi.initialize(instance);

  return function (source) {
    return parsePrism(instance.exports, source);
  }
}
