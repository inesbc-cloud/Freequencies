import assert from "node:assert/strict";
import { load, plain } from "./load.mjs";
const R = load("reports.js");
const D = load("deal.js");
const NS = "xyz.freequencies";
let w = 1;
const it = (kind, data, id) => ({ ns: NS, kind, id: id || kind + ":" + w, author: "0xa", hlc: { wall: w++ }, data });
const DAY = 86400000;

test("reports: an event's result — money, audience, break-even, vs expected", () => {
  const ev = { startTime: 1, fields: { status: "Confirmed", venue: "Damas" }, ext: [
    it("tickets", { sold: 150, capacity: 200, price: 10 }), it("budget", { label: "Sound", amount: 500, dir: "out" }),
    it("artist", { name: "A", fee: 300, status: "confirmed" }), it("artist", { name: "B", status: "asked" }),
    it("details", { audience: "150–300" })] };
  const r = R.eventResult(ev);
  assert.equal(r.income, 1500); assert.equal(r.costs, 800); assert.equal(r.profit, 700);
  assert.equal(r.attendance, 150); assert.equal(r.fill, 0.75); assert.equal(r.breakEven, 80);
  assert.equal(r.artistsPaid, 1); assert.equal(r.expected, 225);
  assert.equal(R.expectedOf("600+"), 600); assert.equal(R.expectedOf("Under 50"), 40);
});
test("reports: a collective's year with the funder numbers", () => {
  const e = (t, ext, f = {}) => ({ startTime: t, fields: { status: "Confirmed", venue: "Damas", ...f }, ext });
  const evs = [
    e(10, [it("artist", { name: "A", fee: 100, status: "confirmed", local: true, wnb: true }, "a1"), it("details", { free: true, access: "step-free" }), it("tickets", { sold: 80 })]),
    e(20, [it("artist", { name: "A", fee: 100, status: "confirmed", local: true, wnb: true }, "a2"), it("artist", { name: "C", status: "confirmed", first: true }, "c1")], { venue: "Lounge" }),
    e(30, [], { status: "Cancelled" }), e(9999, [])];
  const r = R.yearReport(evs, 0, 1000);
  assert.equal(r.events, 2); assert.equal(r.cancelled, 1); assert.equal(r.artists, 2);
  assert.equal(r.local, 1); assert.equal(r.wnb, 1); assert.equal(r.first, 1); assert.equal(r.paidArtists, 2);
  assert.equal(r.free, 1); assert.equal(r.accessible, 1); assert.equal(r.venues, 2); assert.equal(r.audience, 80);
  const txt = R.applicationText(r, "Freequencies", "2026");
  assert.match(txt, /Freequencies organised 2 events in 2026/);
  assert.match(txt, /Lisbon-based artists: 1 \(50%\)/);
});
test("reports: city pulse counts weekends and crowded nights", () => {
  const now = new Date(2026, 10, 23, 12).getTime(); // a Monday
  const fri = new Date(2026, 10, 27, 23).getTime();
  const evs = [0, 1, 2].map((i) => ({ startTime: fri + i * 3600000, title: "E" + i, fields: {} })).concat([{ startTime: fri + 7 * DAY, title: "Next", fields: {} }]);
  const p = R.cityPulse(evs, now, 4);
  assert.equal(p.weekends.length, 4); assert.equal(p.weekends[0].count, 3); assert.equal(p.weekends[1].count, 1);
  assert.equal(p.crowded.length, 1); assert.equal(p.quietest.count, 0);
});
test("deal: the four deal types, break-even and budget lines", () => {
  const base = { price: 10, capacity: 200, other: 0, costs: [{ label: "Venue", amount: 500 }, { label: "Sound", amount: 300 }] };
  const flat = D.parse({ ...base, type: "flat", fee: 400 }).data;
  assert.deepEqual(plain(D.at(flat, 1)), { fill: 1, tickets: 200, door: 2000, costs: 800, artist: 400, promoter: 800 });
  assert.equal(D.breakEven(flat), 120);
  const door = D.parse({ ...base, type: "door", pct: 50 }).data;
  assert.equal(D.at(door, 0.5).artist, 500);
  const plus = D.parse({ ...base, type: "plus", fee: 200, pct: 50 }).data;
  assert.equal(D.at(plus, 1).artist, 200 + (2000 - 800 - 200) * 0.5);
  const vs = D.parse({ ...base, type: "versus", fee: 300, pct: 70 }).data;
  assert.equal(D.at(vs, 0.25).artist, 300);
  assert.equal(D.at(vs, 1).artist, 1200 * 0.7);
  assert.equal(D.table(flat).length, 4);
  assert.deepEqual(plain(D.budgetLines(flat, 0.75, "DJ A").map((l) => l.label)), ["DJ A · Flat fee", "Venue", "Sound"]);
  assert.match(D.parse({ type: "flat", fee: "lots" }).error, /numbers/);
  assert.match(D.parse({ type: "door", pct: 150 }).error, /percentage/);
  assert.equal(D.breakEven(D.parse({ type: "flat", fee: 5000, price: 10, capacity: 100 }).data), null);
});
test("deal: settlement between co-promoters, fewest transfers", () => {
  const s = D.settle({ partners: [{ name: "Freq", share: 50 }, { name: "Damas", share: 30 }, { name: "Radio", share: 20 }],
    moves: [{ who: "Damas", kind: "took", amount: 2000 }, { who: "Freq", kind: "paid", amount: 600 }, { who: "Radio", kind: "paid", amount: 400 }] });
  assert.equal(s.result, 1000); assert.equal(s.sharesOk, true);
  const bal = Object.fromEntries(s.rows.map((r) => [r.name, Math.round(r.balance)]));
  assert.deepEqual(bal, { Freq: 1100, Damas: -1700, Radio: 600 });
  assert.deepEqual(plain(s.transfers), [{ from: "Damas", to: "Freq", amount: 1100 }, { from: "Damas", to: "Radio", amount: 600 }]);
  assert.equal(D.settle({ partners: [{ name: "A", share: 60 }], moves: [] }).sharesOk, false);
});

const N = load("network.js");
test("network: forms are checked against their specs", () => {
  assert.match(N.clean("venue", {}).error, /Fill in/);
  assert.deepEqual(plain(N.clean("venue", { name: " Damas ", capacity: "180", junk: 1 }).data), { name: "Damas", capacity: 180 });
  assert.match(N.clean("gear", { item: "CDJ", qty: "two", owner: "X" }).error, /number/);
  assert.deepEqual(plain(N.clean("crew", { name: "Ana", skills: ["Door", "Juggling", "Bar"] }).data), { name: "Ana", skills: ["Door", "Bar"] });
  assert.match(N.clean("poll", { q: "Which date?", options: "Fri" }).error, /two options/);
  assert.deepEqual(plain(N.clean("poll", { q: "Which date?", options: "Fri\nSat\nFri\n" }).data), { q: "Which date?", options: ["Fri", "Sat"] });
  assert.match(N.clean("poll", { q: "x", options: "a\nb", closes: "soon" }).error, /Dates/);
});
test("network: the oldest anchor; venues not yet in the directory; search", () => {
  const a = N.anchorEvent();
  assert.equal(N.anchorOf([{ ...a, id: "b", calendarId: "L" }, { ...a, id: "a", calendarId: "L" }], "L").id, "a");
  const dir = [{ d: { name: "Damas" } }];
  assert.deepEqual(plain(N.missingVenues(["damas ", "Lounge", ""], dir)), ["Lounge"]);
  const items = [{ d: { name: "Ana", skills: ["Door", "Bar"] } }, { d: { name: "Rui", skills: ["Sound"] } }];
  assert.deepEqual(plain(N.search(items, "bar").map((x) => x.d.name)), ["Ana"]);
});
test("network: borrowing gear — requests, the lender's latest answer, out on a day", () => {
  const anchor = { ext: [
    it("gear", { item: "CDJ", owner: "Freq" }, "g1"),
    it("borrow", { gear: "g1", who: "Radio", from: "2026-12-05", to: "2026-12-06" }, "b1"),
    it("borrow", { gear: "g1", who: "Damas", from: "2026-12-20" }, "b2"),
    it("reply", { borrow: "b1", status: "no" }), it("reply", { borrow: "b1", status: "ok" })] };
  const bs = N.borrowsOf(anchor, "g1");
  assert.deepEqual(plain(bs.map((b) => [b.id, b.status])), [["b1", "ok"], ["b2", "pending"]]);
  assert.equal(N.outOn(anchor, "g1", "2026-12-06"), true);
  assert.equal(N.outOn(anchor, "g1", "2026-12-20"), false);
});
test("network: polls count each person's newest vote", () => {
  const ev = { ext: [it("poll", { q: "Date?", options: ["Fri", "Sat"], closes: "2026-12-01" }, "p1"),
    { ns: NS, kind: "vote", id: "v1", author: "0xa", hlc: { wall: 100 }, data: { poll: "p1", choice: 0 } },
    { ns: NS, kind: "vote", id: "v2", author: "0xa", hlc: { wall: 101 }, data: { poll: "p1", choice: 1 } },
    { ns: NS, kind: "vote", id: "v3", author: "0xb", hlc: { wall: 102 }, data: { poll: "p1", choice: 1 } }] };
  const p = N.pollsOf(ev)[0];
  const t = N.tally(ev, p, "0xa", new Date(2026, 10, 20).getTime());
  assert.deepEqual(plain(t.counts), [0, 2]); assert.equal(t.total, 2); assert.equal(t.mine, 1); assert.equal(t.closed, false);
  assert.deepEqual(plain(t.leaders), [1]);
  assert.equal(N.tally(ev, p, "0xa", new Date(2026, 11, 2).getTime()).closed, true);
});

const L = load("legal.js");
test("legal: the legal-form guide recommends and explains", () => {
  assert.equal(L.recommendForm({ profit: true }).form, "company");
  assert.deepEqual(plain(L.recommendForm({ funding: true, contracts: true })), { form: "association", why: ["funding", "contracts"] });
  assert.equal(L.recommendForm({ money: "some" }).form, "association-later");
  assert.equal(L.recommendForm({ money: "none", people: "few" }).form, "informal");
});
test("legal: inspections log — cleaned, listed newest first, patterns, anonymised", () => {
  assert.match(L.cleanInspection({}).error, /who came/);
  const d = L.cleanInspection({ body: "ASAE", checked: ["Alcohol / food", "Magic"], outcome: "Fine", note: " x ", area: "Cais do Sodré", share: true }).data;
  assert.deepEqual(plain(d), { body: "ASAE", checked: ["Alcohol / food"], outcome: "Fine", note: "x", share: true, area: "Cais do Sodré" });
  const evs = [{ startTime: new Date(2026, 9, 3).getTime(), ext: [it("inspection", { body: "PSP", checked: ["Noise", "Licences"] })] },
               { startTime: new Date(2026, 10, 7).getTime(), ext: [it("inspection", d)] }];
  const list = L.inspectionsOf(evs);
  assert.deepEqual(plain(list.map((x) => x.d.body)), ["ASAE", "PSP"]);
  assert.deepEqual(plain(L.patterns(list).map((p) => [p.check, p.n])), [["Alcohol / food", 1], ["Licences", 1], ["Noise", 1]]);
  assert.deepEqual(plain(L.anonymised(list[0])), { month: "2026-11", area: "Cais do Sodré", body: "ASAE", checked: ["Alcohol / food"], outcome: "Fine" });
});
test("legal: lessons from debrief rows; bilingual text", () => {
  assert.match(L.lessonFrom({ cells: { topic: "Money" } }).error, /worked/);
  assert.deepEqual(plain(L.lessonFrom({ cells: { topic: "Money", worked: "Presale", change: "" } }, "club").data), { topic: "Money", worked: "Presale", change: "", format: "club" });
  assert.equal(L.txt({ en: "Hi", pt: "Olá" }, "pt"), "Olá"); assert.equal(L.txt("x", "pt"), "x"); assert.equal(L.txt(null), "");
});
