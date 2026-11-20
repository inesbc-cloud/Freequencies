import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { load, plain } from "./load.mjs";
import { night, ext, ms } from "./fixtures.mjs";
const P = load("publiccopy.js");

const fixtures = () => {
  const pub = (id, cal, wall) => ext("public", id, { calendar: cal }, { id: "public:" + id + ":" + wall, wall });
  return [
    night("n1", { title: "Freequencies 02", status: "Confirmed", venue: " Damas ", ext: [
      ext("artist", "n1", { name: "Oseias", set: "21:15", status: "confirmed", fee: 300 }), ext("artist", "n1", { name: "Late", set: "01:00", status: "confirmed" }),
      ext("artist", "n1", { name: "Maybe", status: "asked" }), ext("form", "n1", { formId: "f", uri: "wb://g", purpose: "guestlist" }),
      ext("budget", "n1", { label: "secret", amount: 1 }), pub("n1", "cal-pub", 5), pub("n1", "cal-other", 3)] }),
    night("n2", { title: "  ", status: "Cancelled", ext: [pub("n2", "cal-pub", 1)], recur: { freq: "weekly", interval: 2 } }),
    night("n3", { title: "Hold night", status: "Hold", venue: "Lounge" }),
  ];
};
test("public copy: only what attendees may see", () => {
  const [n1, n2] = fixtures();
  const c = P.publicCopyOf(n1, true);
  assert.equal(c.description, "Line-up:\n21:15  Oseias\n01:00  Late\n\nGuest list: wb://g");
  assert.equal(c.location, "Damas");
  assert.equal(P.publicLinkOf(n1).calendar, "cal-other");          // the earliest switch wins
  assert.equal(P.publicCopyOf(n2, true).title, "Cancelled: Untitled night");
});
test("public copy: the same as Android's publish.ts (golden; needs node --experimental-strip-types)", async () => {
  let A;
  try { A = await import(pathToFileURL(path.join(path.dirname(fileURLToPath(import.meta.url)), "../../mobile/src/app/publish.ts"))); }
  catch (e) { console.log("     (skipped: run with node --experimental-strip-types to compare with Android)"); return; }
  const ns = fixtures();
  const all = [{ id: "pub-n1", calendarId: "cal-pub", title: "old" }, { id: "pub-n3", calendarId: "cal-pub", title: "Hold night" }];
  for (const n of ns) assert.deepEqual(plain(P.publicLinkOf(n)), plain(A.publicLinkOf(n)));
  for (const n of ns) for (const pubd of [true, false]) assert.deepEqual(plain(P.publicCopyOf(n, pubd)), plain(A.publicCopyOf(n, pubd)));
  const isT = (c) => c !== "cal-freq";
  assert.deepEqual(plain(P.mirrorPlan(ns, all, isT)), plain(A.mirrorPlan(ns, all, isT)));
  for (const n of ns) assert.deepEqual(plain(P.copyToEvent(P.publicCopyOf(n, true))), plain(A.copyToEvent(A.publicCopyOf(n, true))));
});
