import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext } from "./fixtures.mjs";
const M = load("money.js");
test("budget: lines, fees of booked artists, ticket sales, result", () => {
  const n = night("a", { ext: [ext("budget", "a", { label: "Support", amount: 2000, dir: "in" }), ext("budget", "a", { label: "Venue", amount: 400, dir: "out" }),
    ext("artist", "a", { name: "A", fee: 300, currency: "EUR", status: "confirmed" }), ext("artist", "a", { name: "B", fee: 999, status: "cancelled" }),
    ext("tickets", "a", { sold: 10, price: 8 })] });
  const m = M.moneyOf(n);
  assert.equal(m.income, 2080); assert.equal(m.costs, 700); assert.equal(m.profit, 1380);
  assert.equal(M.money(1380.5, "EUR"), "1 380.50 EUR");
  assert.equal(M.money(-20), "−20 EUR");
  assert.ok(M.parse("x", "-1").error); assert.equal(M.parse("x", "12,5", "", "in").data.amount, 12.5);
});
