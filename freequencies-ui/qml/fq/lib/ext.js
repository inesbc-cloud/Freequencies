.pragma library
// Freequencies data on a night: Scala `ext` items with ns "xyz.freequencies" (ADR 0009). Pure helpers.

var NS = "xyz.freequencies"
function str(v) { return typeof v === "string" ? v : "" }
function num(v) { return (typeof v === "number" && isFinite(v)) ? v : null }
function dataOf(x) { return (x && x.data && typeof x.data === "object" && !Array.isArray(x.data)) ? x.data : {} }
function wallOf(x) { var h = (x && x.hlc && typeof x.hlc === "object") ? x.hlc : {}; return (typeof h.wall === "number" ? h.wall : 0) * 1000 + (typeof h.ctr === "number" ? h.ctr : 0) }
function rnd() { return Math.random().toString(36).slice(2, 10) }

// Freequencies items of one kind on a night.
function extOf(ev, kind) {
    var xs = (ev && Array.isArray(ev.ext)) ? ev.ext : [], out = []
    for (var i = 0; i < xs.length; i++) { var x = xs[i]; if (x && x.ns === NS && x.kind === kind && str(x.id)) out.push(x) }
    return out
}
// One value per night (tags, tickets, poster): the newest item wins, whoever wrote it. A write posts a
// fresh id and retires the writer's own older items, so nobody edits someone else's item and a deleted
// id is never reused (Scala keeps deleted ids deleted).
function latestOf(ev, kind) {
    var xs = extOf(ev, kind), best = null
    for (var i = 0; i < xs.length; i++) {
        var w = wallOf(xs[i]), bw = best ? wallOf(best) : -1
        if (!best || w > bw || (w === bw && xs[i].id > best.id)) best = xs[i]
    }
    return best
}
function latestData(ev, kind) { var x = latestOf(ev, kind); return x ? dataOf(x) : null }
// Lists (tasks, gear, budget lines, posts): one item each, edited by id.
function itemsOf(ev, kind) {
    var xs = extOf(ev, kind), out = []
    for (var i = 0; i < xs.length; i++) out.push({ id: str(xs[i].id), author: str(xs[i].author), d: dataOf(xs[i]) })
    return out
}
function item(kind, target, data, id) { var it = { ns: NS, kind: kind, target: target, data: data }; if (id) it.id = id; return it }
function freshId(kind, nightId) { return kind + ":" + nightId + ":" + rnd() }
