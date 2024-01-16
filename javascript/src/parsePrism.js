import { ParseResult, deserialize } from "./deserialize.js";

/**
 * Parse the given source code.
 *
 * @param {WebAssembly.Exports} prism
 * @param {string} source
 * @param {Object} options
 * @returns {ParseResult}
 */
export function parsePrism(prism, source, options = {}) {
  const sourceArray = new TextEncoder().encode(source);
  const sourcePointer = prism.calloc(1, sourceArray.length);

  const packedOptions = dumpOptions(options);
  const optionsPointer = prism.calloc(1, packedOptions.length);

  const bufferPointer = prism.calloc(prism.pm_buffer_sizeof(), 1);
  prism.pm_buffer_init(bufferPointer);

  const sourceView = new Uint8Array(prism.memory.buffer, sourcePointer, sourceArray.length);
  sourceView.set(sourceArray);

  const optionsView = new Uint8Array(prism.memory.buffer, optionsPointer, packedOptions.length);
  optionsView.set(packedOptions);

  prism.pm_serialize_parse(bufferPointer, sourcePointer, sourceArray.length, optionsPointer);
  const serializedView = new Uint8Array(prism.memory.buffer, prism.pm_buffer_value(bufferPointer), prism.pm_buffer_length(bufferPointer));
  const result = deserialize(sourceArray, serializedView);

  prism.pm_buffer_free(bufferPointer);
  prism.free(sourcePointer);
  prism.free(bufferPointer);
  prism.free(optionsPointer);
  return result;
}

// Converts the given options into a serialized options string.
function dumpOptions(options) {
  const values = [];
  const template = [];
  const encoder = new TextEncoder();

  template.push("L")
  if (options.filepath) {
    const filepath = encoder.encode(options.filepath);
    values.push(filepath.length);
    values.push(filepath);
    template.push("A");
  } else {
    values.push(0);
  }

  template.push("l");
  values.push(options.line || 1);

  template.push("L");
  if (options.encoding) {
    const encoding = encoder.encode(options.encoding);
    values.push(encoding.length);
    values.push(encoding);
    template.push("A");
  } else {
    values.push(0);
  }

  template.push("C");
  values.push(options.frozen_string_literal === undefined ? 0 : 1);

  template.push("C");
  values.push(options.verbose === undefined ? 0 : 1);

  template.push("C");
  if (!options.version || options.version === "latest") {
    values.push(0);
  } else if (options.version === "3.3.0") {
    values.push(1);
  } else {
    throw new Error(`Unsupported version '${options.version}' in compiler options`);
  }

  template.push("L");
  if (options.scopes) {
    const scopes = options.scopes;
    values.push(scopes.length);

    for (const scope of scopes) {
      template.push("L");
      values.push(scope.length);

      for (const local of scope) {
        const name = local.name;
        template.push("L");
        values.push(name.length);

        template.push("A")
        values.push(encoder.encode(name));
      }
    }
  } else {
    values.push(0);
  }

  return pack(values, template);
}

function totalSizeOf(values, template) {
  let size = 0;

  for (let i = 0; i < values.length; i ++) {
    size += sizeOf(values, template, i);
  }

  return size;
}

function sizeOf(values, template, index) {
  switch (template[index]) {
    // arbitrary binary string
    case "A":
      return values[index].length;

    // l: signed 32-bit integer, L: unsigned 32-bit integer
    case "l":
    case "L":
      return 4;

    // 8-bit unsigned integer
    case "C":
      return 1;
  }
}

// platform-agnostic implementation of Node's os.endianness()
function endianness() {
  const arr = new Uint8Array(4);
  new Uint32Array(arr.buffer)[0] = 0xffcc0011;
  return arr[0] === 0xff ? "BE" : "LE";
}

function pack(values, template) {
  const littleEndian = endianness() === "LE";
  const buffer = new ArrayBuffer(totalSizeOf(values, template));
  const data_view = new DataView(buffer);
  let offset = 0;

  for (let i = 0; i < values.length; i ++) {
    switch (template[i]) {
      case "A":
        for (let c = 0; c < values[i].length; c ++) {
          data_view.setUint8(offset + c, values[i][c]);
        }

        break;

      case "l":
        data_view.setInt32(offset, values[i], littleEndian);
        break;

      case "L":
        data_view.setUint32(offset, values[i], littleEndian);
        break;

      case "C":
        data_view.setUint8(offset, values[i], littleEndian);
        break;
    }

    offset += sizeOf(values, template, i);
  }

  return new Uint8Array(buffer);
}