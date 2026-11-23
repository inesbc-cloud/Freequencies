.pragma library
// Lisboa: what everyone sees.
//   "Lisboa" (community calendar): every promoter's public events; anyone adds, people edit their own.
//   Public listings: events announced on Luma (official "What's Happening in Lisbon" feed), fetched
//   every hour by each install through the freequencies_core module (Basecamp gives views no
//   network access) and shown in pink, read-only. Not stored in Scala: every install reads the
//   feed itself, so nobody's computer has to stay on.
// Pure functions, no Qt.
.import "ext.js" as Ext

var COMMUNITY = "fq_community"
var communityField = { key: COMMUNITY, label: "Freequencies community calendar", type: "text" }
var LISTINGS_CAL = "fq-listings"           // the calendar id public listings carry in the views
// Feeds freequencies_core can fetch (the addresses live in the module).
var SOURCES = [{ id: "luma-lisbon", label: "Luma" }]
// Share links of the shared calendars, built in so every install joins them. Filled in once the
// calendars exist (Calendar → Lisboa → copy join links).
var JOIN_LINKS = []

function hasField(c, key) {
    var sc = (c && c.schema) || []
    for (var i = 0; i < sc.length; i++) if (sc[i] && sc[i].key === key) return true
    return false
}
function isCommunityCal(c) { return hasField(c, COMMUNITY) }
function withField(schema, field) {
    var sc = (schema || []).slice()
    if (!hasField({ schema: sc }, field.key)) sc.push(field)
    return sc
}
function isListing(ev) { return !!ev && ev.calendarId === LISTINGS_CAL }

// ── iCal (RFC 5545, the parts feeds use) ──
function unescapeText(v) { return String(v).replace(/\\n/gi, "\n").replace(/\\([,;\\])/g, "$1") }
// 20261124T190000Z (UTC) · 20261124T190000 (local) · 20261124 (all day) → { ms, allDay }
function parseDate(v) {
    var m = /^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$/.exec(String(v).trim())
    if (!m) return null
    var y = +m[1], mo = +m[2] - 1, d = +m[3]
    if (m[4] === undefined) return { ms: new Date(y, mo, d).getTime(), allDay: true }
    var ms = m[7] ? Date.UTC(y, mo, d, +m[4], +m[5], +m[6]) : new Date(y, mo, d, +m[4], +m[5], +m[6]).getTime()
    return { ms: ms, allDay: false }
}
// Events from an .ics text, as calendar events of the listings layer. Cancelled ones are dropped.
function parseIcs(text, source) {
    var lines = String(text || "").replace(/\r\n/g, "\n").replace(/\n[ \t]/g, "").split("\n")
    var out = [], ev = null
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i]
        if (line === "BEGIN:VEVENT") { ev = {}; continue }
        if (line === "END:VEVENT") {
            if (ev && ev.uid && ev.start && ev.status !== "CANCELLED") {
                var end = ev.end && ev.end.ms > ev.start.ms ? ev.end.ms : ev.start.ms + 2 * 3600000
                out.push({ id: "listing:" + ev.uid, calendarId: LISTINGS_CAL, source: source || "", title: ev.title || "(untitled)",
                           description: ev.description || "", location: ev.location || "", url: ev.url || "",
                           startTime: ev.start.ms, endTime: end, allDay: ev.start.allDay, fields: {}, ext: [] })
            }
            ev = null; continue
        }
        if (!ev) continue
        var c = line.indexOf(":")
        if (c < 0) continue
        var name = line.slice(0, c).split(";")[0].toUpperCase(), value = line.slice(c + 1)
        if (name === "UID") ev.uid = value.trim()
        else if (name === "SUMMARY") ev.title = unescapeText(value).trim()
        else if (name === "DESCRIPTION") ev.description = unescapeText(value)
        else if (name === "LOCATION") ev.location = unescapeText(value).trim()
        else if (name === "URL") ev.url = value.trim()
        else if (name === "STATUS") ev.status = value.trim().toUpperCase()
        else if (name === "DTSTART") ev.start = parseDate(value)
        else if (name === "DTEND") ev.end = parseDate(value)
    }
    out.sort(function (a, b) { return a.startTime - b.startTime })
    return out
}

// The event's page on its platform: the first platform link in its text.
function linkOf(ev) {
    var txt = Ext.str(ev && ev.url) + " " + Ext.str(ev && ev.description) + " " + Ext.str(ev && ev.location)
    var m = /https:\/\/(?:lu\.ma|luma\.com|ra\.co|shotgun\.live)\/[^\s"<>)]+/.exec(txt)
    return m ? m[0] : ""
}
// The venue: Luma puts the address in LOCATION (or its own page link when it's hidden).
function venueOf(ev) {
    var l = Ext.str(ev && ev.location).trim()
    if (!l || /^https?:\/\//.test(l)) return ""
    return l.split(",")[0].trim()
}

// Share links the app should join: the built-in ones whose calendar this install doesn't have yet.
function linksToJoin(links, cals) {
    var have = {}
    ;(cals || []).forEach(function (c) { have[c.id] = true })
    return (links || []).filter(function (l) {
        var m = /[?&]id=([^&]+)/.exec(Ext.str(l))
        return m && !have[decodeURIComponent(m[1])]
    })
}
