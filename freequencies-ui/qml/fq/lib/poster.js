.pragma library
// The poster (#15): ext kind "poster" {url} (an image link) or {cid, name} (an attachment), newest wins.
.import "ext.js" as Ext

function posterOf(ev) { var d = Ext.latestData(ev, "poster"); return d && (Ext.str(d.url) || Ext.str(d.cid)) ? d : null }
function isLink(u) { return /^(https?|file):\/\//i.test(Ext.str(u)) }
// What to load: {src} for a link, {cid, name} to fetch from Logos Storage, or null.
function sourceOf(ev) {
    var p = posterOf(ev)
    if (!p) return null
    if (isLink(p.url)) return { src: p.url }
    if (Ext.str(p.cid)) return { cid: p.cid, name: Ext.str(p.name) || "poster" }
    return null
}
