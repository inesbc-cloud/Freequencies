.pragma library
// Night clashes (#25), across all Freequencies calendars (Scala's own check covers one calendar):
// the same venue booked twice at overlapping times, and the same artist or named crew member on two
// nights that overlap or start the same day. Cancelled nights and cancelled bookings never clash.
.import "nights.js" as Nights
.import "lineup.js" as Lineup
.import "crew.js" as Crew

function occKey(o) { return (o.seriesId || o.id) + "@" + o.occ }
function dayKey(t) { var d = new Date(t); return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate() }
function overlap(p, q) { return p.startTime < q.endTime && q.startTime < p.endTime }
function live(o) { return Nights.fieldOf(o, "status") !== "Cancelled" }

// occKey -> [{ kind: "venue" | "person", name, other }]
function clashes(occs) {
    var xs = occs.filter(live), out = {}
    function add(a, b, kind, name) { var k = occKey(a); (out[k] = out[k] || []).push({ kind: kind, name: name, other: b }) }
    for (var a = 0; a < xs.length; a++) for (var b = a + 1; b < xs.length; b++) {
        var p = xs[a], q = xs[b]
        if (occKey(p) === occKey(q)) continue
        var v = Nights.fieldOf(p, "venue").trim().toLowerCase()
        if (v && v === Nights.fieldOf(q, "venue").trim().toLowerCase() && overlap(p, q)) { add(p, q, "venue", Nights.fieldOf(p, "venue").trim()); add(q, p, "venue", Nights.fieldOf(q, "venue").trim()) }
        if (!overlap(p, q) && dayKey(p.startTime) !== dayKey(q.startTime)) continue
        var pp = people(p), qq = people(q)
        for (var key in pp) if (qq[key]) { add(p, q, "person", pp[key]); add(q, p, "person", qq[key]) }
    }
    return out
}
// Booked artists and named crew of a night: key -> name.
function people(o) {
    var out = {}, lu = Lineup.lineupOf(o).concat(Crew.crewOf(o).filter(function (c) { return !!c.name }))
    for (var i = 0; i < lu.length; i++) if (lu[i].status !== "cancelled") out[Lineup.artistKey(lu[i])] = lu[i].name
    return out
}
function line(c, when) {
    return c.kind === "venue" ? "⚠ " + c.name + " is also booked for " + (c.other.title || "another night") + ", " + when
                              : "⚠ " + c.name + " is also on " + (c.other.title || "another night") + ", " + when
}
