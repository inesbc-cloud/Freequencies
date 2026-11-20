import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext } from "./fixtures.mjs";
const F = load("filters.js");
test("filters: combine status (several), type, tag, venue; search covers artists, crew, tags", () => {
  const a = night("a", { status: "Hold", type: "Concert", venue: "Damas", ext: [ext("tags", "a", { tags: ["live coding"] }), ext("artist", "a", { name: "Post Carbon" }), ext("crew", "a", { name: "Lola", role: "Door" })] });
  let f = F.empty();
  assert.equal(F.matches(a, f), true);
  f = F.withStatus(f, "Confirmed"); assert.equal(F.matches(a, f), false);
  f = F.withStatus(f, "Hold"); assert.equal(F.matches(a, f), true);
  f = F.with_(f, "venue", " damas"); assert.equal(F.matches(a, f), true);
  f = F.with_(f, "tag", "techno"); assert.equal(F.matches(a, f), false);
  f = F.with_(f, "tag", "techno"); assert.equal(f.tag, "");           // toggles off
  assert.match(F.extraHay(a), /Post Carbon.*Lola Door.*live coding/);
});
