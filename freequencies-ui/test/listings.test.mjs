import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { load, plain } from "./load.mjs";
const L = load("listings.js");
const here = path.dirname(fileURLToPath(import.meta.url));

test("listings: the real Luma feed parses into pink, read-only events", () => {
  const evs = L.parseIcs(fs.readFileSync(path.join(here, "fixtures-luma.ics"), "utf8"), "Luma");
  assert.equal(evs.length, 3);
  const fq = evs.find((e) => e.title === "Freequencies");
  assert.ok(fq);
  assert.equal(fq.calendarId, L.LISTINGS_CAL);
  assert.equal(L.isListing(fq), true);
  assert.equal(fq.id, "listing:evt-737SOwCoAGpIBaM@events.lu.ma");
  assert.equal(fq.startTime, Date.UTC(2026, 10, 25, 17, 0, 0));
  assert.equal(L.venueOf(fq), "Damas");
  assert.match(L.linkOf(fq), /^https:\/\/luma\.com\//);
  assert.ok(evs[0].startTime <= evs[1].startTime);
});
test("listings: dates, folded lines, escapes, cancelled events", () => {
  const ics = "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nUID:a\r\nSUMMARY:One\\, two\r\nDTSTART;VALUE=DATE:20261201\r\nDESCRIPTION:long\r\n  text\\nnext\r\nEND:VEVENT\r\n" +
    "BEGIN:VEVENT\r\nUID:b\r\nSUMMARY:Off\r\nSTATUS:CANCELLED\r\nDTSTART:20261201T200000Z\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\nSUMMARY:no uid\r\nDTSTART:20261201T200000Z\r\nEND:VEVENT\r\nEND:VCALENDAR";
  const evs = L.parseIcs(ics, "X");
  assert.equal(evs.length, 1);
  assert.equal(evs[0].title, "One, two");
  assert.equal(evs[0].allDay, true);
  assert.equal(evs[0].description, "long text\nnext");
  assert.equal(evs[0].endTime - evs[0].startTime, 2 * 3600000);
  assert.deepEqual(plain(L.parseIcs("", "X")), []);
});
test("listings: community calendar marker and built-in join links", () => {
  assert.equal(L.isCommunityCal({ schema: L.withField([{ key: "status" }], L.communityField) }), true);
  assert.equal(L.isCommunityCal({ schema: [] }), false);
  const links = ["scala://join?id=cal-a&key=k&name=Lisboa", "scala://join?id=cal-b&key=k", "scala://join?key=k"];
  assert.deepEqual(plain(L.linksToJoin(links, [{ id: "cal-a" }])), ["scala://join?id=cal-b&key=k"]);
});
