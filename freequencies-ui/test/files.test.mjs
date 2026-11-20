import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext } from "./fixtures.mjs";
const F = load("files.js");
test("files: attachments, newest flag per file, images, sizes", () => {
  const n = { ...night("a", { ext: [ext("file", "a", { cid: "c1", visibility: "public" }, { wall: 5 }), ext("file", "a", { cid: "c1", visibility: "private" }, { wall: 3 })] }),
              attachments: [{ name: "poster.PNG", storageCid: "c1", size: 2048 }, { name: "rider.pdf", storageCid: "c2", mime: "application/pdf" }, { name: "x" }] };
  assert.equal(F.filesOf(n).length, 2);
  assert.equal(F.visibilityOf(n, "c1"), "public");
  assert.equal(F.visibilityOf(n, "c2"), "private");
  assert.equal(F.isImage(n.attachments[0]), true);
  assert.equal(F.humanSize(2048), "2.0 KB");
  assert.equal(F.without(n.attachments, "c1").length, 2);
});
