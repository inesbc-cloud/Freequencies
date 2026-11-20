import assert from "node:assert/strict";
import { load } from "./load.mjs";
import { night, ext } from "./fixtures.mjs";
const F = load("forms.js");
test("forms: attached forms, status line, answers", () => {
  const n = night("a", { ext: [ext("form", "a", { formId: "f1", uri: "wb://f1", purpose: "guestlist" }), ext("form", "a", { uri: "x" })] });
  const fs = F.formsOf(n);
  assert.equal(fs.length, 1);
  assert.equal(F.formLine(fs[0], { status: "open", canRead: true, responses: 3, newResponses: 1 }), "Guest list · Open · 3 responses · 1 new");
  assert.equal(F.formLine(fs[0], { status: "closed", canRead: false }), "Guest list · Closed · answers go to its creator");
  assert.equal(F.answerText({ options: ["a", "b"] }, [1, { other: "z" }]), "b, z");
  assert.equal(F.answerText(null, true), "Yes");
});
