import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext, ms } from "./fixtures.mjs";
const V = load("venues.js"), A = load("analytics.js");
const now = ms(2026, 11, 20, 12);
const ns = [
  night("a", { venue: "Damas", status: "Confirmed", start: ms(2026, 11, 25, 17), ext: [ext("tickets", "a", { sold: 142, price: 0 }), ext("artist", "a", { name: "Oseias", fee: 300, status: "confirmed" }), ext("tags", "a", { tags: ["talk"] })] }),
  night("b", { venue: "damas ", start: ms(2026, 10, 7, 18), rsvps: { x: "going", y: "maybe" } }),
  night("c", { venue: "Lounge", status: "Cancelled", start: ms(2026, 11, 22, 17) }),
];
test("venues: one per name, nights, next and last, attendance", () => {
  const vs = V.venues(ns, now, () => "Freequencies");
  assert.equal(vs[0].name, "Damas"); assert.equal(vs[0].nights, 2); assert.equal(vs[0].upcoming, 1);
  assert.equal(vs[0].attendance, 143); assert.equal(vs[0].next, ms(2026, 11, 25, 17)); assert.equal(vs[1].attendance, 0);
});
test("analytics: per month and totals; cancelled counted apart", () => {
  const occs = ns.map((n) => ({ ...n, seriesId: n.id, occ: n.startTime }));
  const s = A.stats(occs, (o) => ns.find((n) => n.id === o.seriesId), now, 5, 2);
  assert.equal(s.months.length, 8);
  assert.equal(s.tot.nights, 2); assert.equal(s.tot.cancelled, 1); assert.equal(s.tot.attendance, 143);
  assert.equal(s.tot.profit, -300); assert.equal(s.tot.artists, 1);
  assert.equal(s.tags[0].label, "talk"); assert.equal(s.venues[0].n, 1);
  assert.equal(s.months[5].nights, 1);                      // November
});
