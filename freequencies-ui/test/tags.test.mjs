import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext } from "./fixtures.mjs";
const T = load("tags.js");
test("tags: cleaned, deduplicated, newest value wins", () => {
  const n = night("a", { ext: [ext("tags", "a", { tags: ["Techno", " techno", "", 5, "Live"] }, { wall: 9 }), ext("tags", "a", { tags: ["old"] }, { wall: 2 })] });
  assert.equal(T.tagsOf(n).join(), "techno,live");
  assert.equal(T.withTag(n, "Workshop").join(), "techno,live,workshop");
  assert.equal(T.withoutTag(n, "LIVE").join(), "techno");
  assert.equal(T.allTags([n, night("b", { ext: [ext("tags", "b", { tags: ["ambient"] })] })]).join(), "ambient,live,techno");
  assert.ok(!T.suggestions(n, [], 9).includes("techno"));
});
