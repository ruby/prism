import { WASI } from "https://unpkg.com/@bjorn3/browser_wasi_shim@latest/dist/index.js";
import { parsePrism } from "https://unpkg.com/@ruby/prism@latest/src/parsePrism.js";

const output = document.getElementById("output");
const editorDiv = document.getElementById("editor");
const loading = document.getElementById("loading");
const toast = document.getElementById("toast");

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
function encodeSource(str) {
  const bytes = new TextEncoder().encode(str);
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function decodeSource(str) {
  const padded = str.replace(/-/g, "+").replace(/_/g, "/") + "==".slice(0, (4 - str.length % 4) % 4);
  return new TextDecoder().decode(Uint8Array.from(atob(padded), ch => ch.codePointAt(0)));
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
let lastSource = "";
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

// Convert byte offset to line:column using the source string
function offsetToLineCol(source, offset) {
  let line = 1, col = 0;
  for (let i = 0; i < offset && i < source.length; i++) {
    if (source[i] === "\n") { line++; col = 0; }
    else { col++; }
  }
  return { line, col };
}


function formatLoc(source, loc) {
  if (!loc || loc.startOffset === undefined) return null;
  const start = offsetToLineCol(source, loc.startOffset);
  const end = offsetToLineCol(source, loc.startOffset + loc.length);
  return { start, end, text: `${start.line}:${start.col}-${end.line}:${end.col}` };
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
function renderNode(node, source, prefix, isLast, isRoot) {
  if (!isNode(node)) return "";

  const type = nodeType(node);
  const childPrefix = isRoot ? "" : prefix + (isLast ? CONNECTOR.lastPad : CONNECTOR.midPad);
  const fields = nodeFields(node);
  const foldable = hasChildNodes(fields, node);
  const escapedType = escapeHtml(type);

  let html = `<div class="tree-node" role="treeitem" aria-label="${escapedType}"${foldable ? ' aria-expanded="true"' : ""}>`;
  if (!isRoot) html += `<span class="tree-connector" aria-hidden="true">${prefix}${isLast ? CONNECTOR.last : CONNECTOR.mid}</span>`;
  if (foldable) html += `<button class="tree-toggle" aria-label="Toggle ${escapedType}">▼</button>`;

  const loc = formatLoc(source, node.location);
  const locAttrs = locDataAttrs(loc);

  html += `<span class="tree-type"${locAttrs}>@ ${escapedType}</span>`;
  if (loc) html += ` <span class="tree-loc"${locAttrs}>(${loc.text})</span>`;
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
            html += renderNode(item, source, fieldChildPrefix, i === value.length - 1);
          } else {
            const itemConnector = i === value.length - 1 ? CONNECTOR.last : CONNECTOR.mid;
            html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${fieldChildPrefix}${itemConnector}</span><span class="tree-value">${escapeHtml(JSON.stringify(item))}</span></div>`;
          }
        });
      }
    } else if (isNode(value)) {
      html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>:</div>`;
      html += renderNode(value, source, fieldChildPrefix, true);
    } else if (typeof value === "object" && value.startOffset !== undefined) {
      const fieldLoc = formatLoc(source, value);
      if (fieldLoc) {
        html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>: <span class="tree-loc"${locDataAttrs(fieldLoc)}>${fieldLoc.text}</span></div>`;
      }
    } else if (typeof value === "string") {
      html += `<div class="tree-node"><span class="tree-connector" aria-hidden="true">${childPrefix}${fieldConnector}</span><span class="tree-field">${escapeHtml(field)}</span>: <span class="tree-string">${escapeHtml(JSON.stringify(value))}</span></div>`;
    } else {
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
function renderDiagnostic(source, item, kind) {
  const loc = formatLoc(source, item.location);
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

  switch (currentTab) {
    case "ast":
      const tree = renderNode(lastResult.value, lastSource, "", true, true);
      output.innerHTML = tree
        ? `<div role="tree" aria-label="Abstract syntax tree">${tree}</div>`
        : `<div class="empty-message error-text">${escapeHtml(lastResult.error || "Failed to parse.")}</div>`;
      break;

    case "diagnostics":
      const errors = lastResult.errors || [];
      const warnings = lastResult.warnings || [];
      if (errors.length === 0 && warnings.length === 0) {
        output.innerHTML = `<div class="empty-message">No errors or warnings.</div>`;
      } else {
        let html = "";
        for (const err of errors) html += renderDiagnostic(lastSource, err, "Error");
        for (const warn of warnings) html += renderDiagnostic(lastSource, warn, "Warning");
        output.innerHTML = html;
      }
      break;
  }
}

let timeout = null;
function parse() {
  if (timeout) clearTimeout(timeout);
  timeout = setTimeout(() => {
    lastSource = monacoEditor.getValue();
    history.replaceState(null, "", `#${encodeSource(lastSource)}`);
    try {
      lastResult = parsePrism(instance.exports, lastSource);
    } catch (e) {
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
