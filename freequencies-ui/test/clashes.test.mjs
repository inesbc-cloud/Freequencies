import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext, ms } from "./fixtures.mjs";
const C = load("clashes.js");
const occ = (n) => ({ ...n, seriesId: n.id, occ: n.startTime });
test("clashes: same venue overlapping, same artist same day, across calendars; cancelled never", () => {
  const a = occ(night("a", { venue: "Damas", start: ms(2026, 11, 25, 17), end: ms(2026, 11, 25, 23), ext: [ext("artist", "a", { name: "Post Carbon", status: "asked" })] }));
  const b = occ(night("b", { cal: "other", venue: " damas", start: ms(2026, 11, 25, 21), end: ms(2026, 11, 26, 1), ext: [ext("artist", "b", { name: "post carbon" })] }));
  const c = occ(night("c", { venue: "Lounge", start: ms(2026, 11, 25, 9), end: ms(2026, 11, 25, 10), ext: [ext("crew", "c", { name: "Post Carbon", role: "Door" })] }));
  const d = occ(night("d", { status: "Cancelled", venue: "Damas", start: ms(2026, 11, 25, 18), end: ms(2026, 11, 25, 22) }));
  const m = C.clashes([a, b, c, d]);
  assert.equal(m[C.occKey(a)].map((x) => x.kind + ":" + x.other.id).sort().join(), "person:b,person:c,venue:b");
  assert.equal(m[C.occKey(d)], undefined);
  assert.match(C.line(m[C.occKey(a)][0], "25 Nov"), /^⚠ /);
});
