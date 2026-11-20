import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ms } from "./fixtures.mjs";
const L = load("lanes.js");
const occ = (n) => ({ ...n, seriesId: n.id, occ: n.startTime });
test("lanes: one column per venue, a 'No venue' column last, nights on their day", () => {
  const occs = [occ(night("a", { venue: "Damas", start: ms(2026, 11, 25, 22) })), occ(night("b", { venue: "Lounge", start: ms(2026, 11, 21, 23) })),
                occ(night("c", { venue: "", start: ms(2026, 11, 22, 17) })), occ(night("d", { venue: "Damas", start: ms(2026, 12, 20, 22) }))];
  const g = L.buildLanes(occs, "venue", ms(2026, 11, 16), 14, []);
  assert.equal(g.lanes.map((l) => l.label).sort().join(), "Damas,Lounge,No venue");
  assert.equal(g.lanes[g.lanes.length - 1].id, "—");
  assert.equal(g.days.length, 14);
  const row = g.days.findIndex((d) => d.date === ms(2026, 11, 25));
  assert.equal(g.days[row].cells[g.lanes.findIndex((l) => l.id === "Damas")][0].id, "a");
  assert.equal(g.days.flatMap((d) => d.cells.flat()).length, 3);          // d is outside the window
});
test("lanes: status lanes are always the three, in order", () => {
  const g = L.buildLanes([], "status", ms(2026, 11, 16), 7, []);
  assert.equal(g.lanes.map((l) => l.id).join(), "Hold,Confirmed,Cancelled");
});
