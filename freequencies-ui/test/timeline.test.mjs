import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { ms } from "./fixtures.mjs";
const T = load("timeline.js");
test("timeline: by month, in order; past is newest first", () => {
  const o = (d, m) => ({ startTime: ms(2026, m, d), id: m + "-" + d });
  const occs = [o(25, 11), o(7, 10), o(21, 11), o(17, 12)];
  assert.equal(T.group(occs, false).map((g) => g.occs.map((x) => x.id).join("+")).join(" | "), "10-7 | 11-21+11-25 | 12-17");
  assert.equal(T.group(occs, true)[0].occs[0].id, "12-17");
  const w = T.window_(ms(2026, 11, 20, 15), false); assert.equal(w[0], ms(2026, 11, 20)); assert.equal(w[1], ms(2027, 11, 20));
});
