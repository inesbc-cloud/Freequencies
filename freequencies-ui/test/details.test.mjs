import assert from "node:assert/strict";
import { load, plain } from "./load.mjs";
const D = load("details.js");

test("details: line-up from commas or lines, trimmed and de-duplicated", () => {
  assert.deepEqual(plain(D.parseLineup("DJ A, dj a ;  Live B\n\nC  D")), ["DJ A", "Live B", "C D"]);
  assert.deepEqual(plain(D.parseLineup("")), []);
});
test("details: times in local time; a night ending before it starts ends the next day", () => {
  const t = D.timesOf("2026-11-28", "23:00", "05:00");
  assert.equal(new Date(t.start).getHours(), 23);
  assert.equal(new Date(t.end).getDate(), 29);
  assert.equal(new Date(t.end).getHours(), 5);
  const u = D.timesOf("2026-11-28", "2130", "");
  assert.equal(u.end - u.start, 4 * 3600000);
  assert.match(D.timesOf("2026-02-30", "22:00", "").error, /date/);
  assert.match(D.timesOf("2026-11-28", "25:00", "").error, /Start/);
  assert.match(D.timesOf("2026-11-28", "22:00", "late").error, /End/);
});
test("details: the quick form writes an event, artists and details", () => {
  const r = D.quickNight({ title: "  Noite  ", date: "2026-11-28", start: "22:00", end: "04:00", venue: "Desterro",
    lineup: "A, B", kind: "Club night", audience: "150–300", price: "8,5", age: "18+" });
  assert.equal(r.event.title, "Noite");
  assert.deepEqual(plain(r.event.fields), { status: "Hold", venue: "Desterro", type: "Club night" });
  assert.equal(r.event.location, "Desterro");
  assert.deepEqual(plain(r.items.map((i) => i.kind)), ["artist", "artist", "details"]);
  assert.deepEqual(plain(r.items[2].data), { audience: "150–300", price: 8.5, currency: "EUR", age: "18+" });
});
test("details: only what's filled in is written", () => {
  const r = D.quickNight({ title: "X", date: "2026-11-28", start: "20:00" });
  assert.equal(r.items.length, 0);
  assert.equal(r.event.fields.type, undefined);
  assert.match(D.quickNight({ date: "2026-11-28", start: "20:00" }).error, /name/);
  assert.match(D.quickNight({ title: "X", date: "2026-11-28", start: "20:00", price: "-3" }).error, /price/);
  assert.match(D.quickNight({ title: "X", date: "2026-11-28", start: "20:00", link: "javascript:x" }).error, /https/);
});
test("details: free wins over a price; labels", () => {
  const d = D.detailsData({ free: true, price: "10" }).data;
  assert.deepEqual(plain(d), { free: true });
  assert.equal(D.priceLabel(d), "Free");
  assert.equal(D.summary({ audience: "50–150", price: 5, currency: "EUR", age: "All ages" }), "50–150 expected · 5 EUR · All ages");
  assert.equal(D.summary({}), "");
});
test("details: the newest details item wins", () => {
  const ev = { ext: [
    { ns: "xyz.freequencies", kind: "details", id: "d1", hlc: { wall: 1 }, data: { age: "16+" } },
    { ns: "xyz.freequencies", kind: "details", id: "d2", hlc: { wall: 2 }, data: { age: "18+" } }] };
  assert.equal(D.detailsOf(ev).age, "18+");
  assert.deepEqual(plain(D.detailsOf({})), {});
});
