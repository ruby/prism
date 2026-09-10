import { getDecoder } from "./decoding.js";

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
      if (this.#decoder === null) {
        this.#decoder = getDecoder(this.encoding);
      }
      decoder = this.#decoder;
    }

    return decoder.decode(this.bytes.subarray(byteOffset, byteOffset + length));
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
