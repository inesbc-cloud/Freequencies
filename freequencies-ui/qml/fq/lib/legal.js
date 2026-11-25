.pragma library
// Legal toolkit: legal INFORMATION for promoters in Portugal (not advice). Content is bilingual
// (pt first), every item cites its source and the date it was last checked, and the whole toolkit
// shows a "draft, under legal review" badge until a lawyer has reviewed it (REVIEWED below).
// The content tables live in legal-content.js; this file has the logic. Pure, no Qt.
.import "ext.js" as Ext

// ── which legal form fits you: five questions, a recommendation and why ──
// answers: { money: "none"|"some"|"lots", funding: bool, contracts: bool, profit: bool, people: "few"|"many" }
function recommendForm(a) {
    a = a || {}
    var why = []
    if (a.profit === true) {
        why.push("profit")
        return { form: "company", why: why }
    }
    var needsPerson = a.funding === true || a.contracts === true || a.money === "lots"
    if (a.funding === true) why.push("funding")
    if (a.contracts === true) why.push("contracts")
    if (a.money === "lots") why.push("money")
    if (needsPerson) return { form: "association", why: why }
    if (a.money === "some" || a.people === "many") { why.push(a.money === "some" ? "someMoney" : "people"); return { form: "association-later", why: why } }
    why.push("small")
    return { form: "informal", why: why }
}

// ── inspections log: ext kind "inspection" on the event where it happened ──
// { body, checked: [..], outcome, note, area?, share: bool }
var BODIES = ["PSP", "GNR", "ASAE", "IGAC", "Municipal", "ANEPC / firefighters", "Tax (AT)", "Other"]
var CHECKS = ["Licences", "Noise", "Opening hours", "Capacity", "Alcohol / food", "Music rights", "Fire safety", "IDs", "Drugs", "Other"]
var OUTCOMES = ["Nothing", "Warning", "Fine", "Closed early", "Seizure", "Other"]
function cleanInspection(f) {
    f = f || {}
    if (BODIES.indexOf(f.body) < 0) return { error: "Pick who came." }
    var checked = (Array.isArray(f.checked) ? f.checked : []).filter(function (c) { return CHECKS.indexOf(c) >= 0 })
    var d = { body: f.body, checked: checked, outcome: OUTCOMES.indexOf(f.outcome) >= 0 ? f.outcome : "Nothing",
              note: Ext.str(f.note).trim().slice(0, 1000), share: f.share === true }
    var area = Ext.str(f.area).trim().slice(0, 60); if (area) d.area = area
    return { data: d }
}
// Every inspection across events (newest first), and what they looked at most.
function inspectionsOf(events) {
    var out = []
    ;(events || []).forEach(function (e) {
        Ext.itemsOf(e, "inspection").forEach(function (x) { out.push({ id: x.id, author: x.author, d: x.d, ev: e, at: e.startTime }) })
    })
    out.sort(function (a, b) { return b.at - a.at })
    return out
}
function patterns(list) {
    var by = {}, n = list.length
    list.forEach(function (x) { (x.d.checked || []).forEach(function (c) { by[c] = (by[c] || 0) + 1 }) })
    return Object.keys(by).map(function (k) { return { check: k, n: by[k], of: n } }).sort(function (a, b) { return b.n - a.n || a.check.localeCompare(b.check) })
}
// What gets shared with Lisboa when a collective opts in: no names, no event, no venue.
function anonymised(x) {
    var d = new Date(x.at)
    return { month: d.getFullYear() + "-" + (d.getMonth() < 9 ? "0" : "") + (d.getMonth() + 1), area: x.d.area || "", body: x.d.body, checked: x.d.checked || [], outcome: x.d.outcome }
}

// ── lessons learnt: a debrief row a collective shares with Lisboa (network anchor, kind "lesson") ──
function lessonFrom(row, format) {
    var c = (row && row.cells) || {}
    var d = { topic: Ext.str(c.topic).trim(), worked: Ext.str(c.worked).trim(), change: Ext.str(c.change).trim() }
    if (!d.worked && !d.change) return { error: "Write what worked or what you'd change first." }
    if (format) d.format = format
    return { data: d }
}

// Text in the chosen language from a bilingual { en, pt } (or a plain string).
function txt(x, lang) { if (!x) return ""; if (typeof x === "string") return x; return (lang === "pt" ? x.pt : x.en) || x.en || x.pt || "" }
