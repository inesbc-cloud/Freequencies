import assert from "node:assert/strict";
import { load, plain } from "./load.mjs";
import { night, ext } from "./fixtures.mjs";
const D = load("duplicate.js");
test("duplicate: next week as a Hold, line-up asked, roles open, gear unpacked, tags kept, nothing private", () => {
  const n = night("a", { status: "Confirmed", ext: [
    ext("artist", "a", { name: "Oseias", status: "confirmed", fee: 300, currency: "EUR", contact: "k2", book: "b" }), ext("artist", "a", { name: "Gone", status: "cancelled" }),
    ext("crew", "a", { name: "Lola", role: "Door", status: "confirmed", call: "16:30" }), ext("gear", "a", { item: "CDJs", done: true }),
    ext("tags", "a", { tags: ["live"] }), ext("task", "a", { text: "pay" }), ext("budget", "a", { label: "x", amount: 1 })] });
  const c = plain(D.copyOf(n));
  assert.equal(c.event.startTime - n.startTime, 7 * 864e5);
  assert.equal(c.event.fields.status, "Hold");
  assert.equal(c.items.map((i) => i.kind).join(), "artist,crew,gear,tags");
  assert.equal(c.items[0].data.status, "asked"); assert.equal(c.items[0].data.contact, "k2");
  assert.equal(c.items[1].data.name, ""); assert.equal(c.items[1].data.call, "16:30");
  assert.equal(c.items[2].data.done, false);
  assert.equal(D.repeatLabel({ recur: { freq: "weekly", interval: 2 } }), "Every 2 weeks");
});
