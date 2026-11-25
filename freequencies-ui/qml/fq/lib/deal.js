.pragma library
// Deal calculator and co-promotion settlement. Pure, no Qt.
//
// A deal: what the artist gets, against ticket price × capacity and the night's costs.
//   flat      — a fixed fee
//   door      — a share of the door (ticket money), nothing else
//   plus      — a guarantee plus a share of what's left after costs and the guarantee
//   versus    — the guarantee or a share of what's left after costs, whichever is bigger
// Saved on the event as ext kind "deal" (newest wins): { type, fee, pct, price, capacity, costs: [{label, amount}], other }
.import "ext.js" as Ext

var TYPES = ["flat", "door", "plus", "versus"]
var LABELS = { flat: "Flat fee", door: "Door split", plus: "Guarantee + %", versus: "Guarantee vs %" }
var FILLS = [0.25, 0.5, 0.75, 1]

function n(v) { var s = String(v === undefined || v === null ? "" : v).replace(",", ".").trim(); if (s === "") return 0; var x = Number(s); return isFinite(x) ? x : NaN }
function parse(f) {
    f = f || {}
    var d = { type: TYPES.indexOf(f.type) >= 0 ? f.type : "flat", fee: n(f.fee), pct: n(f.pct), price: n(f.price), capacity: Math.round(n(f.capacity)), other: n(f.other), costs: [] }
    var bad = ["fee", "pct", "price", "capacity", "other"].filter(function (k) { return !isFinite(d[k]) || d[k] < 0 })
    if (bad.length) return { error: "Use plain numbers (no symbols) for fee, %, price, capacity and other income." }
    if (d.pct > 100) return { error: "The share is a percentage, 0 to 100." }
    var cs = Array.isArray(f.costs) ? f.costs : []
    for (var i = 0; i < cs.length; i++) {
        var a = n(cs[i].amount), l = Ext.str(cs[i].label).trim()
        if (!l && !a) continue
        if (!isFinite(a) || a < 0) return { error: "Costs are numbers, like 300." }
        d.costs.push({ label: l || "Cost", amount: a })
    }
    return { data: d }
}
function costsOf(d) { var s = 0; (d.costs || []).forEach(function (c) { s += c.amount }); return s }

// One scenario at a fill (0..1). Everything in the deal's currency.
function at(d, fill) {
    var tickets = Math.round(d.capacity * fill), door = tickets * d.price, costs = costsOf(d)
    var net = door + d.other - costs                       // before the artist
    var p = d.pct / 100, artist
    if (d.type === "flat") artist = d.fee
    else if (d.type === "door") artist = door * p
    else if (d.type === "plus") artist = d.fee + Math.max(0, net - d.fee) * p
    else artist = Math.max(d.fee, Math.max(0, net) * p)
    var promoter = net - artist
    return { fill: fill, tickets: tickets, door: door, costs: costs, artist: artist, promoter: promoter }
}
function table(d) { return FILLS.map(function (f) { return at(d, f) }) }
// Tickets needed so the promoter doesn't lose money (null if it never breaks even at this capacity).
function breakEven(d) {
    if (d.price <= 0) return at(d, 0).promoter >= 0 ? 0 : null
    for (var t = 0; t <= Math.max(d.capacity, 0); t++) if (at(d, d.capacity ? t / d.capacity : 0).promoter >= -0.005) return t
    return null
}
// The chosen deal as budget lines: the artist's fee at the expected fill, and each cost.
function budgetLines(d, fill, artistName) {
    var s = at(d, fill), out = []
    out.push({ label: (artistName ? artistName + " · " : "") + LABELS[d.type], amount: Math.round(s.artist * 100) / 100, dir: "out" })
    ;(d.costs || []).forEach(function (c) { out.push({ label: c.label, amount: c.amount, dir: "out" }) })
    if (d.other > 0) out.push({ label: "Other income", amount: d.other, dir: "in" })
    return out
}

// ── co-promotion: partners share the result; after the night, who owes whom ──
// copro data (ext kind "copro", newest wins): { partners: [{name, share}], moves: [{who, kind: "paid"|"took", label, amount}], settled: bool }
// "paid" = the partner paid a cost; "took" = the partner holds income (door cash, card payout…).
function settle(c) {
    var ps = (c && Array.isArray(c.partners)) ? c.partners.filter(function (p) { return Ext.str(p.name).trim() }) : []
    var mv = (c && Array.isArray(c.moves)) ? c.moves : []
    var totalShare = ps.reduce(function (s, p) { return s + (Number(p.share) || 0) }, 0)
    var costs = 0, income = 0, pos = {}
    ps.forEach(function (p) { pos[p.name] = { name: p.name, share: Number(p.share) || 0, paid: 0, took: 0 } })
    mv.forEach(function (m) {
        var a = Number(m.amount) || 0, x = pos[m.who]; if (!x || a <= 0) return
        if (m.kind === "took") { x.took += a; income += a } else { x.paid += a; costs += a }
    })
    var result = income - costs
    var rows = Object.keys(pos).map(function (k) {
        var x = pos[k], fair = totalShare > 0 ? result * x.share / totalShare : 0
        x.fair = fair; x.balance = fair - (x.took - x.paid)      // > 0: is owed money
        return x
    })
    // fewest transfers: biggest debtor pays biggest creditor
    var cred = rows.filter(function (r) { return r.balance > 0.005 }).map(function (r) { return { name: r.name, v: r.balance } }).sort(function (a, b) { return b.v - a.v })
    var debt = rows.filter(function (r) { return r.balance < -0.005 }).map(function (r) { return { name: r.name, v: -r.balance } }).sort(function (a, b) { return b.v - a.v })
    var transfers = [], i = 0, j = 0
    while (i < debt.length && j < cred.length) {
        var amt = Math.min(debt[i].v, cred[j].v)
        transfers.push({ from: debt[i].name, to: cred[j].name, amount: Math.round(amt * 100) / 100 })
        debt[i].v -= amt; cred[j].v -= amt
        if (debt[i].v < 0.005) i++
        if (cred[j].v < 0.005) j++
    }
    return { rows: rows, costs: costs, income: income, result: result, totalShare: totalShare, transfers: transfers, sharesOk: Math.abs(totalShare - 100) < 0.01 }
}
