.pragma library
// Home: what needs you. Reads the nights (occurrences, each carrying its series' ext items), the
// funding library's links and the clock, and lists what to look at, most urgent first. Pure, no Qt.
.import "ext.js" as Ext
.import "nights.js" as Nights
.import "lineup.js" as Lineup
.import "checklist.js" as Checklist
.import "production.js" as Production
.import "funding.js" as Funding

var DAY = 86400000

// Upcoming occurrences in the next `days`, soonest first (cancelled ones left out).
function upcoming(occs, now, days) {
    return (occs || []).filter(function (o) {
        return o && o.startTime >= now - 6 * 3600000 && o.startTime <= now + days * DAY && Nights.fieldOf(o, "status") !== "Cancelled"
    }).sort(function (a, b) { return a.startTime - b.startTime })
}

// One entry: { tone: "red"|"warn"|"info", text, sub, when, occ? , link? }
function attention(occs, anchor, now, tr) {
    tr = tr || function (s, a) { var o = s; (a || []).forEach(function (v, i) { o = o.split("%" + (i + 1)).join(String(v)) }); return o }
    var out = [], seenSeries = {}
    var list = upcoming(occs, now, 60)
    for (var i = 0; i < list.length; i++) {
        var o = list[i], title = o.title || "(untitled)", days = (o.startTime - now) / DAY
        var status = Nights.fieldOf(o, "status")
        if (status === "Hold" && days <= 21) out.push({ tone: days <= 7 ? "red" : "warn", text: tr("%1 is still on hold", [title]), sub: tr("Confirm it or let the date go."), when: o.startTime, occ: o })
        if (!Nights.fieldOf(o, "venue").trim() && days <= 30) out.push({ tone: "warn", text: tr("%1 has no venue yet", [title]), sub: "", when: o.startTime, occ: o })
        if (Lineup.lineupOf(o).length === 0 && days <= 21) out.push({ tone: "info", text: tr("%1 has no line-up yet", [title]), sub: "", when: o.startTime, occ: o })
        // per series once: its tasks, milestones and posts live on the series, not the occurrence
        var sid = o.seriesId || o.id
        if (seenSeries[sid]) continue
        seenSeries[sid] = true
        var tasks = Checklist.tasksOf(o)
        for (var t = 0; t < tasks.length; t++) {
            if (Checklist.overdue(tasks[t], now)) out.push({ tone: "red", text: Ext.str(tasks[t].d.text) || tr("A task"), sub: tr("Overdue · %1", [title]), when: tasks[t].d.due, occ: o })
            else if (Checklist.dueSoon(tasks[t], now)) out.push({ tone: "warn", text: Ext.str(tasks[t].d.text) || tr("A task"), sub: tr("Due soon · %1", [title]), when: tasks[t].d.due, occ: o })
        }
        // milestones: overdue ones fold into one line per night when there are several
        var ms = Production.dueMilestones(o, now, 7)
        var late = ms.filter(function (x) { return x.overdue }), next = ms.filter(function (x) { return !x.overdue })
        if (late.length > 2) out.push({ tone: "red", text: tr("%1 production milestones overdue", [late.length]), sub: tr("%1 · from “%2”", [title, late[0].task]), when: late[0].due, occ: o, prod: true })
        else for (var m = 0; m < late.length; m++) out.push({ tone: "red", text: late[m].task || tr("A milestone"), sub: tr("Overdue · %1", [title]), when: late[m].due, occ: o, prod: true })
        for (var q = 0; q < next.length; q++) out.push({ tone: "warn", text: next[q].task || tr("A milestone"), sub: tr("Due soon · %1", [title]), when: next[q].due, occ: o, prod: true })
        var posts = Checklist.postsOf(o)
        for (var p = 0; p < posts.length; p++)
            if (Checklist.postDueSoon(posts[p], now)) out.push({ tone: "info", text: (Ext.str(posts[p].d.text) || tr("A post")) + (posts[p].d.channel ? " (" + posts[p].d.channel + ")" : ""), sub: tr("Goes out soon · %1", [title]), when: posts[p].d.when, occ: o })
    }
    var links = Funding.linksOf(anchor, now)
    for (var l = 0; l < links.length; l++)
        if (Funding.deadlineState(links[l].d, now) === "soon") {
            var left = Funding.daysLeft(links[l].d, now)
            out.push({ tone: "warn", text: left <= 1 ? tr("%1 closes today", [links[l].d.name]) : tr("%1 closes in %2 days", [links[l].d.name, left]), sub: tr("Funding call"), when: now + left * DAY, link: links[l].d.url })
        }
    var rank = { red: 0, warn: 1, info: 2 }
    out.sort(function (a, b) { return rank[a.tone] - rank[b.tone] || (a.when || 0) - (b.when || 0) })
    return out
}

// Numbers for the top of Home.
function stats(occs, now) {
    var next30 = upcoming(occs, now, 30)
    var holds = next30.filter(function (o) { return Nights.fieldOf(o, "status") === "Hold" }).length
    return { next30: next30.length, holds: holds, confirmed: next30.length - holds }
}
