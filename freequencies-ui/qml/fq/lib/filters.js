.pragma library
// Search and filters for nights (#24). Scala's search looks in title, location, notes, calendar and
// field values; nights add artists, crew and tags. Filters: status (several), type, tag, venue.
.import "nights.js" as Nights
.import "lineup.js" as Lineup
.import "crew.js" as Crew
.import "tags.js" as Tags

function empty() { return { status: {}, type: "", tag: "", venue: "" } }
function isEmpty(f) { return !f || (Object.keys(f.status || {}).length === 0 && !f.type && !f.tag && !f.venue) }
function withStatus(f, s) { var st = {}; for (var k in f.status) st[k] = true; if (st[s]) delete st[s]; else st[s] = true; return { status: st, type: f.type, tag: f.tag, venue: f.venue } }
function with_(f, key, v) { var o = { status: f.status, type: f.type, tag: f.tag, venue: f.venue }; o[key] = (o[key] === v ? "" : v); return o }
// Does a night pass? Events without Freequencies fields pass only an empty filter.
function matches(ev, f) {
    if (isEmpty(f)) return true
    if (Object.keys(f.status).length && !f.status[Nights.fieldOf(ev, "status")]) return false
    if (f.type && Nights.fieldOf(ev, "type") !== f.type) return false
    if (f.venue && Nights.fieldOf(ev, "venue").trim().toLowerCase() !== f.venue.trim().toLowerCase()) return false
    if (f.tag && Tags.tagsOf(ev).indexOf(f.tag) < 0) return false
    return true
}
// More words for Scala's search: the line-up, the crew and the tags.
function extraHay(ev) {
    return " " + Lineup.lineupOf(ev).map(function (b) { return b.name }).join(" ")
         + " " + Crew.crewOf(ev).map(function (c) { return c.name + " " + c.role }).join(" ")
         + " " + Tags.tagsOf(ev).join(" ")
}
