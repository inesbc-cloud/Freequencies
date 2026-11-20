.pragma library
// The funding library: winning applications (with their documents) and links to funders and open
// calls, shared by everyone in a "Funding" calendar. Scala shows ext items only on events, so the
// library is one anchor event in that calendar; applications and links are ext items on it, and
// documents are the anchor's attachments (Logos Storage, sealed with the calendar key).
// Pure functions, no Qt.
.import "ext.js" as Ext

var MARKER = "fq_funding"                   // schema field key that marks a Funding calendar
var markerField = { key: MARKER, label: "Freequencies funding library", type: "text" }
var ANCHOR_TITLE = "Funding library"
var areas = ["Music", "Arts", "Culture", "Community", "Venue / space", "Touring", "Research", "Other"]

function isFundingCal(c) {
    var sc = (c && c.schema) || []
    for (var i = 0; i < sc.length; i++) if (sc[i] && sc[i].key === MARKER) return true
    return false
}
function fundingSchema(schema) {
    var sc = (schema || []).slice()
    if (!isFundingCal({ schema: sc })) sc.push(markerField)
    return sc
}
// The anchor: the oldest event in the calendar carrying the marker field (the first one created
// wins if two members set the library up at the same time).
function anchorOf(events, calId) {
    var best = null
    for (var i = 0; i < (events || []).length; i++) {
        var e = events[i]
        if (!e || e.calendarId !== calId || !e.fields || e.fields[MARKER] !== "anchor") continue
        if (!best || (e.startTime || 0) < (best.startTime || 0) || ((e.startTime || 0) === (best.startTime || 0) && e.id < best.id)) best = e
    }
    return best
}
function anchorEvent() {
    var f = {}; f[MARKER] = "anchor"
    // An all-day event on 1 Jan 2000: out of the way, and never shown (Funding calendars are hidden).
    return { title: ANCHOR_TITLE, startTime: Date.UTC(2000, 0, 1, 12), endTime: Date.UTC(2000, 0, 1, 13), allDay: true,
             description: "Holds the Freequencies funding library. Don't delete it.", location: "", url: "", reminderMin: 0, fields: f }
}

function clean(v, max) { return Ext.str(v).replace(/\s+/g, " ").trim().slice(0, max || 200) }
function isUrl(s) { return /^https?:\/\/[^\s]+\.[^\s]+$/i.test(s) }
function yearOk(y) { return /^\d{4}$/.test(y) && Number(y) >= 1950 && Number(y) <= 2100 }

// A winning application: what was funded, by whom, when, how much, and the documents.
function appData(f) {
    f = f || {}
    var d = { title: clean(f.title, 160), funder: clean(f.funder, 120) }
    if (!d.title) return { error: "Name the project that was funded." }
    if (!d.funder) return { error: "Who funded it?" }
    var y = clean(f.year, 4); if (y) { if (!yearOk(y)) return { error: "Year like 2025." }; d.year = Number(y) }
    var a = String(f.amount === undefined || f.amount === null ? "" : f.amount).replace(/[\s,]/g, "").trim()
    if (a !== "") { var n = Number(a); if (!isFinite(n) || n < 0) return { error: "Amount is a number, like 15000." }; d.amount = n; d.currency = clean(f.currency, 8) || "EUR" }
    var area = clean(f.area, 40); if (area) d.area = area
    var who = clean(f.applicant, 120); if (who) d.applicant = who
    var notes = Ext.str(f.notes).trim().slice(0, 2000); if (notes) d.notes = notes
    var url = clean(f.url, 400); if (url) { if (!isUrl(url)) return { error: "The link should start with https://" }; d.url = url }
    var docs = Array.isArray(f.docs) ? f.docs : [], out = []
    for (var i = 0; i < docs.length; i++) { var x = docs[i]; if (x && Ext.str(x.cid)) out.push({ cid: x.cid, name: clean(x.name, 160) || "document" }) }
    if (out.length) d.docs = out
    return { data: d }
}
// A funder or open call.
function linkData(f) {
    f = f || {}
    var d = { name: clean(f.name, 160), url: clean(f.url, 400) }
    if (!d.name) return { error: "Name the funder or call." }
    if (!isUrl(d.url)) return { error: "Add the link, starting with https://" }
    var dl = clean(f.deadline, 10)
    if (dl) {
        var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dl)
        if (!m || new Date(+m[1], +m[2] - 1, +m[3]).getMonth() !== +m[2] - 1) return { error: "Deadline like 2027-01-31, or leave it empty." }
        d.deadline = dl
    }
    var amt = clean(f.amount, 60); if (amt) d.amount = amt          // free text: "up to 20 000 EUR"
    var area = clean(f.area, 40); if (area) d.area = area
    if (f.rolling === true) d.rolling = true
    var notes = Ext.str(f.notes).trim().slice(0, 1000); if (notes) d.notes = notes
    return { data: d }
}

function appsOf(anchor) {
    var out = Ext.itemsOf(anchor, "fund-app").filter(function (x) { return !!Ext.str(x.d.title) })
    out.sort(function (a, b) { return (Number(b.d.year) || 0) - (Number(a.d.year) || 0) || Ext.str(a.d.title).localeCompare(Ext.str(b.d.title)) })
    return out
}
// Deadline state on a given day (ms): "open", "soon" (≤ 14 days), "closed", or "" (no deadline).
function deadlineState(d, now) {
    if (!d || !d.deadline) return d && d.rolling ? "open" : ""
    var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(d.deadline)
    if (!m) return ""
    var end = new Date(+m[1], +m[2] - 1, +m[3], 23, 59, 59).getTime()
    if (end < now) return "closed"
    return end - now <= 14 * 86400000 ? "soon" : "open"
}
function daysLeft(d, now) {
    var m = d && /^(\d{4})-(\d{2})-(\d{2})$/.exec(d.deadline || "")
    if (!m) return null
    return Math.ceil((new Date(+m[1], +m[2] - 1, +m[3], 23, 59, 59).getTime() - now) / 86400000)
}
// Open calls first, soonest deadline first; then rolling and undated; closed last.
function linksOf(anchor, now) {
    var out = Ext.itemsOf(anchor, "fund-link").filter(function (x) { return !!Ext.str(x.d.name) && isUrl(Ext.str(x.d.url)) })
    function rank(x) { var s = deadlineState(x.d, now); return s === "soon" || s === "open" ? (x.d.deadline ? 0 : 1) : s === "" ? 1 : 2 }
    out.sort(function (a, b) { return rank(a) - rank(b) || Ext.str(a.d.deadline || "9999").localeCompare(Ext.str(b.d.deadline || "9999")) || Ext.str(a.d.name).localeCompare(Ext.str(b.d.name)) })
    return out
}
// Search across the words people would type: project, funder, area, applicant, notes, year.
function matches(x, q) {
    q = String(q || "").trim().toLowerCase()
    if (!q) return true
    var d = x.d || {}
    var hay = [d.title, d.funder, d.area, d.applicant, d.notes, d.name, d.amount, d.year].map(function (v) { return v === undefined ? "" : String(v) }).join(" ").toLowerCase()
    var words = q.split(/\s+/)
    for (var i = 0; i < words.length; i++) if (hay.indexOf(words[i]) < 0) return false
    return true
}
function amountLabel(d) {
    if (!d || typeof d.amount !== "number") return ""
    var s = String(Math.round(d.amount)).replace(/\B(?=(\d{3})+(?!\d))/g, " ")
    return s + " " + (d.currency || "EUR")
}
// A document is the anchor's attachment with that CID (still there = still downloadable).
function docAvailable(anchor, cid) {
    var a = (anchor && Array.isArray(anchor.attachments)) ? anchor.attachments : []
    for (var i = 0; i < a.length; i++) if (a[i] && a[i].storageCid === cid) return true
    return false
}
