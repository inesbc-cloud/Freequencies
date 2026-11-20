import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext } from "./fixtures.mjs";
const T = load("tickets.js");
test("tickets: line, revenue, share, parse", () => {
  const n = night("a", { ext: [ext("tickets", "a", { sold: 142, capacity: 180, price: 0 })] });
  const t = T.ticketsOf(n);
  assert.equal(T.line(t), "142 / 180 sold · free entry");
  assert.equal(T.revenue({ sold: 10, price: 8 }), 80);
  assert.ok(Math.abs(T.soldShare(t) - 142 / 180) < 1e-9);
  assert.equal(T.parse("lu.ma/x", "1", "", "10,5", "eur").data.url, "https://lu.ma/x");
  assert.equal(T.parse("", "1", "", "10,5", "eur").data.price, 10.5);
  assert.ok(T.parse("", "-2", "", "", "").error);
  assert.equal(T.ticketsOf(night("b")), null);
});
