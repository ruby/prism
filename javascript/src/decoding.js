/**
 * An object that can be used to decode a byte array into a string.
 *
 * @typedef {{ decode: (bytes: Uint8Array) => string }} Decoder
 */

/**
 * The decoder used both as the decoder for binary and the fallback in case the
 * encoding is not supported.
 */
const binaryTextDecoder = {
  /**
   * Decodes a byte array into a string by treating each byte as a single
   * character. This is used for the ASCII-8BIT encoding from Ruby.
   *
   * @param {Uint8Array} bytes
   * @returns {string}
   */
  decode(bytes) {
    let result = "";
    for (const byte of bytes) {
      result += String.fromCharCode(byte);
    }

    return result;
  }
};

/**
 * Decoders built so far, keyed by the encoding and fatal setting they were
 * built for. Nothing here decodes in streaming mode, so a decoder carries no
 * state between calls and one instance serves every caller that wants the same
 * pair.
 *
 * @type {Map<string, Decoder>}
 */
const decoders = new Map();

/**
 * Get a Decoder from the encoding name. If the encoding is not supported, a
 * decoder that treats each byte as a single character is returned.
 *
 * @param {string} name
 * @param {{ fatal: boolean }} options
 * @returns {Decoder}
 */
export function getDecoder(name, options = { fatal: false }) {
  const lower = name.toLowerCase();
  const key = `${lower}:${options.fatal ? "fatal" : "replacement"}`;

  let decoder = decoders.get(key);
  if (decoder !== undefined) {
    return decoder;
  }

  if (lower === "ascii-8bit" || lower === "binary") {
    decoder = binaryTextDecoder;
  } else {
    try {
      decoder = new TextDecoder(lower, options);
    } catch (error) {
      if (error instanceof RangeError) {
        decoder = binaryTextDecoder;
      } else {
        throw error;
      }
    }
  }

  decoders.set(key, decoder);
  return decoder;
}
