import { Source } from "./source.js";

/**
 * A location in the source code. Locations are stored as byte offsets into the
 * source, because bytes are the unit that the parser itself works in. They hold
 * a pointer to the source they came from so that they can resolve line numbers,
 * columns, and the source code that they represent.
 */
export class Location {
  /**
   * The source that this location points into. It is private so that it stays
   * off of the instance itself, which keeps locations cheap to serialize with
   * JSON.stringify.
   *
   * @type {Source}
   */
  #source;

  /**
   * The byte offset from the beginning of the source where this location
   * starts.
   *
   * @type {number}
   */
  startOffset;

  /**
   * The length of this location in bytes.
   *
   * @type {number}
   */
  length;

  /**
   * Construct a new Location.
   *
   * @param {Source} source
   * @param {number} startOffset
   * @param {number} length
   */
  constructor(source, startOffset, length) {
    this.#source = source;
    this.startOffset = startOffset;
    this.length = length;
  }

  /**
   * The byte offset from the beginning of the source where this location ends.
   *
   * @returns {number}
   */
  endOffset() {
    return this.startOffset + this.length;
  }

  /**
   * The line number where this location starts.
   *
   * @returns {number}
   */
  startLine() {
    return this.#source.line(this.startOffset);
  }

  /**
   * The line number where this location ends.
   *
   * @returns {number}
   */
  endLine() {
    return this.#source.line(this.endOffset());
  }

  /**
   * The column in bytes where this location starts from the start of its line.
   *
   * @returns {number}
   */
  startColumn() {
    return this.#source.column(this.startOffset);
  }

  /**
   * The column in bytes where this location ends from the start of its line.
   *
   * @returns {number}
   */
  endColumn() {
    return this.#source.column(this.endOffset());
  }

  /**
   * The source code that this location represents.
   *
   * @returns {string}
   */
  slice() {
    return this.#source.slice(this.startOffset, this.length);
  }
}
