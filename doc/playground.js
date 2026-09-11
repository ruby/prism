import { WASI } from "https://unpkg.com/@bjorn3/browser_wasi_shim@latest/dist/index.js";
import { parsePrism } from "https://unpkg.com/@ruby/prism@latest/src/parsePrism.js";

const output = document.getElementById("output");
const editorDiv = document.getElementById("editor");
const loading = document.getElementById("loading");
const toast = document.getElementById("toast");

const encoder = new TextEncoder();
const decoder = new TextDecoder();

// Load Prism WASM and Monaco, show error if either fails
let instance, monaco;
try {
  const [wasmResult] = await Promise.all([
    WebAssembly.compileStreaming(fetch("https://unpkg.com/@ruby/prism@latest/src/prism.wasm"))
      .then(wasm => {
        const wasi = new WASI([], [], []);
        return WebAssembly.instantiate(wasm, { wasi_snapshot_preview1: wasi.wasiImport })
          .then(inst => { wasi.initialize(inst); return inst; });
      }),
    fetch("https://unpkg.com/@ruby/prism@latest/package.json")
      .then(r => r.json())
      .then(pkg => { document.getElementById("version").textContent = `v${pkg.version}`; })
      .catch(() => {})
  ]);
  instance = wasmResult;

  monaco = await new Promise((resolve, reject) => {
    require.config({ paths: { vs: "https://cdn.jsdelivr.net/npm/monaco-editor@0.52.2/min/vs" } });
    require(["vs/editor/editor.main"], resolve, reject);
  });
} catch (error) {
  loading.textContent = `Failed to load: ${error.message}`;
  throw error;
}

// Example snippets
const EXAMPLES = {
  fibonacci: `def fibonacci(n)
  case n
  when 0
    0
  when 1
    1
  else
    fibonacci(n - 1) + fibonacci(n - 2)
  end
end
`,
  pattern: `case [1, [2, 3]]
in [Integer => a, [Integer => b, Integer => c]]
  puts "matched: \#{a}, \#{b}, \#{c}"
in [Integer => a, *rest]
  puts "first: \#{a}, rest: \#{rest}"
end

config = { name: "prism", version: "1.0" }

case config
in { name: /^pr/ => name, version: }
  puts "\#{name} v\#{version}"
end
`,
  heredoc: `name = "World"

message = <<~HEREDOC
  Hello, \#{name}!
  Today is \#{Time.now}.
HEREDOC

query = <<~SQL.strip
  SELECT *
  FROM users
  WHERE active = true
SQL
`,
  blocks: `numbers = [1, 2, 3, 4, 5]

squares = numbers.map { |n| n ** 2 }
evens = numbers.select(&:even?)

doubler = ->(x) { x * 2 }

numbers.each do |n|
  puts doubler.call(n)
end

def with_logging(&block)
  puts "start"
  result = block.call
  puts "end"
  result
end
`,
  class: `class Person
  attr_accessor :name, :age

  def initialize(name, age)
    @name = name
    @age = age
  end

  def greeting = "Hi, I'm \#{name}!"

  def <=>(other)
    age <=> other.age
  end

  private

  def validate!
    raise ArgumentError, "Invalid age" unless age&.positive?
  end
end
`
};

// URL-safe base64 encode/decode (RFC 4648 §5)
function encodeSource(bytes) {
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function decodeSource(str) {
  const padded = str.replace(/-/g, "+").replace(/_/g, "/") + "==".slice(0, (4 - str.length % 4) % 4);
  return decoder.decode(Uint8Array.from(atob(padded), ch => ch.codePointAt(0)));
}

/* Ruby takes the source encoding from a magic comment on the first line, or the
 * second when the first is a shebang. Every encoding the parser accepts is
 * ascii compatible, which is what lets the comment be read before the encoding
 * it names is known. */
function declaredEncoding(source) {
  const lines = source.split("\n", 2);
  const line = lines[0].startsWith("#!") ? lines[1] : lines[0];
  const match = line && line.match(/^[ \t]*#.*?coding\s*[:=]\s*([\w-]+)/i);
  return match ? match[1].toLowerCase() : "utf-8";
}

/* TextEncoder only ever emits utf-8, so an encoder for any other encoding is
 * built by inverting the decoder the browser already ships. Sweeping the byte
 * space costs enough that each one is built once and kept.
 *
 * The sweep reaches sequences of up to three bytes. Four byte sequences, which
 * gb18030 uses for everything outside its two byte range, would take a million
 * and a half more probes, so they are left out and a character that needs one
 * is reported when the source actually uses it. Everything shorter, which is
 * all of an encoding's common range, encodes exactly. */
const encoders = new Map();

/* The character a byte sequence decodes to, or null when the sequence is not a
 * single character. Sequences that decode to more than one character are
 * rejected so that a run of single byte characters cannot shadow a real
 * multi byte mapping. */
function decodeSingle(decoder, bytes) {
  try {
    const character = decoder.decode(new Uint8Array(bytes));
    return [...character].length === 1 ? character : null;
  } catch {
    return null;
  }
}

function getEncoder(canonical) {
  if (encoders.has(canonical)) return encoders.get(canonical);

  const decoder = new TextDecoder(canonical, { fatal: true });
  const map = new Map();

  for (let byte = 0; byte < 0x100; byte++) {
    const character = decodeSingle(decoder, [byte]);
    if (character && !map.has(character)) map.set(character, [byte]);
  }

  for (let lead = 0x80; lead < 0x100; lead++) {
    for (let trail = 0; trail < 0x100; trail++) {
      const character = decodeSingle(decoder, [lead, trail]);
      if (character && !map.has(character)) map.set(character, [lead, trail]);
    }
  }

  /* euc-jp is the only encoding the browser decodes that reaches a third byte,
   * which it spends on JIS X 0212 behind a 0x8f lead with both continuation
   * bytes in 0xa1 to 0xfe. */
  if (canonical === "euc-jp") {
    for (let mid = 0xa1; mid <= 0xfe; mid++) {
      for (let trail = 0xa1; trail <= 0xfe; trail++) {
        const character = decodeSingle(decoder, [0x8f, mid, trail]);
        if (character && !map.has(character)) map.set(character, [0x8f, mid, trail]);
      }
    }
  }

  const encode = (source) => {
    const bytes = [];

    for (const character of source) {
      const encoded = map.get(character);
      if (!encoded) throw new Error(`${JSON.stringify(character)} could not be encoded as ${canonical}`);
      bytes.push(...encoded);
    }

    return new Uint8Array(bytes);
  };

  encoders.set(canonical, encode);
  return encode;
}

/* The bytes to hand the parser, in the encoding the source declares, so that it
 * sees what it would see reading the same file from disk. */
function sourceBytes(source) {
  const name = declaredEncoding(source);

  /* A comment can spell an encoding several ways, so the choice is made on the
   * canonical name the browser resolves it to rather than on what the comment
   * says. That keeps utf-8 on the encoder the platform already has, whichever
   * of its spellings was used. */
  let canonical;
  try {
    canonical = new TextDecoder(name).encoding;
  } catch {
    return {
      bytes: encoder.encode(source),
      notice: `This browser cannot encode ${name}, so the source was sent as utf-8. Results may differ from Ruby.`
    };
  }

  if (canonical === "utf-8") return { bytes: encoder.encode(source) };
  return { bytes: getEncoder(canonical)(source) };
}

// Read initial source from URL hash or use default
function sourceFromHash() {
  const hash = location.hash.slice(1);
  if (!hash) return null;
  try { return decodeSource(hash); } catch { return null; }
}

const initialSource = sourceFromHash() || EXAMPLES.fibonacci;

monaco.editor.defineTheme("prism", {
  base: "vs",
  inherit: true,
  rules: [],
  colors: { "editorLineNumber.foreground": "#6B7280" }
});

const monacoEditor = monaco.editor.create(document.getElementById("monaco-container"), {
  theme: "prism",
  value: initialSource,
  language: "ruby",
  minimap: { enabled: false },
  fontSize: 14,
  lineHeight: 21,
  scrollBeyondLastLine: false,
  automaticLayout: true,
  tabSize: 2
});

let currentTab = "ast";
let lastResult = null;
let lastNotice = null;
let currentDecorations = [];

// Tab switching
const tabs = Array.from(document.querySelectorAll("[role=tab]"));

function activateTab(tab) {
  tabs.forEach(t => {
    t.classList.remove("active");
    t.setAttribute("aria-selected", "false");
    t.setAttribute("tabindex", "-1");
  });
  tab.classList.add("active");
  tab.setAttribute("aria-selected", "true");
  tab.setAttribute("tabindex", "0");
  tab.focus();
  currentTab = tab.dataset.tab;
  render();
}

document.querySelector(".tabs").addEventListener("click", (event) => {
  const tab = event.target.closest("[role=tab]");
  if (tab) activateTab(tab);
});

document.querySelector(".tabs").addEventListener("keydown", (event) => {
  const tab = event.target.closest("[role=tab]");
  if (!tab) return;
  const index = tabs.indexOf(tab);
  let next = -1;
  if (event.key === "ArrowRight") next = (index + 1) % tabs.length;
  else if (event.key === "ArrowLeft") next = (index - 1 + tabs.length) % tabs.length;
  else if (event.key === "Home") next = 0;
  else if (event.key === "End") next = tabs.length - 1;
  if (next >= 0) {
    event.preventDefault();
    activateTab(tabs[next]);
  }
});

// Examples dropdown
document.getElementById("examples").addEventListener("change", (event) => {
  const key = event.target.value;
  if (key && EXAMPLES[key]) {
    monacoEditor.setValue(EXAMPLES[key]);
    monacoEditor.focus();
  }
});

// Share button
document.getElementById("share").addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(location.href);
    showToast("Link copied to clipboard");
  } catch {
    showToast("Copy the URL from the address bar");
  }
});

let toastTimeout = null;
function showToast(message) {
  if (toastTimeout) clearTimeout(toastTimeout);
  toast.textContent = message;
  toast.classList.add("visible");
  toastTimeout = setTimeout(() => toast.classList.remove("visible"), 2000);
}

// Shared toggle helper
function setToggleState(toggle, collapsed) {
  const treeitem = toggle.closest(".tree-node");
  const children = treeitem.nextElementSibling;
  if (!children || !children.classList.contains("tree-children")) return;
  children.classList.toggle("collapsed", collapsed);
  toggle.textContent = collapsed ? "▶" : "▼";
  treeitem.setAttribute("aria-expanded", String(!collapsed));
}

document.getElementById("collapse-all").addEventListener("click", () => {
  output.querySelectorAll(".tree-toggle").forEach(toggle => setToggleState(toggle, true));
});

document.getElementById("expand-all").addEventListener("click", () => {
  output.querySelectorAll(".tree-toggle").forEach(toggle => setToggleState(toggle, false));
});

// Monaco counts columns in utf-16 code units, which is what the code units
// columns report, so the two line up without any conversion here.
function formatLoc(loc, includeSlice) {
  if (!loc || loc.startOffset === undefined) return null;
  const start = { line: loc.startLine(), col: loc.startCodeUnitsColumn() };
  const end = { line: loc.endLine(), col: loc.endCodeUnitsColumn() };

  let text = `${start.line}:${start.col}-${end.line}:${end.col}`;

  if (includeSlice) {
    text = `${text} = <span class="tree-string">${escapeHtml(JSON.stringify(loc.slice()))}</span>`
  }
  return { start, end, text };
}

function locDataAttrs(loc) {
  if (!loc) return "";
  return ` data-sl="${loc.start.line}" data-sc="${loc.start.col}" data-el="${loc.end.line}" data-ec="${loc.end.col}"`;
}

// Highlight a range in Monaco
function highlightRange(startLine, startCol, endLine, endCol) {
  currentDecorations = monacoEditor.deltaDecorations(currentDecorations, [{
    range: new monaco.Range(startLine, startCol + 1, endLine, endCol + 1),
    options: {
      className: "prism-highlight",
      isWholeLine: false
    }
  }]);
}

function clearHighlight() {
  currentDecorations = monacoEditor.deltaDecorations(currentDecorations, []);
}

// Detect whether a value is a Prism AST node (class instance with location)
function isNode(value) {
  return value && typeof value === "object" && !Array.isArray(value) && value.location && value.constructor && value.constructor.name !== "Object";
}

function isString(value) {
  return value && typeof value === "object" && Object.hasOwn(value, "encoding")
}

function isConstant(value) {
  return typeof value === "string";
}

// Get the node type name from the class name
function nodeType(node) {
  return node.constructor?.name || "Unknown";
}

// Get the enumerable field names, skipping internal ones
const SKIP_FIELDS = new Set(["nodeID", "location", "flags"]);
function nodeFields(node) {
  const fields = [];
  for (const key of Object.getOwnPropertyNames(node)) {
    if (!SKIP_FIELDS.has(key) && !key.startsWith("#")) fields.push(key);
  }
  return fields;
}

// Decode flags by calling is*() predicate methods on the node's prototype
const flagNamesCache = new WeakMap();
function flagPredicateNames(proto) {
  let names = flagNamesCache.get(proto);
  if (!names) {
    names = Object.getOwnPropertyNames(proto).filter(n => n.startsWith("is") && typeof proto[n] === "function");
    flagNamesCache.set(proto, names);
  }
  return names;
}

function activeFlags(node) {
  const proto = Object.getPrototypeOf(node);
  if (!proto) return [];
  const flags = [];
  for (const name of flagPredicateNames(proto)) {
    try { if (node[name]()) flags.push(name.slice(2)); } catch (e) {}
  }
  return flags;
}

// Check if a node has child nodes (not just scalar fields)
function hasChildNodes(fields, node) {
  for (const field of fields) {
    const value = node[field];
    if (isNode(value)) return true;
    if (Array.isArray(value) && value.some(isNode)) return true;
  }
  return false;
}

const CONNECTOR = { last: "└── ", mid: "├── ", lastPad: "    ", midPad: "│   " };

// Build the AST tree as interactive HTML
function renderNode(node, prefix, isLast, isRoot) {
  if (!isNode(node)) return "";

  const type = nodeType(node);
  const childPrefix = isRoot ? "" : prefix + (isLast ? CONNECTOR.lastPad : CONNECTOR.midPad);
  const fields = nodeFields(node);
  const foldable = hasChildNodes(fields, node);
  const escapedType = escapeHtml(type);

  let html = `<div class="tree-node" role="treeitem" aria-label="${escapedType}"${foldable ? ' aria-expanded="true"' : ""}>`;
  if (!isRoot) html += `<span class="tree-connector" aria-hidden="true">${prefix}${isLast ? CONNECTOR.last : CONNECTOR.mid}</span>`;
  if (foldable) html += `<button class="tree-toggle" aria-label="Toggle ${escapedType}">▼</button>`;

  const loc = formatLoc(node.location, false);
  const locAttrs = locDataAttrs(loc);

  html += `<span class="tree-type"${locAttrs}>@ ${escapedType}</span>`;
  if (loc) html += ` <span class="tree-loc"${locAttrs}>(location: ${loc.text})</span>`;
  html += `</div>`;

  html += `<div class="tree-children" role="group">`;
  const flags = activeFlags(node);
  const hasFields = fields.length > 0;
  if (flags.length > 0) {
    const flagConnector = hasFields ? CONNECTOR.mid : CONNECTOR.last;
    html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${flagConnector}</span><span class="tree-field">flags</span>: ${flags.map(f => `<span class="tree-flag">${escapeHtml(f)}</span>`).join(" ")}</div>`;
  }
  fields.forEach((field, idx) => {
    const value = node[field];
    const fieldIsLast = idx === fields.length - 1;
    const fieldConnector = fieldIsLast ? CONNECTOR.last : CONNECTOR.mid;
    const fieldChildPrefix = childPrefix + (fieldIsLast ? CONNECTOR.lastPad : CONNECTOR.midPad);

    if (value === null || value === undefined) {
      html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>: <span class="tree-null">∅</span></div>`;
    } else if (Array.isArray(value)) {
      if (value.length === 0) {
        html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>: []</div>`;
      } else {
        html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>: (${value.length} item${value.length === 1 ? "" : "s"})</div>`;
        value.forEach((item, i) => {
          if (isNode(item)) {
            html += renderNode(item, fieldChildPrefix, i === value.length - 1);
          } else {
            const itemConnector = i === value.length - 1 ? CONNECTOR.last : CONNECTOR.mid;
            if (isConstant(item)) {
              html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${fieldChildPrefix}${itemConnector}</span><span class="tree-constant">:${escapeHtml(item)}</span></div>`;
            } else {
              html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${fieldChildPrefix}${itemConnector}</span><span class="tree-value">${escapeHtml(JSON.stringify(item))}</span></div>`;
            }
          }
        });
      }
    } else if (isNode(value)) {
      html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>:</div>`;
      html += renderNode(value, fieldChildPrefix, true);
    } else if (typeof value === "object" && value.startOffset !== undefined) {
      const fieldLoc = formatLoc(value, true);
      if (fieldLoc) {
        html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>: <span class="tree-loc"${locDataAttrs(fieldLoc)}>${fieldLoc.text}</span></div>`;
      }
    } else if (isString(value)) {
      html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>: <span class="tree-string">${escapeHtml(JSON.stringify(value.value))}</span></div>`;
    } else if (isConstant(value)) {
      html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>: <span class="tree-constant">:${escapeHtml(value)}</span></div>`;
    } else if (typeof value === "number"){
      html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>: <span class="tree-number">${value}</span></div>`;
    } else {
      // Should not reach
      html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>: <span class="tree-value">${escapeHtml(String(value))}</span></div>`;
    }
  });
  html += `</div>`;

  return html;
}

const ESCAPE_MAP = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" };
function escapeHtml(str) {
  return str.replace(/[&<>"]/g, ch => ESCAPE_MAP[ch]);
}

// Render a single diagnostic line
function renderDiagnostic(item, kind) {
  const loc = formatLoc(item.location, false);
  const cssClass = kind === "Error" ? "error-text" : "warning-text";
  return `<div class="diagnostics-line ${cssClass}"${locDataAttrs(loc)}>${kind}: ${escapeHtml(item.message)}${loc ? ` <span class="tree-loc">(${loc.text})</span>` : ""}</div>`;
}

// Delegated event handlers on #output (attached once, survive re-renders)
output.addEventListener("click", (event) => {
  const toggle = event.target.closest(".tree-toggle");
  if (toggle) {
    const treeitem = toggle.closest(".tree-node");
    const collapsed = treeitem.getAttribute("aria-expanded") === "true";
    setToggleState(toggle, collapsed);
    return;
  }

  const locEl = event.target.closest("[data-sl]");
  if (locEl) {
    const sl = parseInt(locEl.dataset.sl);
    const sc = parseInt(locEl.dataset.sc);
    monacoEditor.revealLineInCenter(sl);
    monacoEditor.setPosition({ lineNumber: sl, column: sc + 1 });
    monacoEditor.focus();
  }
});

output.addEventListener("mouseenter", (event) => {
  const locEl = event.target.closest("[data-sl]");
  if (!locEl) return;
  highlightRange(parseInt(locEl.dataset.sl), parseInt(locEl.dataset.sc), parseInt(locEl.dataset.el), parseInt(locEl.dataset.ec));
  (locEl.closest(".tree-node") || locEl).classList.add("tree-highlight");
}, true);

output.addEventListener("mouseleave", (event) => {
  const locEl = event.target.closest("[data-sl]");
  if (!locEl) return;
  clearHighlight();
  (locEl.closest(".tree-node") || locEl).classList.remove("tree-highlight");
}, true);


function render() {
  if (!lastResult) return;

  output.setAttribute("aria-labelledby", currentTab === "ast" ? "tab-ast" : "tab-diagnostics");

  const notice = lastNotice ? `<div class="diagnostics-line warning-text">${escapeHtml(lastNotice)}</div>` : "";

  switch (currentTab) {
    case "ast":
      const tree = renderNode(lastResult.value, "", true, true);
      output.innerHTML = notice + (tree
        ? `<div role="tree" aria-label="Abstract syntax tree">${tree}</div>`
        : `<div class="empty-message error-text">${escapeHtml(lastResult.error || "Failed to parse.")}</div>`);
      break;

    case "diagnostics":
      const errors = lastResult.errors || [];
      const warnings = lastResult.warnings || [];
      if (errors.length === 0 && warnings.length === 0) {
        output.innerHTML = notice || `<div class="empty-message">No errors or warnings.</div>`;
      } else {
        let html = notice;
        for (const err of errors) html += renderDiagnostic(err, "Error");
        for (const warn of warnings) html += renderDiagnostic(warn, "Warning");
        output.innerHTML = html;
      }
      break;
  }
}

let timeout = null;
function parse() {
  if (timeout) clearTimeout(timeout);
  timeout = setTimeout(() => {
    const source = monacoEditor.getValue();

    /* The hash carries the editor's text, which is independent of the encoding
     * the source declares, so it stays utf-8. */
    history.replaceState(null, "", `#${encodeSource(encoder.encode(source))}`);

    try {
      const { bytes, notice } = sourceBytes(source);
      lastNotice = notice || null;
      lastResult = parsePrism(instance.exports, bytes);
    } catch (e) {
      lastNotice = null;
      lastResult = { value: null, error: e.message, errors: [], warnings: [] };
    }
    render();
  }, 200);
}

monacoEditor.onDidChangeModelContent(parse);

// Ready
loading.classList.add("hidden");
editorDiv.classList.add("ready");
parse();
