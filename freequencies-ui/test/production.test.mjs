import assert from "node:assert/strict";
import { load, plain } from "./load.mjs";
const P = load("production.js");
const H = load("home.js");
const NS = "xyz.freequencies";
const DAY = 86400000;
let wall = 1;
const item = (kind, data, author = "0xa") => ({ ns: NS, kind, id: kind + ":" + wall, author, hlc: { wall: wall++ }, data });

test("production: every format seeds a plan whose modules and tables exist", () => {
  for (const f of P.FORMAT_ORDER) {
    const s = P.seedPlan(f);
    assert.equal(s.plan.format, f);
    for (const m of s.plan.modules) assert.ok(P.MODULES[m], f + ": module " + m);
    for (const r of s.rows) {
      assert.ok(P.TABLES[r.table], f + ": table " + r.table);
      assert.equal(P.cleanCells(P.TABLES[r.table], r.cells).error, undefined, f + ": " + JSON.stringify(r.cells));
    }
    assert.ok(s.rows.some((r) => r.table === "milestones"), f + " has milestones");
  }
  assert.equal(P.seedPlan("nope"), null);
});
test("production: the newest version of a row wins, whoever wrote it; deleted rows go", () => {
  const night = { startTime: Date.UTC(2026, 11, 17, 22), ext: [
    item("prod-plan", { format: "club", modules: ["timeline", "bogus"], custom: [] }),
    item("prod-row", { row: "r1", table: "milestones", order: 0, cells: { t: 14, task: "Reveal", done: false } }, "0xa"),
    item("prod-row", { row: "r1", table: "milestones", order: 0, cells: { t: 14, task: "Reveal", done: true } }, "0xb"),
    item("prod-row", { row: "r2", table: "milestones", order: 10, cells: { t: 42, task: "Venue", done: false } }),
    item("prod-row", { row: "r3", table: "milestones", order: 20, cells: { t: 7, task: "Gone" } }),
    item("prod-row", { row: "r3", table: "milestones", order: 20, cells: {}, del: true }),
  ] };
  assert.deepEqual(plain(P.planOf(night).modules), ["timeline"]);
  const ms = P.rowsOf(night, "milestones");
  assert.deepEqual(plain(ms.map((r) => r.row)), ["r2", "r1"]);
  assert.equal(ms[1].cells.done, true);
  assert.equal(ms[1].author, "0xb");
  assert.deepEqual(plain(P.progress(night, P.planOf(night))), { done: 1, total: 2 });
});
test("production: due dates count back from show day; overdue and soon", () => {
  const show = Date.UTC(2026, 11, 17, 22);
  const night = { startTime: show, ext: [
    item("prod-row", { row: "a", table: "milestones", cells: { t: 30, task: "Old", done: false } }),
    item("prod-row", { row: "b", table: "milestones", cells: { t: 10, task: "Soon", done: false } }),
    item("prod-row", { row: "c", table: "milestones", cells: { t: 2, task: "Later", done: false } }),
    item("prod-row", { row: "d", table: "milestones", cells: { t: 30, task: "Done", done: true } })] };
  const now = show - 14 * DAY;
  assert.deepEqual(plain(P.dueMilestones(night, now, 7).map((m) => [m.task, m.overdue])), [["Old", true], ["Soon", false]]);
  assert.equal(P.tLabel(14), "T-14"); assert.equal(P.tLabel(-2), "T+2"); assert.equal(P.tLabel(0), "Show day");
});
test("production: run of show sorts past midnight", () => {
  const night = { ext: [item("prod-row", { row: "x", table: "ros", cells: { time: "02:00", what: "B" } }),
                        item("prod-row", { row: "y", table: "ros", cells: { time: "23:00", what: "A" } })] };
  assert.deepEqual(plain(P.rowsOf(night, "ros").map((r) => r.cells.what)), ["A", "B"]);
});
test("production: cells are checked against their columns", () => {
  const ms = P.TABLES.milestones;
  assert.match(P.cleanCells(ms, { task: "x" }).error, /Days before/);
  assert.deepEqual(plain(P.cleanCells(ms, { t: "14", task: " Reveal ", done: "yes", junk: 1 }).cells), { t: 14, task: "Reveal", owner: "", done: false });
  assert.match(P.cleanCells(P.TABLES.venue, { item: "x", status: "Maybe" }).error, /options/);
  assert.match(P.cleanCells(P.TABLES.ros, { time: "late" }).error, /time/);
  assert.match(P.cleanCells(P.TABLES.vendors, { quote: "a lot" }).error, /number/);
  assert.equal(P.riskScore({ l: "2", i: "3" }), 6);
});
test("production: custom modules from a short column spec", () => {
  const r = P.customModule("Merch", "Item, Qty:num, Price:money, Sold out:check");
  assert.equal(r.module.name, "Merch");
  assert.deepEqual(plain(r.module.cols.map((c) => c.type)), ["text", "num", "money", "check"]);
  assert.ok(r.module.id.startsWith("cm-"));
  assert.match(P.customModule("", "a").error, /Name/);
  assert.match(P.customModule("X", "").error, /column/);
  assert.match(P.customModule("X", "A:colour").error, /types/);
  const plan = { format: "club", modules: [r.module.id], custom: [r.module] };
  assert.equal(P.moduleDef(plan, r.module.id).t, "Merch");
  assert.equal(P.tableDef(plan, r.module.id).cols.length, 4);
});

test("home: holds, missing venue and line-up, overdue milestones, funding deadlines", () => {
  const now = Date.UTC(2026, 10, 20, 12);
  const occ = (o) => ({ ns: NS, fields: {}, ext: [], ...o });
  const occs = [
    occ({ id: "n1", title: "Soon hold", startTime: now + 5 * DAY, fields: { status: "Hold", venue: "Damas" } }),
    occ({ id: "n2", title: "No venue", startTime: now + 20 * DAY, fields: { status: "Confirmed", venue: "" },
          ext: [item("artist", { name: "A", status: "asked" }), item("prod-row", { row: "m", table: "milestones", cells: { t: 28, task: "Announce", done: false } })] }),
    occ({ id: "n3", title: "Cancelled", startTime: now + 3 * DAY, fields: { status: "Cancelled" } }),
    occ({ id: "n4", title: "Far", startTime: now + 90 * DAY, fields: { status: "Hold" } })];
  const anchor = { ext: [item("fund-link", { name: "DGArtes", url: "https://x.pt", deadline: "2026-11-25" })] };
  const a = H.attention(occs, anchor, now);
  const texts = a.map((x) => x.text);
  assert.ok(texts.includes("Soon hold is still on hold"));
  assert.equal(a[0].tone, "red");
  assert.ok(texts.includes("No venue has no venue yet"));
  assert.ok(texts.includes("Soon hold has no line-up yet"));
  assert.ok(!texts.includes("No venue has no line-up yet"));
  assert.ok(texts.includes("Announce"));
  assert.ok(texts.some((t) => t.startsWith("DGArtes closes")));
  assert.ok(!texts.some((t) => t.startsWith("Cancelled") || t.startsWith("Far")));
  assert.deepEqual(plain(H.stats(occs, now)), { next30: 2, holds: 1, confirmed: 1 });
});
test("home: several overdue milestones on one night fold into one line", () => {
  const now = Date.UTC(2026, 10, 20, 12);
  const ms = [30, 25, 20, 3].map((t, i) => item("prod-row", { row: "m" + i, table: "milestones", cells: { t, task: "M" + t, done: false } }));
  const occs = [{ id: "n", title: "Night", startTime: now + 5 * DAY, fields: { status: "Confirmed", venue: "X" }, ext: [item("artist", { name: "A", status: "asked" }), ...ms] }];
  const texts = H.attention(occs, null, now).map((x) => x.text);
  assert.ok(texts.includes("3 production milestones overdue"));
  assert.ok(texts.includes("M3"));
  assert.ok(!texts.includes("M30"));
});
