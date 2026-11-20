import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext } from "./fixtures.mjs";
const E = load("ext.js"), L = load("lineup.js"), C = load("crew.js");

test("ext: newest item wins, whoever wrote it", () => {
  const n = night("a", { ext: [ext("tags", "a", { tags: ["x"] }, { wall: 5 }), ext("tags", "a", { tags: ["y"] }, { wall: 9, author: "0xother" }),
                               ext("tags", "a", { tags: ["z"] }, { wall: 7, ns: "scala" })] });
  assert.equal(E.latestData(n, "tags").tags.join(), "y");
  assert.equal(E.latestOf(night("b"), "tags"), null);
});
test("lineup: sorted by set time, bad fees dropped, unknown status is asked", () => {
  const n = night("a", { ext: [ext("artist", "a", { name: "B", set: "23:00", fee: 300, currency: "EUR", status: "confirmed" }),
                               ext("artist", "a", { name: "A", set: "21:00", fee: -5, status: "weird" }),
                               ext("artist", "a", { name: "  " })] });
  const lu = L.lineupOf(n);
  assert.equal(lu.map((b) => b.name).join(), "A,B");
  assert.equal(lu[0].fee, null); assert.equal(lu[0].status, "asked");
  assert.equal(L.feesTotal(lu), "300 EUR");
  assert.ok(L.setKey("01:00") > L.setKey("23:00"));
});
test("crew: slots, open slots, earliest check-in counts, no foreign check-ins", () => {
  const slot = ext("crew", "a", { name: "Lola", role: "Door", status: "confirmed", call: "16:30" }, { id: "crew1" });
  const n = night("a", { ext: [slot, ext("crew", "a", { role: "Bar" }, { id: "crew2" }),
    ext("checkin", "a", { crew: "crew1", at: 20 }, { id: "checkin:crew1:b" }), ext("checkin", "a", { crew: "crew1", at: 10 }, { id: "checkin:crew1:a" }),
    ext("checkin", "a", { crew: "crew2", at: 5 }, { id: "checkin:crew1:z" })] });
  const cr = C.crewOf(n);
  assert.equal(cr.length, 2);
  const lola = cr.find((c) => c.name === "Lola");
  assert.equal(lola.checkedIn.at, 10);
  assert.equal(cr.find((c) => c.role === "Bar").checkedIn, null);
  assert.equal(C.summaryLabel(C.summary(cr)), "1 on · 1 open · 1 here");
});
