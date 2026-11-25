.pragma library
// The line-up (ADR 0004; mirrors mobile/src/app/lineup.ts): ext kind "artist", data
// {name, contact?, book?, fee?, currency?, set?, status: asked|confirmed|cancelled}.
.import "ext.js" as Ext

var bookingStatuses = ["asked", "confirmed", "cancelled"]
function lineupOf(ev) {
    var xs = Ext.extOf(ev, "artist"), out = []
    for (var i = 0; i < xs.length; i++) {
        var x = xs[i], d = Ext.dataOf(x), name = Ext.str(d.name).trim()
        if (!name) continue
        var fee = (typeof d.fee === "number" && isFinite(d.fee) && d.fee >= 0) ? d.fee : null, st = Ext.str(d.status)
        out.push({ id: Ext.str(x.id), author: Ext.str(x.author), name: name, contact: Ext.str(d.contact), book: Ext.str(d.book), fee: fee,
                   currency: Ext.str(d.currency), set: Ext.str(d.set), status: bookingStatuses.indexOf(st) >= 0 ? st : "asked",
                   local: d.local === true, wnb: d.wnb === true, first: d.first === true })
    }
    out.sort(function (a, b) { return (a.set || "￿").localeCompare(b.set || "￿") || a.name.localeCompare(b.name) })
    return out
}
function artistKey(b) { return b.contact ? "c:" + b.contact : "n:" + b.name.trim().toLowerCase() }
function feeLabel(b) { return b.fee === null ? "" : (b.currency ? b.fee + " " + b.currency : String(b.fee)) }
function feesTotal(bs) {
    var m = {}, keys = []
    for (var i = 0; i < bs.length; i++) {
        var b = bs[i]
        if (b.fee === null || b.status === "cancelled") continue
        if (m[b.currency] === undefined) { m[b.currency] = 0; keys.push(b.currency) }
        m[b.currency] += b.fee
    }
    var parts = []
    for (var k = 0; k < keys.length; k++) parts.push(keys[k] ? m[keys[k]] + " " + keys[k] : String(m[keys[k]]))
    return parts.join(" + ")
}
// Club nights run past midnight: a set starting before noon comes after the evening's sets.
function setKey(set) {
    var m = /(\d{1,2})[:.](\d{2})/.exec(set || "")
    if (!m) return 1e6
    var h = Number(m[1]), mi = Number(m[2])
    return (h < 12 ? h + 24 : h) * 60 + mi
}
function cap(st) { return st.charAt(0).toUpperCase() + st.slice(1) }
// The data written for a booking, from the artist popup's fields.
// flags (optional, for funder reports; private to the collective): { local, wnb, first }
function bookingData(name, status, contact, book, fee, currency, set, flags) {
    var d = { name: name, status: status }
    if (flags) { if (flags.local) d.local = true; if (flags.wnb) d.wnb = true; if (flags.first) d.first = true }
    if (contact) { d.contact = contact; d.book = book }
    if (fee !== null) { d.fee = fee; d.currency = currency }
    if (set) d.set = set
    return d
}
