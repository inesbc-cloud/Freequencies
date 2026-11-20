// node freequencies-ui/test/run.mjs — runs every *.test.mjs here.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
const here = path.dirname(fileURLToPath(import.meta.url));
const tests = [];
globalThis.test = (name, fn) => tests.push({ name, fn });
for (const f of fs.readdirSync(here).filter((f) => f.endsWith(".test.mjs")).sort())
  await import(pathToFileURL(path.join(here, f)));
let failed = 0;
for (const t of tests) {
  try { await t.fn(); console.log("ok   " + t.name); }
  catch (e) { failed++; console.log("FAIL " + t.name + "\n     " + (e && e.message)); }
}
console.log(`\n${tests.length - failed}/${tests.length} passed`);
process.exit(failed ? 1 : 0);
