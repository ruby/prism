import { ParseResult, deserialize } from "./deserialize.js";

/**
 * Parse the given source code.
 *
 * @param {WebAssembly.Exports} prism
 * @param {string} source
 * @returns {ParseResult}
 */
export function parsePrism(prism, source) {
  const sourceArray = new TextEncoder().encode(source);
  const sourcePointer = prism.calloc(1, sourceArray.length);

  const bufferPointer = prism.calloc(prism.pm_buffer_sizeof(), 1);
  prism.pm_buffer_init(bufferPointer);

  const sourceView = new Uint8Array(prism.memory.buffer, sourcePointer, sourceArray.length);
  sourceView.set(sourceArray);

  prism.pm_serialize_parse(bufferPointer, sourcePointer, sourceArray.length);
  const serializedView = new Uint8Array(prism.memory.buffer, prism.pm_buffer_value(bufferPointer), prism.pm_buffer_length(bufferPointer));
  const result = deserialize(sourceArray, serializedView);

  prism.pm_buffer_free(bufferPointer);
  prism.free(sourcePointer);
  prism.free(bufferPointer);
  return result;
}
