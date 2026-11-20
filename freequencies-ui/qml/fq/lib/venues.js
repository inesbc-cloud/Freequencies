.pragma library
// Venues (#26): every venue the nights have used, saved once and reused. Derived, nothing stored.
.import "nights.js" as Nights
.import "tickets.js" as Tickets

function goingOf(ev) { var n = 0, r = (ev && ev.rsvps) || {}; for (var k in r) if (r[k] === "going") n++; return n }
function attendanceOf(ev) { var t = Tickets.ticketsOf(ev); return t && typeof t.sold === "number" ? t.sold : goingOf(ev) }
// nights: masters of the Freequencies calendars; calName(id) -> name.
function venues(nights, now, calName) {
    var by = {}, out = []
    for (var i = 0; i < nights.length; i++) {
        var e = nights[i], v = Nights.fieldOf(e, "venue").trim()
        if (!v) continue
        var key = v.toLowerCase()
        if (!by[key]) { by[key] = { name: v, nights: 0, upcoming: 0, next: 0, last: 0, attendance: 0, cals: [] }; out.push(by[key]) }
        var r = by[key], cn = calName(e.calendarId)
        r.nights++; if (cn && r.cals.indexOf(cn) < 0) r.cals.push(cn)
        if (e.startTime >= now) { r.upcoming++; if (!r.next || e.startTime < r.next) r.next = e.startTime }
        else if (e.startTime > r.last) r.last = e.startTime
        if (Nights.fieldOf(e, "status") !== "Cancelled") r.attendance += attendanceOf(e)
    }
    out.sort(function (a, b) { return b.nights - a.nights || a.name.localeCompare(b.name) })
    return out
}
