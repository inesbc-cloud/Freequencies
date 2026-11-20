.pragma library
// The night's budget (#18): ext kind "budget" {label, amount, currency, dir: "in"|"out"}, plus the
// line-up's fees (out) and ticket sales (in), which count by themselves.
.import "ext.js" as Ext
.import "lineup.js" as Lineup
.import "tickets.js" as Tickets

function linesOf(ev) { return Ext.itemsOf(ev, "budget") }
function moneyOf(ev) {
    var r = { inc: 0, out: 0, fees: 0, tickets: 0, cur: "EUR" }
    if (!ev) { r.income = 0; r.costs = 0; r.profit = 0; return r }
    var lines = linesOf(ev)
    for (var i = 0; i < lines.length; i++) {
        var a = Ext.num(lines[i].d.amount); if (a === null) continue
        if (Ext.str(lines[i].d.currency)) r.cur = lines[i].d.currency
        if (lines[i].d.dir === "in") r.inc += a; else r.out += a
    }
    var lu = Lineup.lineupOf(ev)
    for (var k = 0; k < lu.length; k++) if (lu[k].fee !== null && lu[k].status !== "cancelled") { r.fees += lu[k].fee; if (lu[k].currency) r.cur = lu[k].currency }
    r.tickets = Tickets.revenue(Tickets.ticketsOf(ev))
    r.income = r.inc + r.tickets; r.costs = r.out + r.fees; r.profit = r.income - r.costs
    return r
}
function money(n, cur) {
    var s = Math.round(n * 100) / 100, a = Math.abs(s)
    var txt = (a % 1 ? a.toFixed(2) : String(a)).replace(/\B(?=(\d{3})+(?!\d))/g, " ")
    return (s < 0 ? "−" : "") + txt + " " + (cur || "EUR")
}
function parse(label, amount, currency, dir) {
    label = String(label || "").trim()
    if (!label) return { error: "Say what it's for." }
    var t = String(amount || "").trim().replace(",", "."), a = Number(t)
    if (t === "" || !(isFinite(a) && a >= 0)) return { error: "The amount should be a number, for example 250." }
    return { data: { label: label, amount: a, currency: String(currency || "").trim().toUpperCase() || "EUR", dir: dir === "in" ? "in" : "out" } }
}
