.pragma library
// Freequencies calendars and nights (ADR 0001): the Status / Venue / Type fields, and which Scala
// calendars carry them. Pure functions, no Qt: unit-tested in Node (freequencies-ui/test).

var statuses = ["Hold", "Confirmed", "Cancelled"]
// Kinds of event. New ones go before "Other"; a calendar adopted earlier keeps its own option list,
// and a night may still carry any of these as its type.
var types = ["Club night", "Concert", "Residency", "Live set", "Workshop", "Talk", "Screening", "Community", "Festival", "Other"]
var freqFields = [
    { key: "status", label: "Status", type: "enum", options: statuses },
    { key: "venue", label: "Venue", type: "text" },
    { key: "type", label: "Type", type: "enum", options: types }
]

function str(v) { return typeof v === "string" ? v : "" }
function fieldOf(ev, k) { return (ev && ev.fields && typeof ev.fields[k] === "string") ? ev.fields[k] : "" }

function statusFieldOf(c) {
    var sc = (c && c.schema) || []
    for (var i = 0; i < sc.length; i++) if (sc[i] && sc[i].key === "status") return sc[i]
    return null
}
// A Freequencies `status` field: a choice offering Hold, Confirmed and Cancelled. A `status` of
// another shape belongs to someone else's convention and is left alone.
function isFreqStatusField(f) {
    if (!f || f.type !== "enum" || !Array.isArray(f.options)) return false
    for (var i = 0; i < statuses.length; i++) if (f.options.indexOf(statuses[i]) < 0) return false
    return true
}
function isFreqCal(c) { return isFreqStatusField(statusFieldOf(c)) }

// Owners and editors may change a calendar's fields.
function isEditorOf(c) {
    if (!c) return false
    var me = c.authorAddr || ""
    if (!me) return false
    if (c.owner === me) return true
    var r = c.roles || {}
    return r[me] === "editor" || r[me] === "admin"
}
// My role on a calendar, for the sidebar.
function roleOf(c) {
    if (!c) return ""
    var me = c.authorAddr || ""
    if (me && c.owner === me) return "owner"
    var r = (c.roles || {})[me]
    return r === "admin" ? "editor" : (r || (c.collab ? "member" : "viewer"))
}
// May I change this night? Editors always; viewers never; members on collaborative calendars or their own nights.
function canEdit(ev, c) {
    if (!c || !ev) return false
    if (isEditorOf(c)) return true
    var me = c.authorAddr || "", r = (c.roles || {})[me]
    if (r === "viewer") return false
    return c.collab === true || (!!ev.creatorId && ev.creatorId === me)
}

// Why "Use for Freequencies" can't adopt this calendar ("" = it can).
function adoptBlocker(c) {
    if (!isEditorOf(c)) return "Only its owner or editors can add Freequencies fields"
    var sf = statusFieldOf(c)
    if (sf && !isFreqStatusField(sf)) return "Has its own “status” field, so Freequencies leaves it alone"
    var sc = (c && c.schema) || []
    for (var i = 0; i < sc.length; i++) {
        var f = sc[i]
        if (f && f.key === "venue" && f.type && f.type !== "text") return "Has its own “venue” field of another kind"
        if (f && f.key === "type" && f.type && f.type !== "enum") return "Has its own “type” field of another kind"
    }
    return ""
}
// The calendar's schema with the Freequencies fields added (its own fields kept, nothing replaced).
function adoptedSchema(schema) {
    var sc = (schema || []).slice()
    for (var i = 0; i < freqFields.length; i++) {
        var have = false
        for (var k = 0; k < sc.length; k++) if (sc[k] && sc[k].key === freqFields[i].key) have = true
        if (!have) sc.push(freqFields[i])
    }
    return sc
}
