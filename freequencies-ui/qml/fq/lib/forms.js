.pragma library
// WhisperBox forms on a night (#20, ADR 0005): ext kind "form" {formId, uri, purpose, title}.
.import "ext.js" as Ext

var purposes = [{ id: "booking", label: "Artist booking" }, { id: "crew", label: "Crew sign-up" },
                { id: "guestlist", label: "Guest list" }, { id: "feedback", label: "Feedback" }]
function purposeLabel(p) { for (var i = 0; i < purposes.length; i++) if (purposes[i].id === p) return purposes[i].label; return "Form" }
function formsOf(ev) {
    var xs = Ext.extOf(ev, "form"), out = []
    for (var i = 0; i < xs.length; i++) {
        var d = Ext.dataOf(xs[i]), fid = Ext.str(d.formId)
        if (!fid) continue
        out.push({ id: Ext.str(xs[i].id), author: Ext.str(xs[i].author), formId: fid, uri: Ext.str(d.uri), purpose: Ext.str(d.purpose), title: Ext.str(d.title) })
    }
    return out
}
// One line under a form: purpose · open/closed · answers (counts only for forms I can read).
function formLine(f, sm, wbState) {
    if (!sm) return purposeLabel(f.purpose) + (wbState === "missing" ? " · WhisperBox isn't answering" : " · syncing…")
    var parts = [purposeLabel(f.purpose), Ext.str(sm.status) === "closed" ? "Closed" : "Open"]
    if (sm.canRead === true) {
        var n = typeof sm.responses === "number" ? sm.responses : 0
        parts.push(n + (n === 1 ? " response" : " responses"))
        if (typeof sm.newResponses === "number" && sm.newResponses > 0) parts.push(sm.newResponses + " new")
    } else parts.push("answers go to its creator")
    return parts.join(" · ")
}
function formTitle(f, sm, w) { return (sm && Ext.str(sm.title)) || (w && Ext.str(w.title)) || f.title || purposeLabel(f.purpose) }
function answerText(q, v) {
    if (v === null || v === undefined || v === "") return "—"
    var opts = (q && Array.isArray(q.options)) ? q.options : []
    function one(x) { if (typeof x === "number" && opts[x] !== undefined) return String(opts[x]); if (x && typeof x === "object" && typeof x.other === "string") return x.other; return String(x) }
    if (Array.isArray(v)) return v.map(one).join(", ")
    if (typeof v === "boolean") return v ? "Yes" : "No"
    return one(v)
}
