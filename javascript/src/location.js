/**
 * A location in the source code. Locations are stored as byte offsets into the
 * source, because bytes are the unit that the parser itself works in.
 */
export class Location {
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
   * @param {number} startOffset
   * @param {number} length
   */
  constructor(startOffset, length) {
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
}
