.pragma library
// Tags on a night (#12): ext kind "tags" {tags: [string]}, one value per night (newest wins).
.import "ext.js" as Ext

var suggested = ["techno", "ambient", "live", "live coding", "workshop", "talk", "fundraiser", "outdoor", "free entry"]
function clean(t) { return String(t || "").trim().toLowerCase() }
function tagsOf(ev) {
    var d = Ext.latestData(ev, "tags"), t = d ? d.tags : null, out = []
    if (Array.isArray(t)) for (var i = 0; i < t.length; i++) { if (typeof t[i] !== "string") continue; var c = clean(t[i]); if (c && out.indexOf(c) < 0) out.push(c) }
    return out
}
function withTag(ev, t) { var cur = tagsOf(ev), c = clean(t); if (c && cur.indexOf(c) < 0) cur.push(c); return cur }
function withoutTag(ev, t) { var c = clean(t); return tagsOf(ev).filter(function (x) { return x !== c }) }
// Every tag in use across these nights, sorted.
function allTags(evs) {
    var seen = {}, out = []
    for (var i = 0; i < evs.length; i++) { var ts = tagsOf(evs[i]); for (var k = 0; k < ts.length; k++) if (!seen[ts[k]]) { seen[ts[k]] = true; out.push(ts[k]) } }
    return out.sort()
}
// Suggestions not yet on this night: the usual ones first, then the others in use.
function suggestions(ev, inUse, n) {
    var have = tagsOf(ev), out = []
    var all = suggested.concat(inUse || [])
    for (var i = 0; i < all.length && out.length < n; i++) if (have.indexOf(all[i]) < 0 && out.indexOf(all[i]) < 0) out.push(all[i])
    return out
}
