.pragma library
// Production: a working plan for a night, built from its format. The structure (format → modules →
// a plan counted back from show day, plus custom modules) follows Louisa Prog's INTERSECT production
// office; the formats, modules and templates here are written for independent promoters.
//
// Data, all on the night as Scala ext items (shared with every co-organiser, ADR 0009):
//   "prod-plan"  newest wins: { format, modules: [ids], custom: [{ id, name, cols }] }
//   "prod-row"   one per version of a row: { row, table, order, cells: {…}, del? }
// Anyone may edit any row: an edit posts a new version, and the newest version of each row wins
// (deleting is a version with del: true). Pure functions, no Qt.
.import "ext.js" as Ext
.import "legal-content.js" as LC

var DAY = 86400000

// ── column types: text, long, num, money, date, time, select, check, tminus (days before show) ──
function col(k, l, type, opts) { var c = { k: k, l: l, type: type || "text" }; if (opts) c.opts = opts; return c }
var DONE = ["Done", "Confirmed", "Booked", "Paid", "Signed", "Approved", "Sent", "Received", "Closed", "Mitigated", "Yes"]

var TABLES = {
    goals:      { t: "Goals", lead: "Two or three things this event should achieve, each with something you can count.",
                  cols: [col("goal", "Goal", "long"), col("measure", "How we'll know", "text"), col("target", "Target", "text"), col("actual", "Actual", "text")] },
    milestones: { t: "Timeline", lead: "Counted back from show day: move the date and every deadline moves with it.",
                  cols: [col("t", "Days before", "tminus"), col("task", "Milestone", "long"), col("owner", "Owner", "text"), col("done", "Done", "check")] },
    team:       { t: "Team & roles", lead: "One person per job, with a way to reach them during the event.",
                  cols: [col("role", "Role", "text"), col("name", "Who", "text"), col("contact", "Contact", "text"), col("onNight", "On the day", "check")] },
    venue:      { t: "Venue & ops", lead: "Check what the venue already has before you plan around it.",
                  cols: [col("item", "Check", "long"), col("owner", "Owner", "text"), col("status", "Status", "select", ["To check", "Asked", "Confirmed", "Problem"]), col("notes", "Notes", "text")] },
    permits:    { t: "Licences & compliance", lead: "What needs a permit, insurance or a signature, and by when.",
                  cols: [col("item", "Item", "text"), col("who", "Authority / who", "text"), col("due", "Due", "date"), col("status", "Status", "select", ["Not started", "Applied", "Approved", "Not needed"])] },
    hospitality:{ t: "Hospitality & riders", lead: "Artist riders, guest list spots, drinks, food, transport and beds.",
                  cols: [col("for", "For", "text"), col("item", "What", "text"), col("qty", "Qty", "num"), col("cost", "Cost", "money"), col("status", "Status", "select", ["Needed", "Booked", "Done"])] },
    vendors:    { t: "Suppliers", lead: "Sound, lights, security, bar, printing… Get two quotes for anything big.",
                  cols: [col("vendor", "Supplier", "text"), col("service", "Service", "text"), col("quote", "Quote", "money"), col("contact", "Contact", "text"), col("status", "Status", "select", ["Asked", "Quoted", "Booked", "Paid"])] },
    ros:        { t: "Run of show", lead: "The event minute by minute. Share it with the crew the day before.",
                  cols: [col("time", "Time", "time"), col("what", "What happens", "long"), col("who", "Who", "text"), col("where", "Where", "text")] },
    risks:      { t: "Risks", lead: "What could go wrong, how likely, how bad, and the plan B. 6 or more needs an owner.",
                  cols: [col("risk", "Risk", "long"), col("l", "Likelihood (1–3)", "select", ["1", "2", "3"]), col("i", "Impact (1–3)", "select", ["1", "2", "3"]), col("plan", "Plan B", "long"), col("owner", "Owner", "text"), col("status", "Status", "select", ["Open", "Mitigated", "Closed"])] },
    sessions:   { t: "Sessions", lead: "The whole series in one list: dates, hosts and who came.",
                  cols: [col("date", "Date", "date"), col("theme", "Theme / host", "text"), col("rsvp", "RSVPs", "num"), col("came", "Came", "num"), col("status", "Status", "select", ["Planned", "Confirmed", "Done"])] },
    stops:      { t: "Tour stops", lead: "One row per city or venue, each with its own contact and deal.",
                  cols: [col("date", "Date", "date"), col("city", "City", "text"), col("venue", "Venue", "text"), col("deal", "Deal", "text"), col("contact", "Contact", "text"), col("status", "Status", "select", ["Pitched", "Hold", "Confirmed", "Done"])] },
    donors:     { t: "Donors & pledges", lead: "Every ask, from first contact to the thank-you.",
                  cols: [col("name", "Donor", "text"), col("amount", "Amount", "money"), col("status", "Status", "select", ["Prospect", "Asked", "Pledged", "Received", "Thanked"]), col("notes", "Notes", "text")] },
    debrief:    { t: "Debrief", lead: "Within a week of the event: what worked, what didn't, what we change next time.",
                  cols: [col("topic", "Topic", "text"), col("worked", "What worked", "long"), col("change", "Change next time", "long"), col("owner", "Owner", "text")] }
}

// A module is a group of tables, or one of the night's existing sections (kind "section").
var MODULES = {
    brief:       { t: "Brief", tables: ["goals"] },
    timeline:    { t: "Timeline", tables: ["milestones"] },
    team:        { t: "Team", tables: ["team"] },
    lineup:      { t: "Line-up", section: "lineup" },
    crew:        { t: "Crew & shifts", section: "crew" },
    budget:      { t: "Budget", section: "budget" },
    tickets:     { t: "Tickets", section: "tickets" },
    venue:       { t: "Venue & ops", tables: ["venue", "permits"] },
    hospitality: { t: "Hospitality", tables: ["hospitality"] },
    suppliers:   { t: "Suppliers", tables: ["vendors"] },
    comms:       { t: "Comms", section: "posts" },
    gear:        { t: "Gear", section: "gear" },
    ros:         { t: "Run of show", tables: ["ros"] },
    risks:       { t: "Risks", tables: ["risks"] },
    sessions:    { t: "Sessions", tables: ["sessions"] },
    tour:        { t: "Tour", tables: ["stops"] },
    donors:      { t: "Donors", tables: ["donors"] },
    files:       { t: "Files", section: "files" },
    debrief:     { t: "Debrief", tables: ["debrief"] }
}
var MOD_ORDER = ["brief", "timeline", "team", "lineup", "crew", "budget", "tickets", "venue", "hospitality", "suppliers",
                 "comms", "gear", "ros", "risks", "sessions", "tour", "donors", "files", "debrief"]

// ── formats ──
var M = function (t, task) { return { t: t, task: task } }
var CORE_MILESTONES = [M(42, "Confirm date and venue (hold → confirmed)"), M(35, "Book headliner / main act"), M(28, "Announce the event"),
                       M(21, "Full line-up confirmed"), M(14, "Line-up reveal and tickets live"), M(7, "Tech rider to venue, crew confirmed"),
                       M(3, "Run of show shared with crew"), M(1, "Guest list closed, cash float ready"), M(-2, "Pay artists and suppliers"), M(-7, "Debrief and thank-yous")]
var FORMATS = {
    club:      { label: "Club night", blurb: "DJs, a room, a bar and a long night",
                 modules: ["brief", "timeline", "team", "lineup", "crew", "budget", "tickets", "venue", "hospitality", "comms", "gear", "ros", "risks", "debrief"],
                 milestones: CORE_MILESTONES,
                 rows: { venue: ["Capacity and licence hours", "Sound system and booth monitors", "Security and door policy", "Bar deal and float", "Access and step-free entry"],
                         ros: [["21:30", "Crew call, line check"], ["23:00", "Doors"], ["23:00", "Opening set"], ["06:00", "Lights up, close"]],
                         risks: [["Noise complaint / police visit", "2", "3", "Keep to licence levels, a named neighbour contact"], ["Artist cancels", "1", "3", "Back-up DJ on call"], ["Overcrowding at the door", "2", "2", "Clicker count, one-in-one-out"]] } },
    concert:   { label: "Concert / live", blurb: "Bands or live sets with a stage and soundcheck",
                 modules: ["brief", "timeline", "team", "lineup", "crew", "budget", "tickets", "venue", "hospitality", "suppliers", "comms", "gear", "ros", "risks", "debrief"],
                 milestones: CORE_MILESTONES.concat([M(10, "Stage plot and input lists from every act"), M(0, "Soundcheck order sent")]),
                 rows: { venue: ["Stage size and power", "Backline available", "Load-in times and parking", "Green room"],
                         ros: [["15:00", "Load-in"], ["17:00", "Soundcheck"], ["20:00", "Doors"], ["21:00", "Support"], ["22:00", "Headliner"], ["23:30", "Curfew"]],
                         risks: [["Soundcheck overruns", "2", "2", "Fixed slots, short line checks for support"], ["Equipment failure", "1", "3", "Spare DI, cables and mics"]] } },
    festival:  { label: "Festival / all-dayer", blurb: "Several stages or a long day, more crew, more permits",
                 modules: ["brief", "timeline", "team", "lineup", "crew", "budget", "tickets", "venue", "hospitality", "suppliers", "comms", "gear", "ros", "risks", "files", "debrief"],
                 milestones: [M(120, "Site and date secured"), M(90, "Permits applied for"), M(75, "Headliners booked"), M(60, "Announce, early-bird tickets"),
                              M(45, "Suppliers booked (sound, bar, security, toilets)"), M(30, "Full line-up and timetable"), M(21, "Crew and volunteers rota"),
                              M(14, "Site plan and safety plan signed off"), M(7, "Final production meeting"), M(1, "Build day"), M(-1, "Strike and clean-up"), M(-14, "Debrief, report to funders")],
                 rows: { venue: ["Site plan and capacity", "Power and generators", "Toilets and water", "First aid", "Waste and recycling", "Accessibility route and viewing area"],
                         ros: [["08:00", "Build"], ["12:00", "Gates"], ["23:00", "Last act"], ["00:00", "Site clear"]],
                         risks: [["Bad weather", "2", "3", "Covered areas, wet-weather plan, cancellation threshold"], ["Crowd crush at a stage", "1", "3", "Barriers, stewards, capacity per area"], ["Permit refused", "1", "3", "Apply early, plan B site"]] } },
    residency: { label: "Residency / series", blurb: "The same event every week or month",
                 modules: ["brief", "timeline", "team", "lineup", "budget", "sessions", "comms", "ros", "debrief"],
                 milestones: [M(21, "Book this edition's guests"), M(14, "Announce"), M(7, "Poster and posts out"), M(1, "Confirm crew"), M(-3, "Pay out, note attendance")],
                 rows: { ros: [["22:00", "Doors"], ["23:00", "Resident"], ["01:00", "Guest"], ["04:00", "Close"]] } },
    community: { label: "Community / salon", blurb: "Talks, listening sessions, gatherings with rotating hosts",
                 modules: ["brief", "timeline", "team", "sessions", "budget", "comms", "venue", "debrief"],
                 milestones: [M(21, "Host and theme agreed"), M(14, "Invite out"), M(3, "Reminder, RSVP count"), M(-3, "Thank-you and notes shared")],
                 rows: { venue: ["Seats and accessibility", "Projector / sound", "Tea, water, snacks"] } },
    workshop:  { label: "Workshop / talk", blurb: "A session with a facilitator, sign-ups and materials",
                 modules: ["brief", "timeline", "team", "lineup", "budget", "tickets", "venue", "hospitality", "comms", "gear", "ros", "debrief"],
                 milestones: [M(28, "Facilitator confirmed, fee agreed"), M(21, "Sign-ups open"), M(7, "Materials and equipment list"), M(2, "Reminder to participants"), M(-3, "Feedback form sent")],
                 rows: { venue: ["Tables, chairs, power strips", "Projector and screen", "Materials"], ros: [["18:30", "Set up"], ["19:00", "Welcome"], ["19:15", "Session"], ["21:00", "Wrap"]] } },
    fundraiser:{ label: "Fundraiser / benefit", blurb: "An event that raises money for a cause",
                 modules: ["brief", "timeline", "team", "lineup", "budget", "tickets", "donors", "venue", "comms", "ros", "risks", "debrief"],
                 milestones: CORE_MILESTONES.concat([M(30, "Cause, target and where the money goes, agreed"), M(-14, "Report what was raised")]),
                 rows: { risks: [["Takings handled badly", "1", "3", "Two people count, receipts, a shared sheet"]] } },
    tour:      { label: "Tour", blurb: "An artist or collective on the road, several stops",
                 modules: ["brief", "timeline", "team", "lineup", "tour", "budget", "hospitality", "comms", "gear", "risks", "debrief"],
                 milestones: [M(90, "Routing and target cities"), M(60, "Offers out to venues"), M(45, "Stops confirmed, deals signed"), M(30, "Travel and beds booked"), M(14, "Announce all dates"), M(-7, "Settle every stop")],
                 rows: { risks: [["Travel delay", "2", "2", "Buffer day, flexible tickets"], ["Low pre-sales at a stop", "2", "2", "Local co-promoter, push posts in that city"]] } }
}
var FORMAT_ORDER = ["club", "concert", "festival", "residency", "community", "workshop", "fundraiser", "tour"]

function rnd() { return Math.random().toString(36).slice(2, 10) }

// The plan and the rows a new plan starts with. Rows: [{ table, order, cells }].
function seedPlan(format, tr) {
    tr = tr || function (s) { return s }
    var f = FORMATS[format]
    if (!f) return null
    var rows = []
    function add(table, cells) { rows.push({ table: table, order: rows.length * 10, cells: cells }) }
    var ms = f.milestones.slice().sort(function (a, b) { return b.t - a.t })
    for (var i = 0; i < ms.length; i++) add("milestones", { t: ms[i].t, task: tr(ms[i].task), owner: "", done: false })
    var r = f.rows || {}
    for (var v = 0; v < (r.venue || []).length; v++) add("venue", { item: tr(r.venue[v]), owner: "", status: "To check", notes: "" })
    // the papers most events need (Resources → Legal toolkit → Papers for an event)
    if (f.modules.indexOf("venue") >= 0) for (var lr = 0; lr < LC.LICENCE_ROWS.length; lr++) add("permits", { item: tr(LC.LICENCE_ROWS[lr].en), who: "", due: "", status: "Not started" })
    for (var o = 0; o < (r.ros || []).length; o++) add("ros", { time: r.ros[o][0], what: tr(r.ros[o][1]), who: "", where: "" })
    for (var k = 0; k < (r.risks || []).length; k++) add("risks", { risk: tr(r.risks[k][0]), l: r.risks[k][1], i: r.risks[k][2], plan: tr(r.risks[k][3]), owner: "", status: "Open" })
    add("debrief", { topic: tr("Attendance"), worked: "", change: "", owner: "" })
    add("debrief", { topic: tr("Money"), worked: "", change: "", owner: "" })
    add("debrief", { topic: tr("Crew & team"), worked: "", change: "", owner: "" })
    return { plan: { format: format, modules: f.modules.slice(), custom: [] }, rows: rows }
}

// ── reading ──
function planOf(night) {
    var d = Ext.latestData(night, "prod-plan")
    if (!d || !FORMATS[d.format]) return null
    var mods = Array.isArray(d.modules) ? d.modules.filter(function (m) { return !!MODULES[m] || isCustomId(m) }) : []
    var custom = Array.isArray(d.custom) ? d.custom.filter(function (c) { return c && isCustomId(c.id) && Ext.str(c.name) && Array.isArray(c.cols) && c.cols.length }) : []
    return { format: d.format, modules: mods, custom: custom }
}
function isCustomId(id) { return typeof id === "string" && id.indexOf("cm-") === 0 }

// The newest version of every row, by row id; deleted rows dropped. Each: { row, table, order, cells, id, author }.
function allRows(night) {
    var xs = Ext.extOf(night, "prod-row"), best = {}
    for (var i = 0; i < xs.length; i++) {
        var d = Ext.dataOf(xs[i]), key = Ext.str(d.row)
        if (!key) continue
        var w = Ext.wallOf(xs[i]), b = best[key]
        if (!b || w > b.w || (w === b.w && xs[i].id > b.x.id)) best[key] = { w: w, x: xs[i], d: d }
    }
    var out = []
    for (var k in best) {
        var bd = best[k].d
        if (bd.del === true) continue
        out.push({ row: k, table: Ext.str(bd.table), order: typeof bd.order === "number" ? bd.order : 0,
                   cells: (bd.cells && typeof bd.cells === "object") ? bd.cells : {}, id: best[k].x.id, author: Ext.str(best[k].x.author) })
    }
    return out
}
function rowsOf(night, table) {
    var out = allRows(night).filter(function (r) { return r.table === table })
    if (table === "milestones") out.sort(function (a, b) { return (Number(b.cells.t) || 0) - (Number(a.cells.t) || 0) || a.order - b.order })
    else if (table === "ros") out.sort(function (a, b) { return timeKey(a.cells.time) - timeKey(b.cells.time) || a.order - b.order })
    else out.sort(function (a, b) { return a.order - b.order || (a.row < b.row ? -1 : 1) })
    return out
}
// Club nights run past midnight: early-morning times sort after the evening.
function timeKey(t) {
    var m = /^(\d{1,2})[:.h]?(\d{2})$/.exec(String(t || "").trim())
    if (!m) return 1e6
    var h = Number(m[1]); return (h < 8 ? h + 24 : h) * 60 + Number(m[2])
}

// Table definition, built-in or custom ("cm-…" module's own table has the module's id).
function tableDef(plan, table) {
    if (TABLES[table]) return TABLES[table]
    var c = (plan && plan.custom || []).filter(function (x) { return x.id === table })[0]
    return c ? { t: c.name, lead: "", cols: c.cols, custom: true } : null
}
function moduleDef(plan, id) {
    if (MODULES[id]) return MODULES[id]
    var c = (plan && plan.custom || []).filter(function (x) { return x.id === id })[0]
    return c ? { t: c.name, tables: [c.id], custom: true } : null
}
function modulesOf(plan) { return plan ? plan.modules.filter(function (m) { return !!moduleDef(plan, m) }) : [] }
function missingModules(plan) { return MOD_ORDER.filter(function (m) { return !plan || plan.modules.indexOf(m) < 0 }) }

// ── values ──
function isDone(v) { return v === true || DONE.indexOf(String(v)) >= 0 }
function dueOf(night, tDays) { return (night && typeof night.startTime === "number") ? night.startTime - Number(tDays) * DAY : null }
function tLabel(t) { t = Number(t) || 0; return t > 0 ? "T-" + t : t < 0 ? "T+" + (-t) : "Show day" }
function riskScore(c) { return (Number(c.l) || 0) * (Number(c.i) || 0) }
// A row counts toward progress through its "done" checkbox or its status.
function rowDone(cells) {
    if (cells.done !== undefined) return cells.done === true
    if (cells.status !== undefined) return isDone(cells.status)
    return null
}
// Progress across the plan's tables: { done, total }.
function progress(night, plan) {
    var done = 0, total = 0, rows = allRows(night)
    var mods = modulesOf(plan), tables = {}
    for (var i = 0; i < mods.length; i++) { var md = moduleDef(plan, mods[i]); (md.tables || []).forEach(function (t) { tables[t] = true }) }
    for (var j = 0; j < rows.length; j++) {
        if (!tables[rows[j].table]) continue
        var d = rowDone(rows[j].cells)
        if (d === null) continue
        total++; if (d) done++
    }
    return { done: done, total: total }
}
// Milestones not done, with due dates: overdue (before now), soon (within `days`).
function dueMilestones(night, now, days) {
    var out = []
    var ms = rowsOf(night, "milestones")
    for (var i = 0; i < ms.length; i++) {
        var c = ms[i].cells
        if (c.done === true) continue
        var due = dueOf(night, c.t)
        if (due === null) continue
        if (due < now || due - now <= days * DAY) out.push({ row: ms[i].row, task: Ext.str(c.task), due: due, overdue: due < now })
    }
    out.sort(function (a, b) { return a.due - b.due })
    return out
}

// ── writing ──
// Clean a row's cells against its columns (unknown keys dropped, numbers parsed, options checked).
function cleanCells(def, cells) {
    var out = {}, cols = (def && def.cols) || []
    for (var i = 0; i < cols.length; i++) {
        var c = cols[i], v = cells ? cells[c.k] : undefined
        if (c.type === "check") { out[c.k] = v === true; continue }
        if (c.type === "num" || c.type === "money" || c.type === "tminus") {
            var s = String(v === undefined || v === null ? "" : v).replace(",", ".").trim()
            if (s === "") { if (c.type === "tminus") return { error: "Days before the show: a number, like 14 (or -2 for after)." }; continue }
            var n = Number(s)
            if (!isFinite(n)) return { error: c.l + " should be a number." }
            out[c.k] = c.type === "tminus" ? Math.round(n) : n
            continue
        }
        var str = Ext.str(v === undefined || v === null ? "" : String(v)).trim().slice(0, c.type === "long" ? 1000 : 200)
        if (c.type === "select" && str && c.opts && c.opts.indexOf(str) < 0) return { error: c.l + ": pick one of the options." }
        if (c.type === "date" && str && !/^\d{4}-\d{2}-\d{2}$/.test(str)) return { error: c.l + ": a date like 2026-12-17." }
        if (c.type === "time" && str && !/^\d{1,2}[:.h]?\d{2}$/.test(str)) return { error: c.l + ": a time like 23:00." }
        out[c.k] = str
    }
    return { cells: out }
}
function rowData(table, row, order, cells) { return { row: row, table: table, order: order, cells: cells } }
function deletedRow(r) { return { row: r.row, table: r.table, order: r.order, cells: {}, del: true } }
function newRowId(table) { return table + "-" + rnd() }

// A custom module: a name and columns ("Name:type, Other:type"; type text by default).
var COL_TYPES = ["text", "long", "num", "money", "date", "time", "check"]
function customModule(name, spec) {
    name = Ext.str(name).replace(/\s+/g, " ").trim().slice(0, 60)
    if (!name) return { error: "Name the module." }
    var parts = String(spec || "").split(/[,\n]+/), cols = [], seen = {}
    for (var i = 0; i < parts.length; i++) {
        var p = parts[i].trim(); if (!p) continue
        var m = /^(.*?)(?::\s*([a-z]+))?$/.exec(p), label = m[1].trim().slice(0, 40), type = (m[2] || "text").toLowerCase()
        if (!label) continue
        if (COL_TYPES.indexOf(type) < 0) return { error: "Column types: " + COL_TYPES.join(", ") + "." }
        var k = "c" + label.toLowerCase().replace(/[^a-z0-9]+/g, "").slice(0, 16)
        if (!k || seen[k]) k = k + cols.length
        seen[k] = true
        cols.push(col(k, label, type))
    }
    if (!cols.length) return { error: "Add at least one column, like: Item, Owner, Done:check" }
    if (cols.length > 8) return { error: "Eight columns at most." }
    return { module: { id: "cm-" + rnd(), name: name, cols: cols } }
}
