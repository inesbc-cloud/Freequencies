import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext } from "./fixtures.mjs";
const C = load("checklist.js");
const now = 1_000_000_000_000, DAY = 864e5;
test("tasks: open first by deadline, overdue and due soon", () => {
  const n = night("a", { ext: [ext("task", "a", { text: "late", due: now - DAY }), ext("task", "a", { text: "done", done: true, due: now - 9 * DAY }),
                               ext("task", "a", { text: "soon", due: now + DAY }), ext("task", "a", { text: "whenever" })] });
  const ts = C.tasksOf(n);
  assert.equal(ts.map((t) => t.d.text).join(), "late,soon,whenever,done");
  assert.equal(C.overdue(ts[0], now), true); assert.equal(C.dueSoon(ts[1], now), true); assert.equal(C.overdue(ts[3], now), false);
  assert.equal(C.openCount(n), 3); assert.equal(C.overdueCount([n, n], now), 2);
  assert.ok(C.parse("task", " ", null, {}).error);
  assert.equal(C.parse("task", "Pay", 5, { cat: "payment" }).data.due, 5);
});
