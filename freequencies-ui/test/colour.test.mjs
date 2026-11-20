import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night } from "./fixtures.mjs";
const C = load("colour.js");
const pal = { hold: "H", confirmed: "C", cancelled: "X", faint: "F", swatch: ["s0", "s1", "s2", "s3"] };
test("colour: by status, type, venue, calendar", () => {
  const n = night("a", { status: "Confirmed", type: "Concert", venue: "Damas" });
  assert.equal(C.nightColor(n, "status", pal, "cal", true), "C");
  assert.equal(C.nightColor(n, "type", pal, "cal", true), "s1");
  assert.equal(C.nightColor(n, "venue", pal, "cal", true), C.nightColor(night("b", { venue: " damas " }), "venue", pal, "cal", true));
  assert.equal(C.nightColor(n, "calendar", pal, "cal", true), "cal");
  assert.equal(C.nightColor(n, "status", pal, "cal", false), "cal");
  assert.equal(C.nightColor(night("c", { venue: "" }), "venue", pal, "cal", true), "F");
});
test("colour: legend follows the mode", () => {
  assert.equal(C.legend("status", pal, [], [], null).map((x) => x.color).join(), "H,C,X");
  assert.equal(C.legend("venue", pal, ["Damas", "Lounge"], [], null).length, 2);
});
