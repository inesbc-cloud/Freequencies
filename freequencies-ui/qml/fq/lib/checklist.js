.pragma library
// Checklists on a night: tasks with deadlines (#16), gear (#17), social posts (#19). One ext item
// each, edited by id (ADR 0009).
.import "ext.js" as Ext

// ── tasks (#16): ext kind "task" {text, due?, cat, done}
var taskCats = ["booking", "comms", "social", "payment", "contract", "print", "other"]
var DAY = 864e5
function tasksOf(ev) {
    var xs = Ext.itemsOf(ev, "task")
    xs.sort(function (a, b) { return (a.d.done === true) - (b.d.done === true) || (Ext.num(a.d.due) || 9e15) - (Ext.num(b.d.due) || 9e15) })
    return xs
}
function overdue(it, now) { return it.d.done !== true && Ext.num(it.d.due) !== null && it.d.due < now }
function dueSoon(it, now) { return it.d.done !== true && Ext.num(it.d.due) !== null && it.d.due >= now && it.d.due < now + 3 * DAY }
function openCount(ev) { return tasksOf(ev).filter(function (t) { return t.d.done !== true }).length }
function overdueCount(evs, now) {
    var n = 0
    for (var i = 0; i < evs.length; i++) { var ts = Ext.itemsOf(evs[i], "task"); for (var k = 0; k < ts.length; k++) if (overdue(ts[k], now)) n++ }
    return n
}
// The data for an item from the dialog: {data} or {error}. when = ms or null.
function parse(kind, text, when, extra) {
    text = String(text || "").trim()
    if (!text) return { error: "Write something first." }
    var d
    if (kind === "task") { d = { text: text, cat: extra.cat || "other", done: extra.done === true }; if (when !== null) d.due = when }
    else if (kind === "gear") d = { item: text, done: extra.done === true }
    else return { error: "Unknown kind " + kind }
    return { data: d }
}

// ── gear (#17): ext kind "gear" {item, done}
var gearPresets = ["CDJs", "Mixer", "Monitors", "Projector", "Mics", "Laptop stand", "Extension leads", "Install station"]
function gearOf(ev) {
    var xs = Ext.itemsOf(ev, "gear")
    xs.sort(function (a, b) { return (a.d.done === true) - (b.d.done === true) || Ext.str(a.d.item).localeCompare(Ext.str(b.d.item)) })
    return xs
}
function packedCount(ev) { return gearOf(ev).filter(function (g) { return g.d.done === true }).length }
// Presets not yet on the list (matched loosely: "CDJ-3000 ×2" covers "CDJs").
function missingPresets(ev, n) {
    var have = gearOf(ev).map(function (g) { return Ext.str(g.d.item).toLowerCase() })
    return gearPresets.filter(function (p) {
        var k = p.toLowerCase().replace(/s$/, "")
        return !have.some(function (h) { return h.indexOf(k) >= 0 })
    }).slice(0, n)
}
