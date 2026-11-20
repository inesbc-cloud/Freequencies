import assert from "node:assert/strict";
import { load, plain } from "./load.mjs";
const F = load("funding.js");
const NS = "xyz.freequencies";
const day = (s) => new Date(s + "T12:00:00").getTime();

test("funding: a calendar is a Funding calendar by its marker field", () => {
  assert.equal(F.isFundingCal({ schema: [] }), false);
  const sc = F.fundingSchema([{ key: "x", type: "text" }]);
  assert.equal(F.isFundingCal({ schema: sc }), true);
  assert.equal(F.fundingSchema(sc).length, 2);
});
test("funding: the oldest anchor wins", () => {
  const a = F.anchorEvent();
  const evs = [{ ...a, id: "b", calendarId: "c", startTime: a.startTime }, { ...a, id: "a", calendarId: "c" },
               { ...a, id: "z", calendarId: "other" }, { id: "n", calendarId: "c", fields: {} }];
  assert.equal(F.anchorOf(evs, "c").id, "a");
  assert.equal(F.anchorOf(evs, "none"), null);
});
test("funding: application data is checked and cleaned", () => {
  assert.match(F.appData({ funder: "DGArtes" }).error, /project/);
  assert.match(F.appData({ title: "X" }).error, /funded/);
  assert.match(F.appData({ title: "X", funder: "Y", year: "25" }).error, /Year/);
  assert.match(F.appData({ title: "X", funder: "Y", url: "ftp://x" }).error, /https/);
  const r = F.appData({ title: " Sound  walks ", funder: "Gulbenkian", year: "2025", amount: "15 000", area: "Music",
    docs: [{ cid: "cid1", name: "application.pdf" }, { name: "no cid" }] });
  assert.deepEqual(plain(r.data), { title: "Sound walks", funder: "Gulbenkian", year: 2025, amount: 15000, currency: "EUR",
    area: "Music", docs: [{ cid: "cid1", name: "application.pdf" }] });
  assert.equal(F.amountLabel(r.data), "15 000 EUR");
});
test("funding: links need a name and an http(s) link", () => {
  assert.match(F.linkData({ url: "https://x.pt" }).error, /Name/);
  assert.match(F.linkData({ name: "X", url: "x.pt" }).error, /https/);
  assert.match(F.linkData({ name: "X", url: "https://x.pt", deadline: "2027-02-31" }).error, /Deadline/);
  assert.deepEqual(plain(F.linkData({ name: "X", url: "https://x.pt", deadline: "2027-01-31", rolling: false }).data),
    { name: "X", url: "https://x.pt", deadline: "2027-01-31" });
});
test("funding: deadlines and sorting (open soonest first, closed last)", () => {
  const now = day("2026-11-20");
  assert.equal(F.deadlineState({ deadline: "2026-11-25" }, now), "soon");
  assert.equal(F.deadlineState({ deadline: "2027-03-01" }, now), "open");
  assert.equal(F.deadlineState({ deadline: "2026-11-01" }, now), "closed");
  assert.equal(F.deadlineState({ rolling: true }, now), "open");
  assert.equal(F.daysLeft({ deadline: "2026-11-21" }, now), 2);
  const it = (id, data) => ({ ns: NS, kind: "fund-link", id, data: { url: "https://x.pt", ...data } });
  const anchor = { ext: [it("1", { name: "Closed", deadline: "2026-10-01" }), it("2", { name: "Later", deadline: "2027-05-01" }),
    it("3", { name: "Rolling", rolling: true }), it("4", { name: "Soon", deadline: "2026-11-30" }), it("5", { name: "Bad", url: "x" })] };
  assert.deepEqual(plain(F.linksOf(anchor, now).map((x) => x.d.name)), ["Soon", "Later", "Rolling", "Closed"]);
});
test("funding: applications newest year first; search by any word", () => {
  const it = (id, data) => ({ ns: NS, kind: "fund-app", id, data });
  const anchor = { ext: [it("1", { title: "Old", funder: "A", year: 2019 }), it("2", { title: "New", funder: "Gulbenkian", year: 2025, area: "Music" }), it("3", { funder: "no title" })] };
  const apps = F.appsOf(anchor);
  assert.deepEqual(plain(apps.map((x) => x.d.title)), ["New", "Old"]);
  assert.equal(F.matches(apps[0], "gulben music"), true);
  assert.equal(F.matches(apps[0], "2025"), true);
  assert.equal(F.matches(apps[1], "gulben"), false);
  assert.equal(F.matches(apps[1], ""), true);
});
test("funding: a document is available while it's still attached", () => {
  const anchor = { attachments: [{ storageCid: "c1" }] };
  assert.equal(F.docAvailable(anchor, "c1"), true);
  assert.equal(F.docAvailable(anchor, "c2"), false);
});
