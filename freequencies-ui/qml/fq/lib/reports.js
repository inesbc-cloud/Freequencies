.pragma library
// Reports: numbers with a clear owner and a clear question.
//   eventResult(ev)        — how did this event go? (money, audience, break-even, plan vs actual)
//   yearReport(evs, …)     — how is this collective doing? (+ the numbers funders ask for)
//   cityPulse(evs, …)      — what's on in Lisbon? (busy and empty weekends, crowded nights)
// Pure, no Qt. Text shown to people goes through `tr` (Fq.t) when given.
.import "ext.js" as Ext
.import "nights.js" as Nights
.import "lineup.js" as Lineup
.import "money.js" as Money
.import "tickets.js" as Tickets
.import "venues.js" as Venues
.import "details.js" as Details
.import "crew.js" as Crew

var DAY = 86400000
function id(s, a) { var o = s; (a || []).forEach(function (v, i) { o = o.split("%" + (i + 1)).join(String(v)) }); return o }
// "150–300" → 225 (the middle of an expected-audience band); "600+" → 600; "Under 50" → 40.
function expectedOf(band) {
    var s = Ext.str(band), m = /(\d+)\s*[–-]\s*(\d+)/.exec(s)
    if (m) return Math.round((+m[1] + +m[2]) / 2)
    m = /(\d+)\+/.exec(s); if (m) return +m[1]
    m = /(\d+)/.exec(s); if (m) return Math.round(+m[1] * 0.8)
    return 0
}

function eventResult(ev) {
    var m = Money.moneyOf(ev), t = Tickets.ticketsOf(ev) || {}, det = Details.detailsOf(ev)
    var att = Venues.attendanceOf(ev), cap = Ext.num(t.capacity) || 0, price = Ext.num(t.price)
    var lu = Lineup.lineupOf(ev).filter(function (b) { return b.status !== "cancelled" })
    var paid = lu.filter(function (b) { return b.fee !== null && b.fee > 0 }).length
    var other = m.inc, costs = m.costs
    var be = price && price > 0 ? Math.max(0, Math.ceil((costs - other) / price)) : null
    var exp = expectedOf(det.audience)
    return { cur: m.cur, income: m.income, costs: costs, profit: m.profit, tickets: m.tickets, fees: m.fees,
             attendance: att, capacity: cap, fill: cap > 0 ? Math.min(1, att / cap) : null,
             costPerHead: att > 0 ? costs / att : null, breakEven: be, artists: lu.length, artistsPaid: paid,
             expected: exp, vsExpected: exp > 0 && att > 0 ? att / exp : null,
             hasMoney: m.income > 0 || costs > 0, hasAudience: att > 0 }
}

// evs: the collective's events (masters, one per occurrence for series) in [from, to).
function yearReport(evs, from, to) {
    var r = { events: 0, cancelled: 0, audience: 0, income: 0, costs: 0, profit: 0, cur: "EUR",
              artists: 0, local: 0, wnb: 0, first: 0, free: 0, accessible: 0, venues: 0, crew: 0, paidArtists: 0 }
    var seenA = {}, seenV = {}, seenC = {}
    for (var i = 0; i < (evs || []).length; i++) {
        var e = evs[i]
        if (!e || e.startTime < from || e.startTime >= to) continue
        if (Nights.fieldOf(e, "status") === "Cancelled") { r.cancelled++; continue }
        r.events++
        var m = Money.moneyOf(e); r.income += m.income; r.costs += m.costs; r.cur = m.cur
        r.audience += Venues.attendanceOf(e)
        var det = Details.detailsOf(e), t = Tickets.ticketsOf(e) || {}
        if (det.free === true || (Ext.num(t.price) === 0)) r.free++
        if (Ext.str(det.access).trim()) r.accessible++
        var v = Nights.fieldOf(e, "venue").trim().toLowerCase(); if (v && !seenV[v]) { seenV[v] = true; r.venues++ }
        var lu = Lineup.lineupOf(e)
        for (var k = 0; k < lu.length; k++) {
            var b = lu[k]; if (b.status === "cancelled") continue
            var key = Lineup.artistKey(b), d = rawBooking(e, b.id)
            if (!seenA[key]) {
                seenA[key] = true; r.artists++
                if (d.local === true) r.local++
                if (d.wnb === true) r.wnb++
                if (d.first === true) r.first++
            }
            if (b.fee !== null && b.fee > 0) r.paidArtists++
        }
        var cr = Crew.crewOf(e)
        for (var c = 0; c < cr.length; c++) { var nm = Ext.str(cr[c].name).trim().toLowerCase(); if (nm && !seenC[nm]) { seenC[nm] = true; r.crew++ } }
    }
    r.profit = r.income - r.costs
    r.avgAudience = r.events ? Math.round(r.audience / r.events) : 0
    return r
}
function rawBooking(ev, bookingId) {
    var xs = Ext.extOf(ev, "artist")
    for (var i = 0; i < xs.length; i++) if (xs[i].id === bookingId) return Ext.dataOf(xs[i])
    return {}
}
function pct(n, d) { return d > 0 ? Math.round(100 * n / d) + "%" : "—" }

// A short paragraph and table for funding applications (in the app's language via tr).
function applicationText(r, who, period, tr) {
    tr = tr || id
    var lines = [
        tr("%1 organised %2 events in %3, for about %4 people (%5 on average).", [who, r.events, period, r.audience, r.avgAudience]),
        tr("We programmed %1 artists (%2 based in Lisbon, %3 women or non-binary, %4 performing for the first time) and paid %5 artist fees.", [r.artists, r.local, r.wnb, r.first, r.paidArtists]),
        tr("%1 events were free and %2 had accessibility measures; %3 venues and %4 crew members took part.", [r.free, r.accessible, r.venues, r.crew])
    ]
    var table = [
        [tr("Events"), r.events], [tr("Audience"), r.audience], [tr("Artists"), r.artists],
        [tr("Lisbon-based artists"), r.local + " (" + pct(r.local, r.artists) + ")"],
        [tr("Women and non-binary artists"), r.wnb + " (" + pct(r.wnb, r.artists) + ")"],
        [tr("First-time performers"), r.first + " (" + pct(r.first, r.artists) + ")"],
        [tr("Free events"), r.free], [tr("Events with accessibility measures"), r.accessible], [tr("Venues"), r.venues], [tr("Crew"), r.crew]
    ]
    return lines.join(" ") + "\n\n" + table.map(function (row) { return row[0] + ": " + row[1] }).join("\n")
}

// What's on in the city: the next `weeks` weekends (Fri–Sun) with how many events, and the
// nights with 3+ events (crowded) — from the Lisboa calendar and the public listings.
function cityPulse(evs, now, weeks) {
    var d = new Date(now), dow = d.getDay()
    var fri = new Date(d.getFullYear(), d.getMonth(), d.getDate() + ((5 - dow + 7) % 7), 0, 0, 0).getTime()
    if (dow === 6 || dow === 0) fri -= 7 * DAY   // a weekend in progress counts
    var out = [], byNight = {}
    for (var w = 0; w < weeks; w++) out.push({ start: fri + w * 7 * DAY, end: fri + w * 7 * DAY + 3 * DAY, count: 0, titles: [] })
    for (var i = 0; i < (evs || []).length; i++) {
        var e = evs[i]; if (!e || Nights.fieldOf(e, "status") === "Cancelled") continue
        for (var k = 0; k < out.length; k++) if (e.startTime >= out[k].start && e.startTime < out[k].end) { out[k].count++; if (out[k].titles.length < 4) out[k].titles.push(Ext.str(e.title)) }
        if (e.startTime >= now - DAY && e.startTime < now + weeks * 7 * DAY) {
            var n = new Date(e.startTime - 6 * 3600000); var key = n.getFullYear() + "-" + (n.getMonth() + 1) + "-" + n.getDate()
            ;(byNight[key] = byNight[key] || { day: new Date(n.getFullYear(), n.getMonth(), n.getDate()).getTime(), n: 0 }).n++
        }
    }
    var counts = out.map(function (x) { return x.count })
    var max = Math.max.apply(null, counts.concat([1]))
    var crowded = Object.keys(byNight).map(function (k) { return byNight[k] }).filter(function (x) { return x.n >= 3 }).sort(function (a, b) { return a.day - b.day })
    return { weekends: out, max: max, crowded: crowded, quietest: out.slice().sort(function (a, b) { return a.count - b.count || a.start - b.start })[0] || null }
}
