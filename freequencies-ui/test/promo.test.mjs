import assert from "node:assert/strict";
import { load, plain } from "./load.mjs";
const P = load("promo.js");
const at = (y, mo, d, h = 23, mi = 0) => new Date(y, mo - 1, d, h, mi).getTime();

test("promo: date line and countdown words in EN and PT", () => {
  const s = at(2026, 11, 28, 23), e = at(2026, 11, 29, 5);
  assert.equal(P.whenLine(s, e, "en"), "SAT 28 NOV · 23:00–05:00");
  assert.equal(P.whenLine(s, e, "pt"), "SÁB 28 NOV · 23:00–05:00");
  assert.equal(P.countdown(s, at(2026, 11, 28, 10), "en"), "TONIGHT");
  assert.equal(P.countdown(s, at(2026, 11, 27, 10), "pt"), "AMANHÃ");
  assert.equal(P.countdown(s, at(2026, 11, 24, 10), "en"), "THIS SATURDAY");
  assert.equal(P.countdown(s, at(2026, 11, 10, 10), "en"), "IN 18 DAYS");
  assert.equal(P.countdown(s, at(2026, 11, 30, 10), "en"), "");
});
test("promo: every template fills from the night", () => {
  const f = { title: "Noite", venue: "Desterro", start: at(2026, 11, 28, 23), end: at(2026, 11, 29, 5), lang: "en", now: at(2026, 11, 28, 9),
    lineup: [{ name: "Late One", set: "02:00" }, { name: "Opener", set: "23:00" }], artist: "Opener", ticket: "last", price: "8 EUR" };
  for (const t of P.TEMPLATE_ORDER) { const r = P.fill(t, f); assert.ok(r.big, t); }
  assert.equal(P.fill("artist", f).big, "OPENER");
  assert.equal(P.fill("artist", f).kicker, "NOITE");
  assert.deepEqual(plain(P.fill("timetable", f).rows), [["23:00", "OPENER"], ["02:00", "LATE ONE"]]);
  assert.equal(P.fill("countdown", f).big, "TONIGHT");
  assert.equal(P.fill("tickets", f).big, "LAST TICKETS");
  assert.deepEqual(plain(P.fill("lineup", f).lines), ["LATE ONE", "OPENER"]);
  assert.equal(P.fill("announce", {}).big, "NAME OF THE NIGHT");
});
test("promo: file names and big text size", () => {
  assert.equal(P.fileName("artist", "Freequencies 02", "Ságat Á", "feed"), "freequencies-02-artist-sagat-a-feed.png");
  assert.equal(P.fileName("lineup", "", "", "story"), "night-lineup-story.png");
  assert.ok(P.bigSize("A", 1000) <= 260 && P.bigSize("A VERY LONG ARTIST NAME INDEED", 1000) >= 72);
});
test("promo: the campaign dates every stage and skips what's planned", () => {
  const night = { title: "Noite", startTime: at(2026, 11, 28, 23) };
  const c = P.campaign(night, ["A", "B", "C"], [{ d: { text: "Announce: Noite" } }]);
  const texts = c.map((p) => p.text);
  assert.ok(!texts.includes("Announce: Noite"));
  assert.ok(texts.includes("Artist card: C"));
  const a = c.find((p) => p.text === "Artist card: A"), cc = c.find((p) => p.text === "Artist card: C");
  assert.ok(a.when < cc.when);
  assert.equal(new Date(c.find((p) => p.text.startsWith("Thank")).when).getDate(), 29);
  assert.deepEqual(plain(P.campaign({}, [], [])), []);
});
