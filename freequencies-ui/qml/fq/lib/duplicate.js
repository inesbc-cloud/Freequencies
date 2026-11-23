.pragma library
// Duplicate a night (#22): one week later, as a Hold. The line-up is asked again, crew roles come
// back as open slots, gear unpacked, tags kept. Not tasks, budget, tickets, files or comments.
.import "ext.js" as Ext
.import "lineup.js" as Lineup
.import "crew.js" as Crew
.import "checklist.js" as Checklist
.import "tags.js" as Tags

var WEEK = 7 * 864e5
var repeatOpts = [{ l: "Once", f: "", i: 1 }, { l: "Weekly", f: "weekly", i: 1 }, { l: "Every 2 weeks", f: "weekly", i: 2 }, { l: "Monthly", f: "monthly", i: 1 }]
function repeatLabel(ev) {
    var r = ev && ev.recur
    if (!r || !r.freq) return "Once"
    for (var i = 0; i < repeatOpts.length; i++) if (repeatOpts[i].f === r.freq && repeatOpts[i].i === Math.max(1, r.interval || 1)) return repeatOpts[i].l
    return ""
}
// The new event (for createEvent) and the ext items to post on it once it exists.
function copyOf(m) {
    var ev = { title: m.title || "Untitled event", startTime: m.startTime + WEEK, endTime: (m.endTime || m.startTime) + WEEK, reminderMin: 60,
               fields: { status: "Hold", venue: Ext.str(m.fields && m.fields.venue), type: Ext.str(m.fields && m.fields.type) || "Club night" } }
    if (m.description) ev.description = m.description
    var items = []
    var lu = Lineup.lineupOf(m)
    for (var i = 0; i < lu.length; i++) if (lu[i].status !== "cancelled")
        items.push({ kind: "artist", data: Lineup.bookingData(lu[i].name, "asked", lu[i].contact, lu[i].book, lu[i].fee, lu[i].currency, lu[i].set) })
    var cr = Crew.crewOf(m)
    for (var c = 0; c < cr.length; c++) if (cr[c].role && cr[c].status !== "cancelled") {
        var cd = { name: "", role: cr[c].role, status: "asked" }; if (cr[c].call) cd.call = cr[c].call
        items.push({ kind: "crew", data: cd })
    }
    var gs = Checklist.gearOf(m)
    for (var g = 0; g < gs.length; g++) items.push({ kind: "gear", data: { item: Ext.str(gs[g].d.item), done: false } })
    var tg = Tags.tagsOf(m)
    if (tg.length) items.push({ kind: "tags", data: { tags: tg } })
    return { event: ev, items: items }
}
