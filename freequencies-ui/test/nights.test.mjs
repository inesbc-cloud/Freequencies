import assert from "node:assert/strict";
import { load } from "./load.mjs";
const N = load("nights.js");
const me = "0xme";
const cal = (o = {}) => ({ id: "c", owner: me, authorAddr: me, roles: {}, schema: [], ...o });

test("nights: a calendar with the Freequencies status field is a Freequencies calendar", () => {
  assert.equal(N.isFreqCal(cal({ schema: N.freqFields })), true);
  assert.equal(N.isFreqCal(cal()), false);
  assert.equal(N.isFreqCal(cal({ schema: [{ key: "status", type: "enum", options: ["Hold", "Confirmed"] }] })), false);
});
test("nights: adopting keeps the calendar's own fields and adds the three", () => {
  const s = N.adoptedSchema([{ key: "door", type: "number" }, { key: "venue", type: "text", label: "Where" }]);
  assert.deepEqual(s.map((f) => f.key), ["door", "venue", "status", "type"]);
  assert.equal(s[1].label, "Where");
});
test("nights: adoptBlocker explains why not", () => {
  assert.equal(N.adoptBlocker(cal()), "");
  assert.match(N.adoptBlocker(cal({ owner: "0xother" })), /owner or editors/);
  assert.equal(N.adoptBlocker(cal({ owner: "0xother", roles: { [me]: "editor" } })), "");
  assert.match(N.adoptBlocker(cal({ schema: [{ key: "status", type: "text" }] })), /its own “status”/);
  assert.match(N.adoptBlocker(cal({ schema: [{ key: "venue", type: "number" }] })), /“venue”/);
});
test("nights: roles and edit rights", () => {
  assert.equal(N.roleOf(cal()), "owner");
  assert.equal(N.roleOf(cal({ owner: "x", roles: { [me]: "viewer" } })), "viewer");
  const ev = { creatorId: "x" };
  assert.equal(N.canEdit(ev, cal({ owner: "x", collab: true })), true);
  assert.equal(N.canEdit(ev, cal({ owner: "x", roles: { [me]: "viewer" }, collab: true })), false);
  assert.equal(N.canEdit({ creatorId: me }, cal({ owner: "x" })), true);
});
