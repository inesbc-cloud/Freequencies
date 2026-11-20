import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext } from "./fixtures.mjs";
const P = load("poster.js");
test("poster: a link, an attachment, or nothing (an empty value clears it)", () => {
  assert.equal(P.sourceOf(night("a", { ext: [ext("poster", "a", { url: "https://x/p.png" })] })).src, "https://x/p.png");
  assert.equal(P.sourceOf(night("a", { ext: [ext("poster", "a", { cid: "c1" })] })).cid, "c1");
  assert.equal(P.sourceOf(night("a", { ext: [ext("poster", "a", { cid: "c1" }, { wall: 1 }), ext("poster", "a", {}, { wall: 2 })] })), null);
  assert.equal(P.sourceOf(night("a", { ext: [ext("poster", "a", { url: "javascript:x" })] })), null);
});
