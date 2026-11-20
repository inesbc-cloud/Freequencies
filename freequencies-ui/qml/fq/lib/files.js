.pragma library
// Files on a night (#14): Scala's own `attachments` (Logos Storage, sealed with the calendar key),
// plus a members-only / community flag per file: ext kind "file" {cid, visibility}, newest wins per cid.
.import "ext.js" as Ext

function filesOf(ev) { return (ev && Array.isArray(ev.attachments)) ? ev.attachments.filter(function (a) { return a && Ext.str(a.storageCid) }) : [] }
function visibilityOf(ev, cid) {
    var xs = Ext.extOf(ev, "file"), best = null
    for (var i = 0; i < xs.length; i++) if (Ext.str(Ext.dataOf(xs[i]).cid) === cid && (!best || Ext.wallOf(xs[i]) > Ext.wallOf(best))) best = xs[i]
    return best && Ext.str(Ext.dataOf(best).visibility) === "public" ? "public" : "private"
}
function isImage(a) { return /^image\//.test(Ext.str(a && a.mime)) || /\.(png|jpe?g|gif|webp)$/i.test(Ext.str(a && a.name)) }
function humanSize(n) { n = n || 0; if (n < 1024) return n + " B"; if (n < 1048576) return (n / 1024).toFixed(1) + " KB"; return (n / 1048576).toFixed(1) + " MB" }
function without(atts, cid) { return (Array.isArray(atts) ? atts : []).filter(function (x) { return !(x && x.storageCid === cid) }) }
