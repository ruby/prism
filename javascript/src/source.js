import { getDecoder } from "./decoding.js";

/**
 * The encoder used to count code units for the utf-8 position encoding. The
 * TextEncoder interface only ever emits utf-8, which is exactly what is needed
 * here.
 */
const encoder = new TextEncoder();

/**
 * A source of Ruby code that has been parsed. Locations hold a pointer to the
 * source they came from, which is what allows them to resolve line numbers,
 * columns, and the source code that they represent.
 */
export class Source {
  /**
   * The bytes of the source code, in the encoding that it was parsed in.
   *
   * @type {Uint8Array}
   */
  bytes;

  /**
   * The name of the encoding that the source code is in, as determined by the
   * parser options or by the encoding magic comment.
   *
   * @type {string}
   */
  encoding;

  /**
   * The line number that the source starts on.
   *
   * @type {number}
   */
  startLine;

  /**
   * The byte offset of the start of each line in the source code. The first
   * element is always 0 to mark the first line.
   *
   * @type {number[]}
   */
  offsets;

  /**
   * The decoder used to convert this source's bytes into strings. It is created
   * on first use because not every encoding that the parser accepts has a
   * TextDecoder equivalent, and parsing should not fail on that basis.
   *
   * @type {Decoder | null}
   */
  #decoder;

  /**
   * Construct a new Source.
   *
   * @param {Uint8Array} bytes
   * @param {string} encoding
   * @param {number} startLine
   * @param {number[]} offsets
   */
  constructor(bytes, encoding, startLine, offsets) {
    this.bytes = bytes;
    this.encoding = encoding;
    this.startLine = startLine;
    this.offsets = offsets;
    this.#decoder = null;
  }

  /**
   * Decode the given byte range of the source code into a string. Because a
   * byte range can begin or end in the middle of a multi-byte character, bytes
   * that do not form a whole character are decoded into replacement
   * characters.
   *
   * @param {number} byteOffset
   * @param {number} length
   * @param {TextDecoder | null} decoder
   * @returns {string}
   */
  slice(byteOffset, length, decoder = null) {
    if (decoder === null) {
      decoder = this.#defaultDecoder();
    }

    return decoder.decode(this.bytes.subarray(byteOffset, byteOffset + length));
  }

  /**
   * The decoder for this source's own encoding. It is created on first use
   * because not every encoding that the parser accepts has a TextDecoder
   * equivalent, and parsing should not fail on that basis.
   *
   * @returns {Decoder}
   */
  #defaultDecoder() {
    if (this.#decoder === null) {
      this.#decoder = getDecoder(this.encoding);
    }

    return this.#decoder;
  }

  /**
   * The line number that the given byte offset is on.
   *
   * @param {number} byteOffset
   * @returns {number}
   */
  line(byteOffset) {
    return this.startLine + this.findLine(byteOffset);
  }

  /**
   * The byte offset of the start of the line that the given byte offset is on.
   *
   * @param {number} byteOffset
   * @returns {number}
   */
  lineStart(byteOffset) {
    return this.offsets[this.findLine(byteOffset)];
  }

  /**
   * The byte offset of the end of the line that the given byte offset is on.
   *
   * @param {number} byteOffset
   * @returns {number}
   */
  lineEnd(byteOffset) {
    const offset = this.offsets[this.findLine(byteOffset) + 1];
    return offset === undefined ? this.bytes.length : offset;
  }

  /**
   * The column in bytes of the given byte offset from the start of its line.
   *
   * @param {number} byteOffset
   * @returns {number}
   */
  column(byteOffset) {
    return byteOffset - this.lineStart(byteOffset);
  }

  /**
   * The column in code units of the given byte offset from the start of its
   * line, counted in the given position encoding. A code unit is the smallest
   * unit of an encoding form, so utf-8 counts bytes, utf-16 counts sixteen bit
   * units where characters outside the basic multilingual plane take two, and
   * utf-32 counts whole codepoints.
   *
   * These are the three position encodings of the language server protocol,
   * spelled the way the protocol spells them, so a negotiated value can be
   * passed straight through. It defaults to utf-16 because that is what the
   * protocol defaults to.
   *
   * The prefix of the line is decoded through this source's own encoding
   * first, so a given character resolves to the same column no matter which
   * encoding the source was parsed in.
   *
   * @param {number} byteOffset
   * @param {"utf-8" | "utf-16" | "utf-32"} encoding
   * @returns {number}
   */
  codeUnitsColumn(byteOffset, encoding = "utf-16") {
    const lineStart = this.lineStart(byteOffset);

    /* Byte offsets are themselves utf-8 code units when the source is utf-8,
     * and counting them directly keeps bytes that do not decode from inflating
     * the column into the width of the replacement character. */
    if (encoding === "utf-8" && this.encoding.toLowerCase() === "utf-8") {
      return byteOffset - lineStart;
    }

    const prefix = this.#defaultDecoder().decode(this.bytes.subarray(lineStart, byteOffset));

    switch (encoding) {
      case "utf-8":
        return encoder.encode(prefix).length;
      case "utf-16":
        return prefix.length;
      case "utf-32": {
        /* Every codepoint is one utf-16 code unit except those outside the
         * basic multilingual plane, which are a surrogate pair. Decoders only
         * ever produce well-formed utf-16, substituting the replacement
         * character for anything they cannot pair up, so every low surrogate
         * here closes a pair and dropping them leaves the codepoint count. */
        let count = prefix.length;

        for (let index = 0; index < prefix.length; index++) {
          const unit = prefix.charCodeAt(index);
          if (unit >= 0xdc00 && unit <= 0xdfff) count--;
        }

        return count;
      }
      default:
        throw new Error(`Unsupported position encoding '${encoding}'`);
    }
  }

  /**
   * Binary search through the offsets to find the index of the line that the
   * given byte offset is on.
   *
   * @param {number} byteOffset
   * @returns {number}
   */
  findLine(byteOffset) {
    let low = 0;
    let high = this.offsets.length;

    /* Find the first line that starts after the given byte offset; the line
     * that contains the offset is the one before it. */
    while (low < high) {
      const middle = (low + high) >>> 1;

      if (this.offsets[middle] > byteOffset) {
        high = middle;
      } else {
        low = middle + 1;
      }
    }

    return low - 1;
  }
}
