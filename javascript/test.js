import test, { suite } from "node:test";
import assert from "node:assert";
import { loadPrism } from "./src/index.js";
import * as nodes from "./src/nodes.js";
import { Location } from "./src/location.js";
import { Source } from "./src/source.js";
import { Visitor } from "./src/visitor.js";

const parse = await loadPrism();

function statement(result) {
  return result.value.statements.body[0];
}

function eachNode(node, callback) {
  callback(node);

  for (const child of node.childNodes()) {
    if (child) eachNode(child, callback);
  }
}

suite("fields", () => {
  test("node", () => {
    const result = parse("foo");
    assert(result.value instanceof nodes.ProgramNode);
  });

  test("node? present", () => {
    const result = parse("foo.bar");
    assert(statement(result).receiver instanceof nodes.CallNode);
  });

  test("node? absent", () => {
    const result = parse("foo");
    assert(statement(result).receiver === null);
  });

  test("node[]", () => {
    const result = parse("foo.bar");
    assert(result.value.statements.body instanceof Array);
  });

  suite("string", () => {
    test("basic", () => {
      const result = parse('"foo"');
      const node = statement(result);

      assert(!node.isForcedUtf8Encoding())
      assert(!node.isForcedBinaryEncoding())

      assert(node.unescaped.value === "foo");
      assert(node.unescaped.encoding === "utf-8");
      assert(node.unescaped.validEncoding);
    });

    test("forced utf-8 using \\u syntax", () => {
      const result = parse('# encoding: utf-8\n"\\u{9E7F}"');
      const node = statement(result);
      const str = node.unescaped;

      assert(node.isForcedUtf8Encoding());
      assert(!node.isForcedBinaryEncoding());

      assert(str.value === "鹿");
      assert(str.encoding === "utf-8");
      assert(str.validEncoding);
    });

    test("forced utf-8 string with invalid byte sequence", () => {
      const result = parse('# encoding: utf-8\n"\\xFF\\xFF\\xFF"');
      const node = statement(result);
      const str = node.unescaped;

      assert(node.isForcedUtf8Encoding());
      assert(!node.isForcedBinaryEncoding());

      assert(str.value === "ÿÿÿ");
      assert(str.encoding === "utf-8");
      assert(!str.validEncoding);
    });

    test("ascii with embedded utf-8 character", () => {
      // # encoding: ascii\n"鹿"'
      // # encoding: ascii\n"é¹¿"'
      const ascii_str = new Buffer.from([35, 32, 101, 110, 99, 111, 100, 105, 110, 103, 58, 32, 97, 115, 99, 105, 105, 10, 34, 233, 185, 191, 34]);
      const result = parse(ascii_str);
      const node = statement(result);
      const str = node.unescaped;

      assert(!node.isForcedUtf8Encoding());
      assert(node.isForcedBinaryEncoding());

      assert(str.value === "é¹¿");
      assert(str.encoding === "ascii-8bit");
      assert(str.validEncoding);
    });

    test("forced binary", () => {
      const result = parse('# encoding: ascii\n"\\xFF\\xFF\\xFF"');
      const node = statement(result);
      const str = node.unescaped;

      assert(!node.isForcedUtf8Encoding());
      assert(node.isForcedBinaryEncoding());

      assert(str.value === "ÿÿÿ");
      assert(str.encoding === "ascii-8bit");
      assert(str.validEncoding);
    });

    test("forced binary with Unicode character", () => {
      // # encoding: us-ascii\n"\\xFFé¹¿\\xFF"
      const ascii_str = Buffer.from([35, 32, 101, 110, 99, 111, 100, 105, 110, 103, 58, 32, 97, 115, 99, 105, 105, 10, 34, 92, 120, 70, 70, 233, 185, 191, 92, 120, 70, 70, 34]);
      const result = parse(ascii_str);
      const node = statement(result);
      const str = node.unescaped;

      assert(!node.isForcedUtf8Encoding());
      assert(node.isForcedBinaryEncoding());

      assert(str.value === "ÿé¹¿ÿ");
      assert(str.encoding === "ascii-8bit");
      assert(str.validEncoding);
    });
  });

  test("constant", () => {
    const result = parse("foo = 1");
    assert(result.value.locals[0] === "foo");
  });

  test("constant? present", () => {
    const result = parse("def foo(*bar); end");
    assert(statement(result).parameters.rest.name === "bar");
  });

  test("constant? absent", () => {
    const result = parse("def foo(*); end");
    assert(statement(result).parameters.rest.name === null);
  });

  test("constant[]", async() => {
    const result = parse("foo = 1");
    assert(result.value.locals instanceof Array);
  });

  test("location", () => {
    const result = parse("foo = 1");
    const location = result.value.location;

    assert(location instanceof Location);
    assert(location.startOffset === 0);
    assert(location.length === 7);
    assert(location.endOffset() === 7);
  });

  test("location? present", () => {
    const result = parse("def foo = bar");

    assert(statement(result).equalLoc instanceof Location);
  });

  test("location? absent", () => {
    const result = parse("def foo; bar; end");
    assert(statement(result).equalLoc === null);
  });

  test("uint8", () => {
    const result = parse("-> { _3 }");
    assert(statement(result).parameters.maximum === 3);
  });

  test("uint32", () => {
    const result = parse("foo = 1");
    assert(statement(result).depth === 0);
  });

  test("flags", () => {
    const result = parse("/foo/mi");
    const regexp = statement(result);

    assert(regexp.isIgnoreCase());
    assert(regexp.isMultiLine());
    assert(!regexp.isExtended());
  });

  suite("integer", () => {
    test("decimal", () => {
      const result = parse("10");
      assert(statement(result).value === 10);
    });

    test("hex", () => {
      const result = parse("0xA");
      assert(statement(result).value === 10);
    });

    test("2 nodes", () => {
      const result = parse("4294967296");
      assert(statement(result).value === 4294967296n);
    });

    test("3 nodes", () => {
      const result = parse("18446744073709552000");
      assert(statement(result).value === 18446744073709552000n);
    });
  });

  test("double", () => {
    const result = parse("1.0");
    assert(statement(result).value === 1.0);
  });
});

test("scopes", () => {
  let result;

  result = parse("foo");
  assert(statement(result) instanceof nodes.CallNode);

  result = parse("foo", { scopes: [["foo"]] });
  assert(statement(result) instanceof nodes.LocalVariableReadNode);

  result = parse("foo", { scopes: [{ locals: ["foo"] }] });
  assert(statement(result) instanceof nodes.LocalVariableReadNode);

  result = parse("foo(*)");
  assert(result.errors.length > 0);

  result = parse("foo(*)", { scopes: [{ forwarding: ["*"] }] });
  assert(result.errors.length === 0);
});

test("compactChildNodes() matches childNodes() without the nulls", () => {
  const sources = [
    "case a\nwhen b\n  c\nend",
    "case a\nin [b]\n  c\nend",
    "a, b = 1, 2",
    "def foo(a, b = 1, *c, d:, &e); end",
    "begin\n  a\nrescue B, C\n  d\nend",
    "case a\nin { b: Integer => c }\n  d\nend"
  ];

  for (const source of sources) {
    eachNode(parse(source).value, (node) => {
      assert.deepStrictEqual(
        node.compactChildNodes(),
        node.childNodes().filter((child) => child !== null),
        `${node.constructor.name} in ${JSON.stringify(source)}`
      );
    });
  }
});

test("visitor visits nodes inside node list fields", () => {
  class CallCollector extends Visitor {
    names = [];

    visitCallNode(node) {
      this.names.push(node.name);
      super.visitCallNode(node);
    }
  }

  function collect(source) {
    const visitor = new CallCollector();
    visitor.visit(parse(source).value);
    return visitor.names;
  }

  assert.deepStrictEqual(collect("case a\nwhen b\n  c\nend"), ["a", "b", "c"]);
  assert.deepStrictEqual(collect("begin\n  a\nrescue B\n  c\nend"), ["a", "c"]);
  assert.deepStrictEqual(collect("def foo(a = b); end"), ["b"]);
});

test("source", () => {
  const source = new Source(new TextEncoder().encode("foo\nbar\nbaz"), "utf-8", 1, [0, 4, 8]);

  assert.deepStrictEqual([0, 4, 8, 11].map((offset) => source.line(offset)), [1, 2, 3, 3]);
  assert.deepStrictEqual([0, 4, 8, 11].map((offset) => source.lineStart(offset)), [0, 4, 8, 8]);
  assert.deepStrictEqual([0, 4, 8, 11].map((offset) => source.lineEnd(offset)), [4, 8, 11, 11]);
  assert.deepStrictEqual([0, 4, 8, 11].map((offset) => source.column(offset)), [0, 0, 0, 3]);

  assert(source.slice(4, 3) === "bar");
  assert(source.slice(0, 11) === "foo\nbar\nbaz");
});

suite("location", () => {
  test("lines and columns", () => {
    const result = parse("foo\nbar\nbaz");
    const body = result.value.statements.body;

    assert.deepStrictEqual(body.map((node) => node.location.startLine()), [1, 2, 3]);
    assert.deepStrictEqual(body.map((node) => node.location.endLine()), [1, 2, 3]);
    assert.deepStrictEqual(body.map((node) => node.location.startColumn()), [0, 0, 0]);
    assert.deepStrictEqual(body.map((node) => node.location.endColumn()), [3, 3, 3]);
  });

  test("lines and columns spanning multiple lines", () => {
    const result = parse("foo(\n  bar\n)");
    const location = statement(result).location;

    assert(location.startLine() === 1);
    assert(location.startColumn() === 0);
    assert(location.endLine() === 3);
    assert(location.endColumn() === 1);
  });

  test("lines respect the line option", () => {
    for (const line of [-2147483648, -1073741824, -5, -1, 0, 1, 10, 1073741824, 2147483646]) {
      const result = parse("foo\nbar", { line });
      const body = result.value.statements.body;

      assert.deepStrictEqual(body.map((node) => node.location.startLine()), [line, line + 1]);
    }
  });

  test("slice", () => {
    const result = parse("foo(bar)");
    const node = statement(result);

    assert(node.location.slice() === "foo(bar)");
    assert(node.messageLoc.slice() === "foo");
    assert(node.arguments_.arguments_[0].location.slice() === "bar");
  });

  test("slice with multibyte characters", () => {
    const result = parse('"鹿" + "foo"');
    const node = statement(result);

    assert(node.receiver.location.slice() === '"鹿"');
    assert(node.receiver.location.startColumn() === 0);

    assert(node.receiver.location.endColumn() === 5);
    assert(node.arguments_.arguments_[0].location.slice() === '"foo"');
  });
});
