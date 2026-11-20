.pragma library
// The timeline (#23): occurrences grouped by month, upcoming first or most recent first.
function monthKey(t) { var d = new Date(t); return d.getFullYear() * 12 + d.getMonth() }
function group(occs, past) {
    var xs = occs.slice().sort(function (a, b) { return past ? b.startTime - a.startTime : a.startTime - b.startTime })
    var out = [], cur = null
    for (var i = 0; i < xs.length; i++) {
        var k = monthKey(xs[i].startTime)
        if (!cur || cur.key !== k) { cur = { key: k, first: xs[i].startTime, occs: [] }; out.push(cur) }
        cur.occs.push(xs[i])
    }
    return out
}
// The window: a year ahead from today, or the year before it.
function window_(now, past) {
    var d = new Date(now); d.setHours(0, 0, 0, 0)
    var a = d.getTime(), y = new Date(d); y.setFullYear(y.getFullYear() + (past ? -1 : 1))
    return past ? [y.getTime(), a] : [a, y.getTime()]
}
