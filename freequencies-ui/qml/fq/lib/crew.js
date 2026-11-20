.pragma library
// Crew (ADR 0007; mirrors mobile/src/app/crew.ts): slots (kind "crew") and check-ins (kind "checkin").
.import "ext.js" as Ext
.import "lineup.js" as Lineup

var roles = ["Door", "Bar", "Sound", "Lights", "Security", "Cloakroom", "Runner"]
// A fresh id per check-in (Scala keeps deleted ids deleted); the slot is in the id so a check-in
// can't be filed under someone else's slot.
function checkinPrefix(slotId) { return "checkin:" + slotId + ":" }
function checkinId(slotId) { return checkinPrefix(slotId) + Ext.rnd() }
function crewOf(ev) {
    var ins = {}, out = [], cs = Ext.extOf(ev, "checkin")
    for (var i = 0; i < cs.length; i++) {
        var x = cs[i], d = Ext.dataOf(x), slot = Ext.str(d.crew)
        if (!slot || Ext.str(x.id).indexOf(checkinPrefix(slot)) !== 0) continue
        var at = (typeof d.at === "number" && isFinite(d.at)) ? d.at : 0, prev = ins[slot]
        if (!prev || at < prev.at || (at === prev.at && Ext.str(x.id) < prev.id)) ins[slot] = { id: Ext.str(x.id), author: Ext.str(x.author), at: at }
    }
    var ys = Ext.extOf(ev, "crew")
    for (var k = 0; k < ys.length; k++) {
        var y = ys[k], e = Ext.dataOf(y), name = Ext.str(e.name).trim(), role = Ext.str(e.role).trim()
        if (!name && !role) continue
        var st = Ext.str(e.status), id = Ext.str(y.id)
        out.push({ id: id, author: Ext.str(y.author), name: name, contact: name ? Ext.str(e.contact) : "", book: name ? Ext.str(e.book) : "",
                   role: role, call: Ext.str(e.call).trim(), status: Lineup.bookingStatuses.indexOf(st) >= 0 ? st : "asked",
                   checkedIn: name ? (ins[id] || null) : null })
    }
    out.sort(function (a, b) {
        return (a.role || "￿").localeCompare(b.role || "￿") || (a.call || "￿").localeCompare(b.call || "￿")
            || (a.name ? 0 : 1) - (b.name ? 0 : 1) || a.name.localeCompare(b.name)
    })
    return out
}
function summary(slots) {
    var r = { people: 0, open: 0, confirmed: 0, here: 0 }
    for (var i = 0; i < slots.length; i++) {
        var c = slots[i]
        if (c.status === "cancelled") continue
        if (!c.name) { r.open++; continue }
        r.people++
        if (c.status === "confirmed") r.confirmed++
        if (c.checkedIn) r.here++
    }
    return r
}
function summaryLabel(sm) {
    var parts = []
    if (sm.people) parts.push(sm.people + " on")
    if (sm.open) parts.push(sm.open + " open")
    if (sm.here) parts.push(sm.here + " here")
    return parts.join(" · ")
}
