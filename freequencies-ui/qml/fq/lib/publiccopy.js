.pragma library
// The public copy of a night (#21, ADR 0008). MUST stay identical to mobile/src/app/publish.ts: if the
// desktop and Android computed different copies they would keep rewriting each other's. The golden test
// (freequencies-ui/test/publiccopy.test.mjs) runs both on the same nights.
.import "ext.js" as Ext
.import "lineup.js" as Lineup

function publicEventId(nightId) { return "pub-" + nightId }
function publicPrefix(nightId) { return "public:" + nightId + ":" }
function publicItemId(nightId) { return publicPrefix(nightId) + Ext.rnd() }
// The switch: the earliest "public" item under this night's prefix (by hlc, then id).
function publicLinkOf(ev) {
    var nightId = Ext.str(ev && ev.id), xs = (ev && Array.isArray(ev.ext)) ? ev.ext : [], best = null
    for (var i = 0; i < xs.length; i++) {
        var x = xs[i]
        if (!x || x.ns !== Ext.NS || x.kind !== "public" || !nightId || Ext.str(x.id).indexOf(publicPrefix(nightId)) !== 0) continue
        var cal = Ext.str(Ext.dataOf(x).calendar)
        if (!cal) continue
        var h = (x.hlc && typeof x.hlc === "object") ? x.hlc : {}
        var wall = typeof h.wall === "number" ? h.wall : 0, ctr = typeof h.ctr === "number" ? h.ctr : 0
        if (!best || wall < best.wall || (wall === best.wall && (ctr < best.ctr || (ctr === best.ctr && Ext.str(x.id) < best.id))))
            best = { id: Ext.str(x.id), author: Ext.str(x.author), calendar: cal, wall: wall, ctr: ctr }
    }
    return best ? { id: best.id, author: best.author, calendar: best.calendar } : null
}
// Only what attendees may see: never the description, fees, crew, holds, budget, tasks or comments.
function publicCopyOf(n, published) {
    var f = (n.fields && typeof n.fields === "object" && !Array.isArray(n.fields)) ? n.fields : {}
    var cancelled = !published || Ext.str(f.status) === "Cancelled", lines = []
    if (cancelled) lines.push("This night is off.")
    else {
        var acts = Lineup.lineupOf(n).filter(function (b) { return b.status === "confirmed" })
        acts.sort(function (a, b) { return Lineup.setKey(a.set) - Lineup.setKey(b.set) })
        if (acts.length) { lines.push("Line-up:"); for (var i = 0; i < acts.length; i++) lines.push(acts[i].set ? acts[i].set + "  " + acts[i].name : acts[i].name) }
        var xs = Array.isArray(n.ext) ? n.ext : []
        for (var k = 0; k < xs.length; k++) {
            var x = xs[k], d = Ext.dataOf(x)
            if (x && x.ns === Ext.NS && x.kind === "form" && Ext.str(d.purpose) === "guestlist" && Ext.str(d.uri)) {
                if (lines.length) lines.push(""); lines.push("Guest list: " + Ext.str(d.uri)); break
            }
        }
    }
    return { title: (cancelled ? "Cancelled: " : "") + (Ext.str(n.title).trim() || "Untitled night"),
             startTime: n.startTime, endTime: n.endTime, allDay: n.allDay === true,
             location: Ext.str(f.venue).trim(), description: lines.join("\n"), recur: (n.recur === undefined || n.recur === null) ? null : n.recur }
}
function canon(v) {
    return JSON.stringify(v, function (k, x) {
        if (!x || typeof x !== "object" || Array.isArray(x)) return x
        var o = {}, ks = Object.keys(x).sort(); for (var i = 0; i < ks.length; i++) o[ks[i]] = x[ks[i]]; return o
    })
}
function sameCopy(cur, want) {
    if (!cur) return false
    return Ext.str(cur.title) === want.title && cur.startTime === want.startTime && cur.endTime === want.endTime
        && (cur.allDay === true) === want.allDay && Ext.str(cur.location) === want.location
        && Ext.str(cur.description) === want.description && canon(cur.recur === undefined || cur.recur === null ? null : cur.recur) === canon(want.recur)
}
function copyToEvent(c) {
    var e = { title: c.title, startTime: c.startTime, endTime: c.endTime }
    if (c.allDay) e.allDay = true
    if (c.location) e.location = c.location
    if (c.description) e.description = c.description
    if (c.recur !== null && c.recur !== undefined) e.recur = c.recur
    return e
}
// What to write so every published (or formerly published) night's copy is up to date.
function mirrorPlan(nights, all, isPublicTarget) {
    var out = []
    for (var k = 0; k < nights.length; k++) {
        var n = nights[k], pid = publicEventId(n.id), link = publicLinkOf(n), copies = [], targets = {}, order = []
        for (var e = 0; e < all.length; e++) if (all[e].id === pid && isPublicTarget(all[e].calendarId)) {
            copies.push(all[e]); if (!targets[all[e].calendarId]) { targets[all[e].calendarId] = true; order.push(all[e].calendarId) } }
        if (link && isPublicTarget(link.calendar) && !targets[link.calendar]) { targets[link.calendar] = true; order.push(link.calendar) }
        for (var t = 0; t < order.length; t++) {
            var cal = order[t], want = publicCopyOf(n, !!link && link.calendar === cal), cur = null
            for (var c = 0; c < copies.length; c++) if (copies[c].calendarId === cal) { cur = copies[c]; break }
            if (!sameCopy(cur, want)) out.push({ calendarId: cal, id: pid, copy: want, nightId: n.id })
        }
    }
    return out
}
