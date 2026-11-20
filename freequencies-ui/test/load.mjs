// Load a QML JavaScript library (qml/fq/lib/*.js, ".pragma library") into Node, the way QML would:
// `.import "x.js" as X` lines become a binding X to that library. No Qt APIs are used in fq/lib.
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";
const LIB = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "qml", "fq", "lib");
const cache = new Map();
export function load(name) {
  if (cache.has(name)) return cache.get(name);
  let src = fs.readFileSync(path.join(LIB, name), "utf8");
  const ctx = vm.createContext({ console, Math, JSON, Date, Number, String, Object, Array, isFinite, isNaN });
  src = src.replace(/^\s*\.pragma library\s*$/m, "").replace(/^\s*\.import\s+"([^"]+)"\s+as\s+(\w+)\s*$/gm, (_, f, as) => {
    ctx[as] = load(f); return "";
  });
  vm.runInContext(src, ctx, { filename: name });
  cache.set(name, ctx);
  return ctx;
}
