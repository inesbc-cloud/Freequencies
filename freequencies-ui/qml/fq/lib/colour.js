.pragma library
// Colour by status / type / venue / calendar (#6). Pure: the palette comes in from Fq.qml.
.import "nights.js" as Nights

var modes = [{ id: "status", label: "Status" }, { id: "type", label: "Type" }, { id: "venue", label: "Venue" }, { id: "calendar", label: "Calendar" }]

function hashIndex(s, n) { var h = 0; s = String(s || ""); for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0; return h % n }
function statusColor(s, pal) { return s === "Confirmed" ? pal.confirmed : s === "Cancelled" ? pal.cancelled : s === "Hold" ? pal.hold : pal.faint }
function typeColor(t, pal) { var i = Nights.types.indexOf(t); return i < 0 ? pal.faint : pal.swatch[i % pal.swatch.length] }
function venueColor(v, pal) { return v ? pal.swatch[hashIndex(String(v).trim().toLowerCase(), pal.swatch.length)] : pal.faint }

// The colour of a night. Events of non-Freequencies calendars keep their calendar's colour (calColor).
function nightColor(ev, by, pal, calColor, isFreq) {
    if (by === "calendar" || !isFreq) return calColor
    if (by === "type") return typeColor(Nights.fieldOf(ev, "type"), pal)
    if (by === "venue") return venueColor(Nights.fieldOf(ev, "venue"), pal)
    return statusColor(Nights.fieldOf(ev, "status"), pal)
}
// What the legend shows for a mode. venues: names in use; cals: [{id,name}] with their colour.
function legend(by, pal, venues, cals, calColorOf) {
    var out = [], i
    if (by === "status") for (i = 0; i < Nights.statuses.length; i++) out.push({ label: Nights.statuses[i], color: statusColor(Nights.statuses[i], pal) })
    else if (by === "type") for (i = 0; i < Nights.types.length; i++) out.push({ label: Nights.types[i], color: typeColor(Nights.types[i], pal) })
    else if (by === "venue") for (i = 0; i < venues.length && i < 8; i++) out.push({ label: venues[i], color: venueColor(venues[i], pal) })
    else for (i = 0; i < cals.length; i++) out.push({ label: cals[i].name || "(unnamed)", color: calColorOf(cals[i].id) })
    return out
}
