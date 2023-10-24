import test from "node:test";
import assert from "node:assert";
import { loadPrism } from "./src/index.js";
import * as nodes from "./src/nodes.js";

const parse = await loadPrism();

test("node", () => {
  const result = parse("foo");
  assert(result.value instanceof nodes.ProgramNode);
});

test("node? present", () => {
  const result = parse("foo.bar");
  assert(result.value.statements.body[0].receiver instanceof nodes.CallNode);
});

test("node? absent", () => {
  const result = parse("foo");
  assert(result.value.statements.body[0].receiver === null);
});

test("node[]", () => {
  const result = parse("foo.bar");
  assert(result.value.statements.body instanceof Array);
});

test("string", () => {
  const result = parse('"foo"');
  assert(result.value.statements.body[0].unescaped === "foo");
});

test("constant", () => {
  const result = parse("foo = 1");
  assert(result.value.locals[0] === "foo");
});

test("constant? present", () => {
  const result = parse("def foo(*bar); end");
  assert(result.value.statements.body[0].parameters.rest.name === "bar");
});

test("constant? absent", () => {
  const result = parse("def foo(*); end");
  assert(result.value.statements.body[0].parameters.rest.name === null);
});

test("constant[]", async() => {
  const result = parse("foo = 1");
  assert(result.value.locals instanceof Array);
});

test("location", () => {
  const result = parse("foo = 1");
  assert(typeof result.value.location.startOffset === "number");
});

test("location? present", () => {
  const result = parse("def foo = bar");
  assert(result.value.statements.body[0].equalLoc !== null);
});

test("location? absent", () => {
  const result = parse("def foo; bar; end");
  assert(result.value.statements.body[0].equalLoc === null);
});

test("uint32", () => {
  const result = parse("foo = 1");
  assert(result.value.statements.body[0].depth === 0);
});

test("flags", () => {
  const result = parse("/foo/mi");
  const regexp = result.value.statements.body[0];

  assert(regexp.isIgnoreCase());
  assert(regexp.isMultiLine());
  assert(!regexp.isExtended());
});
