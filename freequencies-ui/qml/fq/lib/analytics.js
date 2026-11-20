.pragma library
// Analytics (#27): nights, attendance and revenue per month; totals; top tags and venues.
.import "nights.js" as Nights
.import "lineup.js" as Lineup
.import "tags.js" as Tags
.import "money.js" as Money
.import "venues.js" as Venues

// occs: expanded occurrences in [first month, last month]; master(o) -> its event; now: ms.
function stats(occs, master, now, before, after) {
    var d0 = new Date(now), months = []
    for (var i = -before; i <= after; i++) {
        var a = new Date(d0.getFullYear(), d0.getMonth() + i, 1), b = new Date(a.getFullYear(), a.getMonth() + 1, 1)
        months.push({ start: a.getTime(), end: b.getTime(), nights: 0, cancelled: 0, attendance: 0, revenue: 0, profit: 0 })
    }
    var tot = { nights: 0, confirmed: 0, hold: 0, cancelled: 0, attendance: 0, revenue: 0, profit: 0, artists: 0 }, seen = {}, byTag = {}, byVenue = {}
    for (var k = 0; k < occs.length; k++) {
        var o = occs[k], m = master(o) || o, st = Nights.fieldOf(m, "status")
        for (var j = 0; j < months.length; j++) {
            var mo = months[j]
            if (o.startTime < mo.start || o.startTime >= mo.end) continue
            if (st === "Cancelled") { mo.cancelled++; tot.cancelled++; break }
            var money = Money.moneyOf(m), att = Venues.attendanceOf(m)
            mo.nights++; mo.attendance += att; mo.revenue += money.income; mo.profit += money.profit
            tot.nights++; tot.attendance += att; tot.revenue += money.income; tot.profit += money.profit
            if (st === "Confirmed") tot.confirmed++; else tot.hold++
            var lu = Lineup.lineupOf(m); for (var l = 0; l < lu.length; l++) { var key = Lineup.artistKey(lu[l]); if (!seen[key]) { seen[key] = true; tot.artists++ } }
            var tg = Tags.tagsOf(m); for (var t = 0; t < tg.length; t++) byTag[tg[t]] = (byTag[tg[t]] || 0) + 1
            var v = Nights.fieldOf(m, "venue").trim(); if (v) byVenue[v] = (byVenue[v] || 0) + 1
            break
        }
    }
    function top(o, n) { return Object.keys(o).map(function (k) { return { label: k, n: o[k] } }).sort(function (a, b) { return b.n - a.n || a.label.localeCompare(b.label) }).slice(0, n) }
    var mx = { nights: 1, attendance: 1, revenue: 1 }
    for (var x = 0; x < months.length; x++) for (var key2 in mx) mx[key2] = Math.max(mx[key2], months[x][key2])
    return { months: months, tot: tot, max: mx, tags: top(byTag, 8), venues: top(byVenue, 6) }
}
