.pragma library
// The board (#9; from prototypes/lanes/lanes.ts): days down, lanes across. A lane is a venue, a
// status or a calendar. Pure: occurrences in, {lanes, days} out.
.import "nights.js" as Nights

function laneOf(o, by) {
    if (by === "calendar") return o.calendarId
    var v = Nights.fieldOf(o, by)
    return v === "" ? "—" : v
}
function dayStart(t0, n) { var d = new Date(t0); d.setDate(d.getDate() + n); return d.getTime() }

// occs: expanded occurrences; by: "venue" | "status" | "calendar"; first: local midnight (ms);
// nDays: rows; cals: [{id, name}] for calendar lanes.
function buildLanes(occs, by, first, nDays, cals) {
    var lanes = [], index = {}
    function addLane(id, label) { if (index[id] === undefined) { index[id] = lanes.length; lanes.push({ id: id, label: label }) } }
    if (by === "calendar") for (var i = 0; i < cals.length; i++) addLane(cals[i].id, cals[i].name || "(unnamed)")
    else if (by === "status") for (var s = 0; s < Nights.statuses.length; s++) addLane(Nights.statuses[s], Nights.statuses[s])
    var end = dayStart(first, nDays), inWin = []
    for (var a = 0; a < occs.length; a++) if (occs[a].startTime >= first && occs[a].startTime < end) inWin.push(occs[a])
    var noValue = false
    for (var b = 0; b < inWin.length; b++) { var id = laneOf(inWin[b], by); if (id === "—") { noValue = true; continue } addLane(id, id) }
    if (noValue) addLane("—", by === "venue" ? "No venue" : "—")
    var days = []
    for (var c = 0; c < nDays; c++) { var cells = []; for (var e = 0; e < lanes.length; e++) cells.push([]); days.push({ date: dayStart(first, c), cells: cells }) }
    for (var g = 0; g < inWin.length; g++) {
        var dd = new Date(inWin[g].startTime); dd.setHours(0, 0, 0, 0)
        var row = -1
        for (var r = 0; r < days.length; r++) if (days[r].date === dd.getTime()) { row = r; break }
        var col = index[laneOf(inWin[g], by)]
        if (row >= 0 && col !== undefined) days[row].cells[col].push(inWin[g])
    }
    return { lanes: lanes, days: days }
}
