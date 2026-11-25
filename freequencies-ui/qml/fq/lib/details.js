.pragma library
// The quick new-night form and a night's optional details. The essentials (name, date, venue,
// times, line-up) are a normal Scala event plus "artist" items; everything else optional rides in
// one "details" ext item (newest wins, like tags and tickets). Pure functions, no Qt.
.import "ext.js" as Ext

// Kinds of event are Nights.types (the calendar's "type" field).
var ages = ["All ages", "16+", "18+"]
var audiences = ["Under 50", "50–150", "150–300", "300–600", "600+"]

// "DJ A, DJ B" or one name per line → unique, trimmed names (case-insensitive), in order.
function parseLineup(text) {
    var parts = String(text || "").split(/[\n,;]+/), out = [], seen = {}
    for (var i = 0; i < parts.length; i++) {
        var n = parts[i].replace(/\s+/g, " ").trim()
        if (!n || n.length > 120) continue
        var k = n.toLowerCase()
        if (seen[k]) continue
        seen[k] = true; out.push(n)
    }
    return out
}

// "21:30" / "9:05" / "2130" → {h, m}, or null.
function parseTime(s) {
    var t = String(s || "").trim(), m = /^(\d{1,2})[:.h]?(\d{2})$/.exec(t)
    if (!m) return null
    var h = Number(m[1]), mi = Number(m[2])
    if (h > 23 || mi > 59) return null
    return { h: h, m: mi }
}
// "2026-11-28" → {y, mo, d}, or null.
function parseDate(s) {
    var m = /^(\d{4})-(\d{1,2})-(\d{1,2})$/.exec(String(s || "").trim())
    if (!m) return null
    var y = Number(m[1]), mo = Number(m[2]), d = Number(m[3])
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null
    var probe = new Date(y, mo - 1, d)
    if (probe.getMonth() !== mo - 1) return null
    return { y: y, mo: mo, d: d }
}
// Start and end in local time. A night that ends at or before it starts ends the next day (club nights).
function timesOf(dateStr, startStr, endStr) {
    var d = parseDate(dateStr)
    if (!d) return { error: "Pick a date like 2026-11-28." }
    var s = parseTime(startStr)
    if (!s) return { error: "Start time like 22:00." }
    var e = endStr && String(endStr).trim() ? parseTime(endStr) : null
    if (endStr && String(endStr).trim() && !e) return { error: "End time like 04:00, or leave it empty." }
    var start = new Date(d.y, d.mo - 1, d.d, s.h, s.m, 0, 0).getTime()
    var end
    if (e) {
        end = new Date(d.y, d.mo - 1, d.d, e.h, e.m, 0, 0).getTime()
        if (end <= start) end = new Date(d.y, d.mo - 1, d.d + 1, e.h, e.m, 0, 0).getTime()
    } else end = start + 4 * 3600000
    return { start: start, end: end }
}

function clean(v, max) { return Ext.str(v).replace(/\s+/g, " ").trim().slice(0, max || 200) }

// The optional details, cleaned. Empty values are dropped; price is a number ≥ 0 or absent.
function detailsData(f) {
    f = f || {}
    var d = {}
    var aud = clean(f.audience, 40); if (aud) d.audience = aud
    if (f.free === true) d.free = true
    else {
        var p = String(f.price === undefined || f.price === null ? "" : f.price).replace(",", ".").trim()
        if (p !== "") {
            var n = Number(p)
            if (!isFinite(n) || n < 0) return { error: "Ticket price is a number, like 8 or 12.50." }
            d.price = Math.round(n * 100) / 100
            d.currency = clean(f.currency, 8) || "EUR"
        }
    }
    var age = clean(f.age, 20); if (age) d.age = age
    var acc = clean(f.access, 400); if (acc) d.access = acc
    var link = clean(f.link, 400)
    if (link) {
        if (!/^https?:\/\/\S+$/i.test(link)) return { error: "The link should start with https://" }
        d.link = link
    }
    return { data: d }
}
function isEmpty(d) { for (var k in d) return false; return true }

// What the form writes: the event, then one item per artist and (if any) the details item.
// The status starts as Hold; kind of event goes in the calendar's "type" field.
function quickNight(f) {
    f = f || {}
    var title = clean(f.title, 160)
    if (!title) return { error: "Give the event a name." }
    var t = timesOf(f.date, f.start, f.end)
    if (t.error) return t
    var det = detailsData(f)
    if (det.error) return det
    var fields = { status: f.status || "Hold", venue: clean(f.venue, 160) }
    if (f.kind) fields.type = clean(f.kind, 40)
    var ev = { title: title, startTime: t.start, endTime: t.end, allDay: false, description: Ext.str(f.notes).trim(),
               location: fields.venue, url: "", reminderMin: 60, fields: fields }
    var items = []
    var names = parseLineup(f.lineup)
    for (var i = 0; i < names.length; i++) items.push({ kind: "artist", data: { name: names[i], status: "asked" } })
    if (!isEmpty(det.data)) items.push({ kind: "details", data: det.data })
    return { event: ev, items: items }
}

function detailsOf(night) { return Ext.latestData(night, "details") || {} }
function priceLabel(d, tr) {
    if (!d) return ""
    if (d.free === true) return tr ? tr("Free") : "Free"
    if (typeof d.price === "number") return d.price + (d.currency ? " " + d.currency : "")
    return ""
}
// One line for cards and the panel: "150–300 · 8 EUR · 18+".
function summary(d, tr) {
    if (!d) return ""
    return [d.audience ? (tr ? tr("%1 expected", [d.audience]) : d.audience + " expected") : "", priceLabel(d, tr), d.age ? (tr ? tr(d.age) : d.age) : ""].filter(function (x) { return !!x }).join(" · ")
}
