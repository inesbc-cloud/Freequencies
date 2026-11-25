.pragma library
// Network: what collectives share with each other, in the Lisboa community calendar (ADR 0011).
// Like the Funding library, it lives on one anchor event there (field fq_network = "anchor"):
//   "venue"   a venue in the directory          { name, area, capacity, access, tech, contact, deal, notes }
//   "gear"    something a collective can lend   { item, qty, owner, contact, notes }
//   "borrow"  a request to borrow gear          { gear, who, from, to, note }
//   "reply"   the lender's answer (newest wins) { borrow, status: "ok" | "no" | "returned" }
//   "crew"    a person in the crew pool         { name, skills: [..], contact, when, notes }   (they add themselves)
//   "poll"    a quick poll                      { q, options: [..], closes }                   (also on any event)
//   "vote"    one vote; the newest per person and poll counts { poll, choice }
// Scala lets only an item's author change it, so each person edits what they added.
// Pure, no Qt.
.import "ext.js" as Ext

var MARKER = "fq_network"
var markerField = { key: MARKER, label: "Freequencies network", type: "text" }
var SKILLS = ["Door", "Bar", "Sound", "Lights", "Security", "Stage", "Visuals", "Photo / video", "Runner", "First aid", "Driving", "Design"]

function anchorOf(events, calId) {
    var best = null
    for (var i = 0; i < (events || []).length; i++) {
        var e = events[i]
        if (!e || e.calendarId !== calId || !e.fields || e.fields[MARKER] !== "anchor") continue
        if (!best || (e.startTime || 0) < (best.startTime || 0) || (e.startTime === best.startTime && e.id < best.id)) best = e
    }
    return best
}
function anchorEvent() {
    var f = {}; f[MARKER] = "anchor"
    return { title: "Freequencies network", startTime: Date.UTC(2000, 0, 1, 12), endTime: Date.UTC(2000, 0, 1, 13), allDay: true,
             description: "Holds the shared venue directory, gear library, crew pool and polls. Don't delete it.", location: "", url: "", reminderMin: 0, fields: f }
}

// ── the forms (shared by the popup and validation) ──
function f(k, l, type, opts) { var x = { k: k, l: l, type: type || "text" }; if (opts) x.opts = opts; return x }
var SPECS = {
    venue: { t: "Venue", fields: [f("name", "Name", "text"), f("area", "Neighbourhood", "text"), f("capacity", "Capacity", "num"),
                                  f("access", "Accessibility", "long"), f("tech", "Sound, lights, backline", "long"), f("deal", "Usual deal", "text"),
                                  f("contact", "Contact (shared with Lisboa members)", "text"), f("notes", "Notes", "long")], need: ["name"] },
    gear:  { t: "Gear", fields: [f("item", "What", "text"), f("qty", "How many", "num"), f("owner", "Lent by (collective)", "text"),
                                 f("contact", "Contact", "text"), f("notes", "Condition, pick-up, rules", "long")], need: ["item", "owner"] },
    crew:  { t: "Crew pool", fields: [f("name", "Your name", "text"), f("skills", "Skills", "multi", SKILLS), f("contact", "Contact", "text"),
                                      f("when", "When you're usually free", "text"), f("notes", "Notes (paid / volunteer, languages…)", "long")], need: ["name"] },
    borrow: { t: "Borrow", fields: [f("who", "Who's borrowing (collective)", "text"), f("from", "From (date)", "date"), f("to", "Until (date)", "date"),
                                    f("note", "Note for the lender", "long")], need: ["who", "from"] },
    poll:  { t: "Poll", fields: [f("q", "Question", "text"), f("options", "Options, one per line", "lines"), f("closes", "Closes (date, optional)", "date")], need: ["q", "options"] }
}
function clean(kind, cells) {
    var spec = SPECS[kind]; if (!spec) return { error: "Unknown kind." }
    var d = {}
    for (var i = 0; i < spec.fields.length; i++) {
        var c = spec.fields[i], v = cells ? cells[c.k] : undefined
        if (c.type === "num") {
            var s = String(v === undefined || v === null ? "" : v).trim()
            if (s === "") continue
            var n = Number(s); if (!isFinite(n) || n < 0) return { error: "%1 should be a number.", arg: c.l }
            d[c.k] = Math.round(n); continue
        }
        if (c.type === "multi") { var arr = Array.isArray(v) ? v.filter(function (x) { return c.opts.indexOf(x) >= 0 }) : []; if (arr.length) d[c.k] = arr; continue }
        if (c.type === "lines") {
            var ls = (Array.isArray(v) ? v : String(v || "").split("\n")).map(function (x) { return Ext.str(x).trim().slice(0, 80) }).filter(function (x) { return !!x })
            ls = ls.filter(function (x, i2) { return ls.indexOf(x) === i2 }).slice(0, 8)
            if (ls.length) d[c.k] = ls; continue
        }
        var t = Ext.str(v === undefined || v === null ? "" : String(v)).trim().slice(0, c.type === "long" ? 800 : 160)
        if (c.type === "date" && t && !/^\d{4}-\d{2}-\d{2}$/.test(t)) return { error: "Dates look like 2026-12-17." }
        if (t) d[c.k] = t
    }
    for (var j = 0; j < spec.need.length; j++) if (d[spec.need[j]] === undefined) return { error: "Fill in: %1", arg: spec.fields.filter(function (x) { return x.k === spec.need[j] })[0].l }
    if (kind === "poll" && d.options.length < 2) return { error: "A poll needs at least two options." }
    return { data: d }
}

// ── reading ──
function list(anchor, kind) {
    var out = Ext.itemsOf(anchor, kind)
    var key = kind === "venue" || kind === "crew" ? "name" : kind === "gear" ? "item" : "q"
    out.sort(function (a, b) { return Ext.str(a.d[key]).localeCompare(Ext.str(b.d[key])) })
    return out
}
function search(items, q) {
    q = String(q || "").trim().toLowerCase(); if (!q) return items
    var words = q.split(/\s+/)
    return items.filter(function (x) {
        var hay = Object.keys(x.d).map(function (k) { var v = x.d[k]; return Array.isArray(v) ? v.join(" ") : String(v) }).join(" ").toLowerCase()
        return words.every(function (w) { return hay.indexOf(w) >= 0 })
    })
}
// Venues you've used in your events that aren't in the directory yet (case-insensitive).
function missingVenues(usedNames, dirItems) {
    var have = {}; (dirItems || []).forEach(function (x) { have[Ext.str(x.d.name).trim().toLowerCase()] = true })
    return (usedNames || []).filter(function (n) { return n && !have[n.trim().toLowerCase()] })
}

// Borrow requests on a piece of gear, each with its latest reply ("pending" if none).
function borrowsOf(anchor, gearId) {
    var reqs = Ext.itemsOf(anchor, "borrow").filter(function (b) { return b.d.gear === gearId })
    var replies = Ext.extOf(anchor, "reply")
    return reqs.map(function (r) {
        var best = null
        for (var i = 0; i < replies.length; i++) { var d = Ext.dataOf(replies[i]); if (d.borrow !== r.id) continue; if (!best || Ext.wallOf(replies[i]) > Ext.wallOf(best)) best = replies[i] }
        return { id: r.id, author: r.author, d: r.d, status: best ? Ext.dataOf(best).status : "pending" }
    }).sort(function (a, b) { return Ext.str(a.d.from).localeCompare(Ext.str(b.d.from)) })
}
// Is the gear out on a day (yyyy-mm-dd)? An accepted request covering that day.
function outOn(anchor, gearId, day) {
    return borrowsOf(anchor, gearId).some(function (b) { return b.status === "ok" && Ext.str(b.d.from) <= day && day <= (Ext.str(b.d.to) || Ext.str(b.d.from)) })
}

// Polls (on the network anchor or any event): options with counts; my choice; open/closed.
function pollsOf(ev) { return Ext.itemsOf(ev, "poll").filter(function (p) { return Ext.str(p.d.q) && Array.isArray(p.d.options) && p.d.options.length >= 2 }) }
function tally(ev, poll, me, now) {
    var votes = Ext.extOf(ev, "vote"), latest = {}
    for (var i = 0; i < votes.length; i++) {
        var v = votes[i], d = Ext.dataOf(v); if (d.poll !== poll.id) continue
        var a = Ext.str(v.author); if (!latest[a] || Ext.wallOf(v) > Ext.wallOf(latest[a])) latest[a] = v
    }
    var counts = poll.d.options.map(function () { return 0 }), total = 0, mine = -1
    for (var who in latest) {
        var c = Ext.dataOf(latest[who]).choice
        if (typeof c !== "number" || c < 0 || c >= counts.length) continue
        counts[c]++; total++; if (who === me) mine = c
    }
    var closes = Ext.str(poll.d.closes), closed = false
    if (closes) { var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(closes); if (m) closed = new Date(+m[1], +m[2] - 1, +m[3], 23, 59, 59).getTime() < now }
    var max = Math.max.apply(null, counts.concat([0]))
    return { counts: counts, total: total, mine: mine, closed: closed, leaders: counts.map(function (c, i) { return c === max && max > 0 ? i : -1 }).filter(function (i) { return i >= 0 }) }
}
