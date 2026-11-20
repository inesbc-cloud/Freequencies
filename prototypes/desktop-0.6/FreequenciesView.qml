// Freequencies — the coordination tool for Lisbon's independent culture, on top of the Scala calendar.
//
// 0.6: rebuilt in the Freequencies design language (terminal ground, acid green, Bebas Neue + FT88 Serif)
// and extended with the Track A features of the Freequencies plan: month / week / board / timeline /
// venues / analytics views, drag & drop, search and filters, colour coding, tags, tickets, posters,
// files in Logos Storage, notes, tasks with deadlines, gear checklist, budget, social planner,
// recurring nights, duplicate, venue-clash warnings. See docs/adr/0009-track-a-on-ext-items.md.
//
// A pure-QML view over the `scala` core module (ADR 0001 / 0002): it reads and writes Scala's
// calendars, so every night is an ordinary Scala event and shows up in Scala too. Freequencies'
// own data rides in Scala's mechanisms: the calendar's custom fields (Status, Venue, Type) and
// Scala's per-event comments (ext items, ns "scala", kind "comment").
//
// Rules carried over from the Scala view: every core call is async (callVia), results are
// double-JSON-encoded (j()), all text that other people wrote is Text.PlainText.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "templates.js" as Tpl

import Logos.Theme
import Logos.Controls

Item {
    id: root
    width: 1440
    height: 900

    // ── core bridge (same pattern as Scala's view) ───────────────────────────────
    property bool ready: false
    readonly property int callTimeoutMs: 20000
    function hasBridge() {
        return typeof logos !== "undefined" && logos !== null
            && (typeof logos.callModuleAsync === "function" || typeof logos.callModule === "function")
    }
    function _deliver(cb, raw) {
        if (!cb) return
        try { cb(raw === undefined || raw === null ? "" : raw) }
        catch (e) { console.warn("freequencies: callback error: " + e) }
    }
    function callVia(module, method, args, cb) {
        var a = args || []
        if (!root.hasBridge()) { Qt.callLater(function () { root._deliver(cb, "") }); return }
        if (typeof logos.callModuleAsync === "function") {
            try { logos.callModuleAsync(module, method, a, function (res) { root._deliver(cb, res) }, root.callTimeoutMs) }
            catch (e) { console.warn("freequencies: callModuleAsync threw: " + e); Qt.callLater(function () { root._deliver(cb, "") }) }
            return
        }
        Qt.callLater(function () {
            var raw = ""
            try { raw = logos.callModule(module, method, a) } catch (e) { raw = "" }
            root._deliver(cb, raw)
        })
    }
    function core(method, args, cb) { root.callVia("scala", method, args, cb) }
    function j(raw, fallback) {
        var v = raw
        for (var i = 0; i < 3 && typeof v === "string"; i++) {
            var t = v.trim()
            if (t === "") return fallback
            try { v = JSON.parse(t) } catch (e) { return (i === 0 ? fallback : v) }
        }
        return (v === undefined || v === null) ? fallback : v
    }

    // ── tokens: the Freequencies identity (site + posters) ──────────────────────
    readonly property color cBase:    "#050805"   // terminal ground
    readonly property color cMantle:  "#0a110a"
    readonly property color cCrust:   "#050805"   // ink on lime / acid
    readonly property color cSurface: "#111c11"
    readonly property color cSurface2:"#1a2c1d"
    readonly property color cLine:    "#223a26"   // ruled grid
    readonly property color cText:    "#d6efd6"
    readonly property color cSub:     "#a3c4a3"   // a shade lighter than the site's body grey, for legibility
    readonly property color cFaint:   "#6f8f6f"
    readonly property color cLime:    "#6ef600"   // primary
    readonly property color cAcid:    "#7bf686"   // poster green
    readonly property color cSignal:  "#4aa8ff"   // the (( )) signal blue
    readonly property color cBracket: "#2f6bff"
    readonly property color cHold:    "#4aa8ff"
    readonly property color cWarn:    "#ffc531"
    readonly property color cRed:     "#ff5a4a"
    // older names, kept so shared code reads the same as the Scala view
    readonly property color cBlue:    cAcid
    readonly property color cYellow:  cWarn
    readonly property color cGreen:   cLime
    readonly property color cMauve:   cLime
    readonly property color cPink:    "#ff6ad5"

    // ── the Freequencies schema: custom fields a calendar gets when it's used for Freequencies ──
    readonly property var statuses: ["Hold", "Confirmed", "Cancelled"]
    readonly property var types: ["Club night", "Concert", "Residency", "Other"]
    readonly property var freqFields: [
        { key: "status", label: "Status", type: "enum", options: root.statuses },
        { key: "venue", label: "Venue", type: "text" },
        { key: "type", label: "Type", type: "enum", options: root.types }
    ]
    // Colour comes from the status field (ADR 0001 §4), not from the calendar.
    function statusColor(s) {
        return s === "Confirmed" ? root.cLime : s === "Cancelled" ? root.cRed : s === "Hold" ? root.cHold : root.cFaint
    }
    function fieldOf(ev, k) { return (ev && ev.fields && typeof ev.fields[k] === "string") ? ev.fields[k] : "" }

    // ── data ─────────────────────────────────────────────────────────────────────
    property var calendars: []
    property var events: []
    property bool loading: true
    property string loadError: ""
    property bool refreshing: false
    property string coreVer: ""
    function refresh() {
        if (root.refreshing) return            // single-flight
        root.refreshing = true
        root.core("listCalendars", [], function (rc) {
            var cs = root.j(rc, null)
            root.core("listAllEvents", [], function (re) {
                var es = root.j(re, null)
                root.refreshing = false
                root.loading = false
                if (!Array.isArray(cs) || !Array.isArray(es)) {
                    root.loadError = root.hasBridge() ? "Couldn't read your calendars from Scala. Is the ‘scala’ package installed?" : "No Basecamp bridge."
                    return
                }
                root.loadError = ""
                root.calendars = cs
                root.events = es
                if (root.selected) {
                    var still = root.eventById(root.selected.id)
                    if (!still) root.selected = null
                }
            })
        })
    }
    Timer { interval: 10000; running: root.ready; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: Qt.callLater(function () {
        root.ready = root.hasBridge()
        root.core("coreVersion", [], function (r) { root.coreVer = String(root.j(r, "") || "") })
        root.refresh()
    })

    function calById(id) { for (var i = 0; i < calendars.length; i++) if (calendars[i].id === id) return calendars[i]; return null }
    function eventById(id) { for (var i = 0; i < events.length; i++) if (events[i].id === id) return events[i]; return null }
    // A calendar is a Freequencies calendar when its `status` field is the Freequencies one: a choice
    // field offering Hold, Confirmed and Cancelled. A `status` field of another shape belongs to
    // someone else's convention and is left alone.
    function statusFieldOf(c) {
        var sc = (c && c.schema) || []
        for (var i = 0; i < sc.length; i++) if (sc[i] && sc[i].key === "status") return sc[i]
        return null
    }
    function isFreqStatusField(f) {
        if (!f || f.type !== "enum" || !Array.isArray(f.options)) return false
        for (var i = 0; i < root.statuses.length; i++) if (f.options.indexOf(root.statuses[i]) < 0) return false
        return true
    }
    function isFreqCal(c) { return isFreqStatusField(statusFieldOf(c)) }
    // Why "Use for Freequencies" can't adopt this calendar ("" = it can).
    function adoptBlocker(c) {
        if (!isEditorOf(c)) return "Only its owner or editors can add Freequencies fields"
        var sf = statusFieldOf(c)
        if (sf && !isFreqStatusField(sf)) return "Has its own “status” field, so Freequencies leaves it alone"
        var sc = (c && c.schema) || []
        for (var i = 0; i < sc.length; i++) {
            var f = sc[i]
            if (f && f.key === "venue" && f.type && f.type !== "text") return "Has its own “venue” field of another kind"
            if (f && f.key === "type" && f.type && f.type !== "enum") return "Has its own “type” field of another kind"
        }
        return ""
    }
    readonly property var freqCals: { var o = []; for (var i = 0; i < calendars.length; i++) if (isFreqCal(calendars[i])) o.push(calendars[i]); return o }
    readonly property var otherCals: { var o = []; for (var i = 0; i < calendars.length; i++) if (!isFreqCal(calendars[i])) o.push(calendars[i]); return o }
    property var hiddenCals: ({})
    function toggleCal(id) { var h = {}; for (var k in hiddenCals) h[k] = hiddenCals[k]; if (h[id]) delete h[id]; else h[id] = true; hiddenCals = h }
    // Only owners/editors may change a calendar's fields.
    function isEditorOf(c) {
        if (!c) return false
        var me = c.authorAddr || ""
        if (!me) return false
        if (c.owner === me) return true
        var r = c.roles || {}
        return r[me] === "editor" || r[me] === "admin"
    }

    // "Use for Freequencies": add the Status / Venue / Type fields to a calendar's schema (keeps its own fields).
    function adoptCalendar(c) {
        var why = adoptBlocker(c)
        if (why) { root.notify(why + ".", true); return }
        var sc = (c.schema || []).slice()
        for (var i = 0; i < root.freqFields.length; i++) {
            var f = root.freqFields[i], have = false
            for (var k = 0; k < sc.length; k++) if (sc[k] && sc[k].key === f.key) have = true
            if (!have) sc.push(f)
        }
        root.core("updateCalendarMeta", [c.id, JSON.stringify({ schema: sc })], function (r) {
            if (root.j(r, false) === true || String(r) === "true") { root.notify("“" + (c.name || "Calendar") + "” now uses Freequencies fields"); root.refresh() }
            else root.notify("Couldn't update “" + (c.name || "the calendar") + "”. Only its owner or editors can change its fields.", true)
        })
    }

    // ── recurrence expansion (identical to Scala's) ──────────────────────────────
    function expandEvent(ev, winStart, winEnd) {
        var dur = Math.max(0, (ev.endTime || ev.startTime) - ev.startTime)
        var r = ev.recur
        function mk(s) { var o = {}; for (var k in ev) o[k] = ev[k]; o.startTime = s; o.endTime = s + dur; o.seriesId = ev.id; o.occ = s; return o }
        if (!r || !r.freq) return (ev.startTime + dur >= winStart && ev.startTime <= winEnd) ? [mk(ev.startTime)] : []
        var interval = Math.max(1, Math.floor(r.interval || 1))
        var hardUntil = (typeof r.until === "number") ? r.until : Infinity
        var out = [], cur = new Date(ev.startTime)
        for (var i = 0; i < 500; i++) {
            var s = cur.getTime()
            if (s > hardUntil || s > winEnd) break
            if (s + dur >= winStart) out.push(mk(s))
            if (r.freq === "daily") cur.setDate(cur.getDate() + interval)
            else if (r.freq === "weekly") cur.setDate(cur.getDate() + 7 * interval)
            else if (r.freq === "monthly") cur.setMonth(cur.getMonth() + interval)
            else if (r.freq === "yearly") cur.setFullYear(cur.getFullYear() + interval)
            else break
        }
        return out
    }
    function expandEvents(evs, winStart, winEnd) {
        var out = []
        for (var i = 0; i < evs.length; i++) { var xs = expandEvent(evs[i], winStart, winEnd); for (var k = 0; k < xs.length; k++) out.push(xs[k]) }
        out.sort(function (a, b) { return a.startTime - b.startTime })
        return out
    }

    // ── lanes (prototypes/lanes/lanes.ts) ────────────────────────────────────────
    property date firstDay: { var d = new Date(); d.setHours(0, 0, 0, 0); return d }
    readonly property int nDays: 14
    property string laneBy: "venue"          // "venue" | "status" | "calendar"
    function laneOf(o) {
        if (laneBy === "calendar") return o.calendarId
        var v = fieldOf(o, laneBy)
        return v === "" ? "—" : v
    }
    function buildLanes(occs, cals) {
        var lanes = [], index = {}
        function addLane(id, label) { if (index[id] === undefined) { index[id] = lanes.length; lanes.push({ id: id, label: label }) } }
        if (laneBy === "calendar") { for (var i = 0; i < cals.length; i++) addLane(cals[i].id, cals[i].name || "(unnamed)") }
        else if (laneBy === "status") { for (var s = 0; s < statuses.length; s++) addLane(statuses[s], statuses[s]) }
        var d0 = new Date(firstDay).getTime()
        function dayStart(n) { var d = new Date(d0); d.setDate(d.getDate() + n); return d.getTime() }
        var end = dayStart(nDays), inWin = []
        for (var a = 0; a < occs.length; a++) if (occs[a].startTime >= d0 && occs[a].startTime < end) inWin.push(occs[a])
        var noValue = false
        for (var b = 0; b < inWin.length; b++) { var id = laneOf(inWin[b]); if (id === "—") { noValue = true; continue } addLane(id, id) }
        if (noValue) addLane("—", laneBy === "venue" ? "No venue" : "—")
        var days = []
        for (var c = 0; c < nDays; c++) { var cells = []; for (var e = 0; e < lanes.length; e++) cells.push([]); days.push({ date: dayStart(c), cells: cells }) }
        for (var g = 0; g < inWin.length; g++) {
            var dd = new Date(inWin[g].startTime); dd.setHours(0, 0, 0, 0)
            var row = -1
            for (var r = 0; r < days.length; r++) if (days[r].date === dd.getTime()) { row = r; break }
            var col = index[laneOf(inWin[g])]
            if (row >= 0 && col !== undefined) days[row].cells[col].push(inWin[g])
        }
        return { lanes: lanes, days: days }
    }
    readonly property var shownCals: { var o = []; for (var i = 0; i < freqCals.length; i++) if (!hiddenCals[freqCals[i].id]) o.push(freqCals[i]); return o }
    readonly property var grid: {
        var ids = {}
        for (var i = 0; i < shownCals.length; i++) ids[shownCals[i].id] = true
        var src = []
        for (var k = 0; k < events.length; k++) if (ids[events[k].calendarId]) src.push(events[k])
        var d0 = new Date(firstDay).getTime()
        return buildLanes(expandEvents(src, d0, d0 + (nDays + 1) * 864e5), shownCals)
    }
    function shiftDays(n) { var d = new Date(firstDay); d.setDate(d.getDate() + n); firstDay = d }
    function rangeLabel() {
        var a = new Date(firstDay), b = new Date(firstDay); b.setDate(b.getDate() + nDays - 1)
        return Qt.formatDate(a, "d MMM") + " – " + Qt.formatDate(b, "d MMM yyyy")
    }

    // ── the selected night (right panel) ─────────────────────────────────────────
    property var selected: null              // an occurrence
    readonly property var selMaster: selected ? (eventById(selected.seriesId || selected.id) || selected) : null
    readonly property var selCal: selMaster ? calById(selMaster.calendarId) : null
    function canEdit(ev) {
        var c = ev ? calById(ev.calendarId) : null
        if (!c) return false
        var me = c.authorAddr || ""
        if (isEditorOf(c)) return true
        var r = (c.roles || {})[me]
        if (r === "viewer") return false
        return c.collab === true || (!!ev.creatorId && ev.creatorId === me)
    }
    // Change one Freequencies field on the night (status / venue / type) — a normal Scala edit.
    property bool saving: false
    // Scala replaces a whole event on every edit (last write wins per event), so the edit is built on
    // the freshest copy, fetched right before saving: a title or time someone changed since the board
    // last refreshed is kept, not overwritten with the board's older copy.
    function setField(key, value) {
        var m = selMaster
        if (!m || saving) return
        saving = true
        root.core("getEvent", [m.id], function (raw) {
            var fresh = root.j(raw, null)
            if (!fresh || typeof fresh !== "object" || fresh.id !== m.id) {
                saving = false
                root.notify("Couldn't load the night to change it. It may have been deleted.", true)
                root.refresh()
                return
            }
            var up = JSON.parse(JSON.stringify(fresh))
            delete up.seriesId; delete up.occ; delete up.ext; delete up.rsvps
            if (!up.calendarId) up.calendarId = m.calendarId
            up.fields = (up.fields && typeof up.fields === "object") ? up.fields : {}
            up.fields[key] = value
            root.core("updateEvent", [JSON.stringify(up)], function (r) {
                saving = false
                if (String(root.j(r, "")) === m.id) { root.notify("Saved"); root.refresh() }
                else root.notify("Couldn't save the change. You may not have edit rights on this calendar.", true)
            })
        })
    }
    function commentsOf(ev) {
        var out = [], xs = (ev && ev.ext) || []
        for (var i = 0; i < xs.length; i++) if (xs[i].ns === "scala" && xs[i].kind === "comment") out.push(xs[i])
        return out
    }
    property bool commentBusy: false
    function postComment(text) {
        text = String(text || "").trim()
        if (!text || commentBusy || !selMaster) return
        commentBusy = true
        var item = { ns: "scala", kind: "comment", target: selMaster.id, data: { text: text } }
        root.core("postExt", [selMaster.calendarId, JSON.stringify(item)], function (r) {
            commentBusy = false
            var res = root.j(r, {})
            if (res && res.ok) { commentInput.text = ""; root.refresh() }
            else root.notify("Couldn't post the comment" + (res && res.error ? ": " + res.error : ". Update the ‘scala’ package to 0.12.0+."), true)
        })
    }
    function deleteComment(id) {
        root.core("deleteExt", [selMaster.calendarId, id], function (r) {
            var res = root.j(r, {})
            if (res && res.ok) root.refresh(); else root.notify("Couldn't delete the comment.", true)
        })
    }
    // ── line-up (ADR 0004; mirrors mobile/src/app/lineup.ts) ─────────────────────
    readonly property var bookingStatuses: ["asked", "confirmed", "cancelled"]
    function str(v) { return typeof v === "string" ? v : "" }
    function lineupOf(ev) {
        var xs = (ev && Array.isArray(ev.ext)) ? ev.ext : [], out = []
        for (var i = 0; i < xs.length; i++) {
            var x = xs[i]
            if (!x || x.ns !== "xyz.freequencies" || x.kind !== "artist" || !str(x.id)) continue
            var d = (x.data && typeof x.data === "object") ? x.data : {}
            var name = str(d.name).trim()
            if (!name) continue
            var fee = (typeof d.fee === "number" && isFinite(d.fee) && d.fee >= 0) ? d.fee : null
            var st = str(d.status)
            out.push({ id: str(x.id), author: str(x.author), name: name, contact: str(d.contact), book: str(d.book), fee: fee,
                       currency: str(d.currency), set: str(d.set), status: bookingStatuses.indexOf(st) >= 0 ? st : "asked" })
        }
        out.sort(function (a, b) { return (a.set || "\uffff").localeCompare(b.set || "\uffff") || a.name.localeCompare(b.name) })
        return out
    }
    function artistKey(b) { return b.contact ? "c:" + b.contact : "n:" + b.name.trim().toLowerCase() }
    function feeLabel(b) { return b.fee === null ? "" : (b.currency ? b.fee + " " + b.currency : String(b.fee)) }
    function feesTotal(bs) {
        var m = {}, keys = []
        for (var i = 0; i < bs.length; i++) {
            var b = bs[i]
            if (b.fee === null || b.status === "cancelled") continue
            if (m[b.currency] === undefined) { m[b.currency] = 0; keys.push(b.currency) }
            m[b.currency] += b.fee
        }
        var parts = []
        for (var k = 0; k < keys.length; k++) parts.push(keys[k] ? m[keys[k]] + " " + keys[k] : String(m[keys[k]]))
        return parts.join(" + ")
    }
    function bookingColor(st) { return st === "confirmed" ? cLime : st === "cancelled" ? cRed : cHold }
    function cap(st) { return st.charAt(0).toUpperCase() + st.slice(1) }
    function occKey(o) { return (o.seriesId || o.id) + "@" + o.occ }
    function dayKey(t) { var d = new Date(t); return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate() }
    // occKey → [{artist, other}] for nights on the board whose artist also plays a night that overlaps
    // it or starts the same day.
    readonly property var doubles: {
        var ids = {}
        for (var i = 0; i < freqCals.length; i++) ids[freqCals[i].id] = true
        var src = []
        for (var k = 0; k < events.length; k++) if (ids[events[k].calendarId]) src.push(events[k])
        var occs = expandEvents(src, root.winStart - 864e5, root.winEnd + 864e5)
        var byArtist = {}, order = []
        for (var a = 0; a < occs.length; a++) {
            // Artists and named crew (ADR 0007): one person can't be in two places either way.
            var seen = {}, lu = lineupOf(occs[a]).concat(crewOf(occs[a]).filter(function (c) { return !!c.name }))
            for (var b = 0; b < lu.length; b++) {
                if (lu[b].status === "cancelled") continue
                var key = artistKey(lu[b])
                if (seen[key]) continue
                seen[key] = true
                if (!byArtist[key]) { byArtist[key] = []; order.push(key) }
                byArtist[key].push({ night: occs[a], name: lu[b].name })
            }
        }
        var out = {}
        for (var o = 0; o < order.length; o++) {
            var list = byArtist[order[o]]
            for (var x = 0; x < list.length; x++) for (var y = x + 1; y < list.length; y++) {
                var p = list[x].night, q = list[y].night
                if (occKey(p) === occKey(q)) continue
                var overlap = p.startTime < q.endTime && q.startTime < p.endTime
                if (!overlap && dayKey(p.startTime) !== dayKey(q.startTime)) continue
                ;(out[occKey(p)] = out[occKey(p)] || []).push({ artist: list[x].name, other: q })
                ;(out[occKey(q)] = out[occKey(q)] || []).push({ artist: list[y].name, other: p })
            }
        }
        return out
    }
    function doubleLine(d) { return "⚠ " + d.artist + " is also booked at " + (d.other.title || "another night") + ", " + Qt.formatDateTime(new Date(d.other.startTime), "d MMM hh:mm") }

    // Kith (the `kith` core module): every book's contacts, read when the artist picker opens.
    property var kithArtists: []             // [{bookId, id, name}]
    property string kithState: ""            // "" | "loading" | "ok" | "none" | "missing"
    function loadKith() {
        if (kithState === "loading") return
        kithState = "loading"
        callVia("kith", "listBooks", [], function (rb) {
            var books = j(rb, null)
            if (!Array.isArray(books)) { kithState = "missing"; return }
            if (books.length === 0) { kithArtists = []; kithState = "none"; return }
            var acc = [], left = books.length
            for (var i = 0; i < books.length; i++) (function (book) {
                var bid = str(book && book.id)
                callVia("kith", "listContacts", [bid], function (rc) {
                    var cs = j(rc, [])
                    if (Array.isArray(cs)) for (var k = 0; k < cs.length; k++) {
                        var c = cs[k], nm = (c && c.name && typeof c.name === "object") ? str(c.name.display).trim() : ""
                        if (nm && str(c.id)) acc.push({ bookId: bid, id: str(c.id), name: nm })
                    }
                    if (--left === 0) { acc.sort(function (a, b) { return a.name.localeCompare(b.name) }); kithArtists = acc; kithState = "ok" }
                })
            })(books[i])
        })
    }
    function kithName(b) {
        if (b.contact) for (var i = 0; i < kithArtists.length; i++) if (kithArtists[i].id === b.contact) return kithArtists[i].name
        return b.name
    }

    // artist popup state
    property string aId: ""
    property string aContact: ""
    property string aBook: ""
    property string aStatus: "asked"
    property bool aMine: true
    property bool aCanRemove: false
    property string aQuery: ""
    readonly property var aMatches: {
        var q = aQuery.trim().toLowerCase(), out = []
        for (var i = 0; i < kithArtists.length && out.length < 12; i++) if (!q || kithArtists[i].name.toLowerCase().indexOf(q) >= 0) out.push(kithArtists[i])
        return out
    }
    function openArtist(b) {
        if (!selMaster) return
        var lu = lineupOf(selMaster)
        aId = b ? b.id : ""; aContact = b ? b.contact : ""; aBook = b ? b.book : ""; aStatus = b ? b.status : "asked"
        aMine = !b || (!!selCal && b.author === selCal.authorAddr)
        aCanRemove = !!b && (aMine || isEditorOf(selCal))
        aQuery = ""; aSearch.text = ""
        aName.text = b ? b.name : ""; aSet.text = b ? b.set : ""
        aFee.text = b && b.fee !== null ? String(b.fee) : ""
        var cur = "EUR"
        for (var i = 0; i < lu.length; i++) if (lu[i].currency) { cur = lu[i].currency; break }
        aCur.text = b && b.currency ? b.currency : cur
        artistPopup.open()
        if (!b) loadKith()
    }
    property bool artistBusy: false
    function saveArtist() {
        if (!selMaster || artistBusy) return
        var name = aName.text.trim()
        if (!name) { notify("Pick an artist or type a name.", true); return }
        var feeT = aFee.text.trim().replace(",", "."), fee = feeT === "" ? null : Number(feeT)
        if (fee !== null && !(isFinite(fee) && fee >= 0)) { notify("The fee should be a number, for example 250 or 99.50.", true); return }
        var data = { name: name, status: aStatus }
        if (aContact) { data.contact = aContact; data.book = aBook }
        if (fee !== null) { data.fee = fee; data.currency = aCur.text.trim().toUpperCase() }
        if (aSet.text.trim()) data.set = aSet.text.trim()
        var item = { ns: "xyz.freequencies", kind: "artist", target: selMaster.id, data: data }
        var editId = aId
        if (editId) item.id = editId
        artistBusy = true
        core("postExt", [selMaster.calendarId, JSON.stringify(item)], function (r) {
            artistBusy = false
            var res = j(r, {})
            // Close only the popup this save came from (it may have been reopened for another booking meanwhile).
            if (res && res.ok) { if (aId === editId) artistPopup.close(); notify(editId ? "Booking updated" : "Added " + name); refresh() }
            else notify("Couldn't save the booking" + (res && res.error ? ": " + res.error : ". Update the ‘scala’ package to 0.12.0+."), true)
        })
    }
    function removeArtist() {
        if (!selMaster || !aId || artistBusy) return
        var delId = aId
        artistBusy = true
        core("deleteExt", [selMaster.calendarId, delId], function (r) {
            artistBusy = false
            var res = j(r, {})
            if (res && res.ok) { if (aId === delId) artistPopup.close(); notify("Removed from the line-up"); refresh() }
            else notify("Couldn't remove the booking.", true)
        })
    }

    // ── public copy (ADR 0008); mirrors mobile/src/app/publish.ts ─────────────────
    function publicEventId(nightId) { return "pub-" + nightId }
    function publicPrefix(nightId) { return "public:" + nightId + ":" }
    function publicItemId(nightId) { return publicPrefix(nightId) + Math.random().toString(36).slice(2, 10) }
    function publicLinkOf(ev) {
        var nightId = str(ev && ev.id), xs = (ev && Array.isArray(ev.ext)) ? ev.ext : [], best = null
        for (var i = 0; i < xs.length; i++) {
            var x = xs[i]
            if (!x || x.ns !== "xyz.freequencies" || x.kind !== "public" || !nightId || str(x.id).indexOf(publicPrefix(nightId)) !== 0) continue
            var d = (x.data && typeof x.data === "object" && !Array.isArray(x.data)) ? x.data : {}
            var cal = str(d.calendar)
            if (!cal) continue
            var h = (x.hlc && typeof x.hlc === "object") ? x.hlc : {}
            var wall = typeof h.wall === "number" ? h.wall : 0, ctr = typeof h.ctr === "number" ? h.ctr : 0
            if (!best || wall < best.wall || (wall === best.wall && (ctr < best.ctr || (ctr === best.ctr && str(x.id) < best.id))))
                best = { id: str(x.id), author: str(x.author), calendar: cal, wall: wall, ctr: ctr }
        }
        return best ? { id: best.id, author: best.author, calendar: best.calendar } : null
    }
    // Club nights run past midnight: a set starting before noon comes after the evening's sets.
    function setKey(set) {
        var m = /(\d{1,2})[:.](\d{2})/.exec(set || "")
        if (!m) return 1e6
        var h = Number(m[1]), mi = Number(m[2])
        return (h < 12 ? h + 24 : h) * 60 + mi
    }
    // Only what attendees may see: never the night's description, fees, crew, holds, comments.
    function publicCopyOf(n, published) {
        var f = (n.fields && typeof n.fields === "object") ? n.fields : {}
        var cancelled = !published || str(f.status) === "Cancelled", lines = []
        if (cancelled) lines.push("This night is off.")
        else {
            var acts = lineupOf(n).filter(function (b) { return b.status === "confirmed" })
            acts.sort(function (a, b) { return setKey(a.set) - setKey(b.set) })
            if (acts.length) { lines.push("Line-up:"); for (var i = 0; i < acts.length; i++) lines.push(acts[i].set ? acts[i].set + "  " + acts[i].name : acts[i].name) }
            var xs = Array.isArray(n.ext) ? n.ext : []
            for (var k = 0; k < xs.length; k++) {
                var x = xs[k], d = (x && x.data && typeof x.data === "object") ? x.data : {}
                if (x && x.ns === "xyz.freequencies" && x.kind === "form" && str(d.purpose) === "guestlist" && str(d.uri)) {
                    if (lines.length) lines.push(""); lines.push("Guest list: " + str(d.uri)); break
                }
            }
        }
        return { title: (cancelled ? "Cancelled: " : "") + (str(n.title).trim() || "Untitled night"),
                 startTime: n.startTime, endTime: n.endTime, allDay: n.allDay === true,
                 location: str(f.venue).trim(), description: lines.join("\n"), recur: (n.recur === undefined ? null : n.recur) }
    }
    function canon(v) {
        return JSON.stringify(v, function (k, x) {
            if (!x || typeof x !== "object" || Array.isArray(x)) return x
            var o = {}, ks = Object.keys(x).sort(); for (var i = 0; i < ks.length; i++) o[ks[i]] = x[ks[i]]; return o
        })
    }
    function sameCopy(cur, want) {
        if (!cur) return false
        return str(cur.title) === want.title && cur.startTime === want.startTime && cur.endTime === want.endTime
            && (cur.allDay === true) === want.allDay && str(cur.location) === want.location
            && str(cur.description) === want.description && canon(cur.recur === undefined ? null : cur.recur) === canon(want.recur)
    }
    function copyToEvent(c) {
        var e = { title: c.title, startTime: c.startTime, endTime: c.endTime }
        if (c.allDay) e.allDay = true
        if (c.location) e.location = c.location
        if (c.description) e.description = c.description
        if (c.recur !== null && c.recur !== undefined) e.recur = c.recur
        return e
    }
    function isPublicTarget(calId) { var c = calById(calId); return !!c && !isFreqCal(c) }
    function mirrorPlan() {
        var freq = {}; for (var i = 0; i < calendars.length; i++) if (isFreqCal(calendars[i])) freq[calendars[i].id] = true
        var out = []
        for (var k = 0; k < events.length; k++) {
            var n = events[k]
            if (!freq[n.calendarId]) continue
            var pid = publicEventId(n.id), link = publicLinkOf(n), copies = [], targets = {}
            for (var e = 0; e < events.length; e++) if (events[e].id === pid && isPublicTarget(events[e].calendarId)) { copies.push(events[e]); targets[events[e].calendarId] = true }
            if (link && isPublicTarget(link.calendar)) targets[link.calendar] = true
            for (var cal in targets) {
                var want = publicCopyOf(n, !!link && link.calendar === cal), cur = null
                for (var c = 0; c < copies.length; c++) if (copies[c].calendarId === cal) cur = copies[c]
                if (!sameCopy(cur, want)) out.push({ calendarId: cal, id: pid, copy: want, nightId: n.id })
            }
        }
        return out
    }
    // After every refresh, bring each published night's public copy up to date. Only owners/editors of
    // the public calendar write; for others the night says so.
    property var mirrorBlocked: ({})
    property var lastWritten: ({})
    property bool mirroring: false
    property bool putMissing: false          // scala core older than 0.12.4: no putEvent, so no copying
    onEventsChanged: Qt.callLater(root.runMirror)
    function runMirror() {
        if (mirroring || putMissing) return
        var plan = mirrorPlan(), blocked = {}, todo = []
        for (var i = 0; i < plan.length; i++) {
            var w = plan[i]
            if (!isEditorOf(calById(w.calendarId))) { blocked[w.nightId] = true; continue }
            var sig = JSON.stringify(copyToEvent(w.copy))
            if (lastWritten[w.id + "@" + w.calendarId] !== sig) todo.push({ w: w, sig: sig })
        }
        mirrorBlocked = blocked
        if (!todo.length) return
        mirroring = true
        var left = todo.length
        for (var t = 0; t < todo.length; t++) (function (job) {
            core("putEvent", [job.w.calendarId, job.w.id, JSON.stringify(copyToEvent(job.w.copy))], function (r) {
                if (r === "" || r === undefined || r === null) putMissing = true
                if (r === job.w.id || str(j(r, "")) === job.w.id) { var m = {}; for (var k in lastWritten) m[k] = lastWritten[k]; m[job.w.id + "@" + job.w.calendarId] = job.sig; lastWritten = m }
                if (--left === 0) { mirroring = false; refresh() }
            })
        })(todo[t])
    }
    readonly property var publicTargets: { var o = []; for (var i = 0; i < calendars.length; i++) if (!isFreqCal(calendars[i]) && isEditorOf(calendars[i]) && calendars[i].open === false) o.push(calendars[i]); return o }
    property bool pubBusy: false
    function makePublic(calId) {
        if (!selMaster || pubBusy) return
        pubBusy = true
        var item = { ns: "xyz.freequencies", kind: "public", target: selMaster.id, id: publicItemId(selMaster.id), data: { calendar: calId } }
        core("postExt", [selMaster.calendarId, JSON.stringify(item)], function (r) {
            pubBusy = false
            var res = j(r, {})
            if (res && res.ok) { pubPopup.close(); notify("Public: attendees will see it"); refresh() }
            else notify("Couldn't make it public" + (res && res.error ? ": " + res.error : "."), true)
        })
    }
    function newPublicCalendar() {
        if (!selMaster || pubBusy || !selCal) return
        pubBusy = true
        core("createCalendar", [(selCal.name || "Our nights") + " (public)", selCal.color || "#89b4fa", ""], function (r) {
            var id = str(j(r, ""))
            if (!id) { pubBusy = false; notify("Couldn't create the calendar.", true); return }
            core("updateCalendarMeta", [id, JSON.stringify({ open: false, description: "What's on. Published from Freequencies." })], function () {
                pubBusy = false; makePublic(id)
            })
        })
    }
    function stopPublic() {
        var link = publicLinkOf(selMaster)
        if (!selMaster || !link || pubBusy) return
        pubBusy = true
        core("deleteExt", [selMaster.calendarId, link.id], function (r) {
            pubBusy = false
            var res = j(r, {})
            if (res && res.ok) { notify("No longer public: its copy now says Cancelled"); refresh() } else notify("Couldn't change it.", true)
        })
    }
    function copyInvite(calId, role) {
        core("createInvite", [calId, role], function (r) {
            var res = j(r, {})
            if (res && res.ok && str(res.link)) copyText(res.link); else notify("Couldn't make a link" + (res && res.error ? ": " + res.error : "."), true)
        })
    }

    // ── crew (ADR 0007): crew slots (kind "crew") and check-ins (kind "checkin"); mirrors mobile/src/app/crew.ts ──
    readonly property var crewRoles: ["Door", "Bar", "Sound", "Lights", "Security", "Cloakroom", "Runner"]
    // A fresh id per check-in: Scala keeps a deleted ext id deleted, so "undo, then check in again"
    // needs a new one. The slot is in the id so a check-in can't be filed under someone else's slot.
    function checkinPrefix(slotId) { return "checkin:" + slotId + ":" }
    function checkinId(slotId) { return checkinPrefix(slotId) + Math.random().toString(36).slice(2, 10) }
    function crewOf(ev) {
        var xs = (ev && Array.isArray(ev.ext)) ? ev.ext : [], ins = {}, out = []
        for (var i = 0; i < xs.length; i++) {
            var x = xs[i]
            if (!x || x.ns !== "xyz.freequencies" || x.kind !== "checkin" || !str(x.id)) continue
            var d = (x.data && typeof x.data === "object" && !Array.isArray(x.data)) ? x.data : {}
            var slot = str(d.crew)
            if (!slot || str(x.id).indexOf(checkinPrefix(slot)) !== 0) continue
            var at = (typeof d.at === "number" && isFinite(d.at)) ? d.at : 0, prev = ins[slot]
            // Two people checking the same person in at once: the earliest counts.
            if (!prev || at < prev.at || (at === prev.at && str(x.id) < prev.id)) ins[slot] = { id: str(x.id), author: str(x.author), at: at }
        }
        for (var k = 0; k < xs.length; k++) {
            var y = xs[k]
            if (!y || y.ns !== "xyz.freequencies" || y.kind !== "crew" || !str(y.id)) continue
            var e = (y.data && typeof y.data === "object" && !Array.isArray(y.data)) ? y.data : {}
            var name = str(e.name).trim(), role = str(e.role).trim()
            if (!name && !role) continue
            var st = str(e.status), id = str(y.id)
            out.push({ id: id, author: str(y.author), name: name, contact: name ? str(e.contact) : "", book: name ? str(e.book) : "",
                       role: role, call: str(e.call).trim(), status: bookingStatuses.indexOf(st) >= 0 ? st : "asked",
                       checkedIn: name ? (ins[id] || null) : null })
        }
        out.sort(function (a, b) {
            return (a.role || "\uffff").localeCompare(b.role || "\uffff") || (a.call || "\uffff").localeCompare(b.call || "\uffff")
                || (a.name ? 0 : 1) - (b.name ? 0 : 1) || a.name.localeCompare(b.name)
        })
        return out
    }
    function crewSummary(slots) {
        var r = { people: 0, open: 0, confirmed: 0, here: 0 }
        for (var i = 0; i < slots.length; i++) {
            var c = slots[i]
            if (c.status === "cancelled") continue
            if (!c.name) { r.open++; continue }
            r.people++
            if (c.status === "confirmed") r.confirmed++
            if (c.checkedIn) r.here++
        }
        return r
    }
    function crewSummaryLabel(sm) {
        var parts = []
        if (sm.people) parts.push(sm.people + " on")
        if (sm.open) parts.push(sm.open + " open")
        if (sm.here) parts.push(sm.here + " here")
        return parts.join(" · ")
    }
    function crewShort(ev) {
        var sm = crewSummary(crewOf(ev))
        if (!sm.people && !sm.open) return ""
        return "Crew " + sm.people + (sm.open ? " · " + sm.open + " open" : "")
    }

    // crew popup state
    property string cId: ""
    property string cContact: ""
    property string cBook: ""
    property string cStatus: "asked"
    property bool cMine: true
    property bool cCanRemove: false
    property string cQuery: ""
    readonly property var cMatches: {
        var q = cQuery.trim().toLowerCase(), out = []
        for (var i = 0; i < kithArtists.length && out.length < 12; i++) if (!q || kithArtists[i].name.toLowerCase().indexOf(q) >= 0) out.push(kithArtists[i])
        return out
    }
    function openCrew(c) {
        if (!selMaster) return
        cId = c ? c.id : ""; cContact = c ? c.contact : ""; cBook = c ? c.book : ""; cStatus = c ? c.status : "asked"
        cMine = !c || (!!selCal && c.author === selCal.authorAddr)
        cCanRemove = !!c && (cMine || isEditorOf(selCal))
        cQuery = ""; cSearch.text = ""
        cName.text = c ? c.name : ""; cRole.text = c ? c.role : ""; cCall.text = c ? c.call : ""
        crewPopup.open()
        loadKith()
    }
    property bool crewBusy: false
    function saveCrew() {
        if (!selMaster || crewBusy) return
        var name = cName.text.trim(), role = cRole.text.trim()
        if (!name && !role) { notify("Give a role or a name. A role without a name is an open slot.", true); return }
        var data = { name: name, role: role, status: cStatus }
        if (name && cContact) { data.contact = cContact; data.book = cBook }
        if (cCall.text.trim()) data.call = cCall.text.trim()
        var item = { ns: "xyz.freequencies", kind: "crew", target: selMaster.id, data: data }
        var editId = cId
        if (editId) item.id = editId
        crewBusy = true
        core("postExt", [selMaster.calendarId, JSON.stringify(item)], function (r) {
            crewBusy = false
            var res = j(r, {})
            if (res && res.ok) { if (cId === editId) crewPopup.close(); notify(editId ? "Crew updated" : name ? "Added " + name + " to the crew" : "Open slot added"); refresh() }
            else notify("Couldn't save" + (res && res.error ? ": " + res.error : "."), true)
        })
    }
    function removeCrew() {
        if (!selMaster || !cId || crewBusy) return
        var delId = cId
        crewBusy = true
        core("deleteExt", [selMaster.calendarId, delId], function (r) {
            crewBusy = false
            var res = j(r, {})
            if (res && res.ok) { if (cId === delId) crewPopup.close(); notify("Removed from the crew"); refresh() }
            else notify("Couldn't remove it.", true)
        })
    }
    // Anyone on the door can check someone in; undoing is for whoever did it, or an editor.
    function canUndoCheckin(c) { return !!c.checkedIn && ((!!selCal && c.checkedIn.author === selCal.authorAddr) || isEditorOf(selCal)) }
    function toggleCheckin(c) {
        if (!selMaster || crewBusy || !c.name) return
        crewBusy = true
        var done = function (r, what) {
            crewBusy = false
            var res = j(r, {})
            if (res && res.ok) { notify(what); refresh() } else notify("Couldn't check in" + (res && res.error ? ": " + res.error : "."), true)
        }
        if (c.checkedIn) core("deleteExt", [selMaster.calendarId, c.checkedIn.id], function (r) { done(r, "Check-in undone") })
        else core("postExt", [selMaster.calendarId, JSON.stringify({ ns: "xyz.freequencies", kind: "checkin", target: selMaster.id, id: checkinId(c.id),
                                                                     data: { crew: c.id, at: Date.now() } })], function (r) { done(r, c.name + " is here") })
    }

    // ── forms (ADR 0005): WhisperBox forms attached to a night as ext items (kind "form") ──────
    function wb(method, args, cb) { callVia("whisperbox_core", method, args, cb) }
    readonly property var formPurposes: [
        { id: "booking", label: "Artist booking" }, { id: "crew", label: "Crew sign-up" },
        { id: "guestlist", label: "Guest list" }, { id: "feedback", label: "Feedback" }]
    function purposeLabel(p) { for (var i = 0; i < formPurposes.length; i++) if (formPurposes[i].id === p) return formPurposes[i].label; return "Form" }
    function formsOf(ev) {
        var xs = (ev && Array.isArray(ev.ext)) ? ev.ext : [], out = []
        for (var i = 0; i < xs.length; i++) {
            var x = xs[i]
            if (!x || x.ns !== "xyz.freequencies" || x.kind !== "form" || !str(x.id)) continue
            var d = (x.data && typeof x.data === "object") ? x.data : {}
            var fid = str(d.formId)
            if (!fid) continue
            out.push({ id: str(x.id), author: str(x.author), formId: fid, uri: str(d.uri), purpose: str(d.purpose), title: str(d.title) })
        }
        return out
    }
    // WhisperBox's state: forms by id (title, status, mine, questions) and, for my forms, the answers.
    property var wbForms: ({})
    property var wbSummaries: ({})          // formId -> formSummary (counts only for forms I can read)
    function loadSummaries(ev) {
        var fs = formsOf(ev)
        for (var i = 0; i < fs.length; i++) (function (fid) {
            wb("formSummary", [fid], function (r) {
                var sm = j(r, null)
                if (!sm || typeof sm !== "object" || sm.ok !== true) return
                var m = {}; for (var k in wbSummaries) m[k] = wbSummaries[k]
                m[fid] = sm; wbSummaries = m
            })
        })(fs[i].formId)
    }
    property var wbResponses: ({})
    property string wbState: ""             // "" | "loading" | "ok" | "missing"
    function loadWb() {
        if (wbState === "loading") return
        wbState = "loading"
        wb("snapshot", [], function (r) {
            var snap = j(r, null)
            if (!snap || typeof snap !== "object" || !snap.state || typeof snap.state !== "object") { wbState = "missing"; return }
            wbForms = (snap.state.forms && typeof snap.state.forms === "object") ? snap.state.forms : {}
            wbResponses = (snap.creatorView && snap.creatorView.responses && typeof snap.creatorView.responses === "object") ? snap.creatorView.responses : {}
            wbState = "ok"
            loadSummaries(selMaster)
        })
    }
    onSelMasterChanged: if (selMaster && formsOf(selMaster).length > 0) loadWb()
    Timer { interval: 15000; repeat: true; running: root.ready && !!root.selMaster && root.formsOf(root.selMaster).length > 0; onTriggered: root.loadWb() }
    function formLine(f) {
        var sm = wbSummaries[f.formId]
        if (!sm) return purposeLabel(f.purpose) + (wbState === "missing" ? " · WhisperBox isn't answering" : " · syncing…")
        var parts = [purposeLabel(f.purpose), str(sm.status) === "closed" ? "Closed" : "Open"]
        if (sm.canRead === true) {
            var n = typeof sm.responses === "number" ? sm.responses : 0
            parts.push(n + (n === 1 ? " response" : " responses"))
            if (typeof sm.newResponses === "number" && sm.newResponses > 0) parts.push(sm.newResponses + " new")
        } else parts.push("answers go to its creator")
        return parts.join(" · ")
    }
    function formTitle(f) { var sm = wbSummaries[f.formId], w = wbForms[f.formId]; return (sm && str(sm.title)) || (w && str(w.title)) || f.title || purposeLabel(f.purpose) }

    // WhisperBox's shared templates (templates.js is generated from whisperbox-sdk), titled for the night,
    // so the desktop and Android offer the same forms (ADR 0005).
    function formTemplate(purpose, ev) {
        var when = Qt.formatDate(new Date(ev.startTime), "d MMM"), name = ev.title || "our night"
        return Tpl.template(purpose, { title: purposeLabel(purpose) + ": " + name + " (" + when + ")" })
    }
    property bool formBusy: false
    function addForm(purpose) {
        if (!selMaster || formBusy) return
        var ev = selMaster, def = formTemplate(purpose, selected || ev)
        formBusy = true
        wb("createForm", [JSON.stringify(def)], function (r) {
            var res = j(r, {})
            if (!res || !res.ok || !str(res.formId)) { formBusy = false; notify("Couldn't create the form" + (res && res.error ? ": " + res.error : ". Is the ‘whisperbox_core’ package installed?"), true); return }
            var fid = str(res.formId)
            wb("shareUri", [fid], function (r2) {
                var su = j(r2, {}), uri = (su && su.ok) ? str(su.uri) : ""
                var item = { ns: "xyz.freequencies", kind: "form", target: ev.id, id: fid, data: { formId: fid, uri: uri, purpose: purpose, title: def.title } }
                core("postExt", [ev.calendarId, JSON.stringify(item)], function (r3) {
                    formBusy = false
                    var px = j(r3, {})
                    if (px && px.ok) { formPopup.close(); notify("Form created. Copy its link to share it."); refresh(); loadWb() }
                    else notify("The form was created in WhisperBox but couldn't be attached to the night" + (px && px.error ? ": " + px.error : "."), true)
                })
            })
        })
    }
    function detachForm(f) {
        if (!selMaster) return
        core("deleteExt", [selMaster.calendarId, f.id], function (r) {
            var res = j(r, {})
            if (res && res.ok) { notify("Form removed from this night. It stays in WhisperBox."); refresh() } else notify("Couldn't remove the form.", true)
        })
    }
    function copyText(t) { clipHelper.text = t; clipHelper.selectAll(); clipHelper.copy(); notify("Link copied") }
    TextEdit { id: clipHelper; visible: false }

    // responses viewer
    property var respRows: []
    property string respTitle: ""
    function openResponses(f) {
        respTitle = formTitle(f); respRows = []
        respPopup.open()
        wb("getDecryptedResponses", [f.formId], function (r) {
            var res = j(r, {})
            if (!res || !res.ok || !Array.isArray(res.responses)) { respRows = [{ head: "Couldn't read the answers", lines: [res && res.error ? str(res.error) : "Only the form's creator can read them."] }]; return }
            var w = wbForms[f.formId] || {}, qs = Array.isArray(w.questions) ? w.questions : [], rows = []
            for (var i = 0; i < res.responses.length; i++) {
                var rr = res.responses[i] || {}, ans = Array.isArray(rr.answers) ? rr.answers : [], lines = []
                for (var k = 0; k < ans.length; k++) {
                    var a = ans[k] || {}, qq = null
                    for (var m = 0; m < qs.length; m++) if (qs[m] && qs[m].id === a.questionId) { qq = qs[m]; break }
                    lines.push((qq ? str(qq.text) : str(a.questionId)) + ": " + answerText(qq, a.value))
                }
                rows.push({ head: typeof rr.submittedAt === "number" ? Qt.formatDateTime(new Date(rr.submittedAt), "d MMM hh:mm") : "Answer " + (i + 1), lines: lines })
            }
            if (rows.length === 0) rows.push({ head: "No answers yet", lines: [] })
            respRows = rows
        })
    }
    function answerText(q, v) {
        if (v === null || v === undefined || v === "") return "—"
        var opts = (q && Array.isArray(q.options)) ? q.options : []
        function one(x) { if (typeof x === "number" && opts[x] !== undefined) return String(opts[x]); if (x && typeof x === "object" && typeof x.other === "string") return x.other; return String(x) }
        if (Array.isArray(v)) return v.map(one).join(", ")
        if (typeof v === "boolean") return v ? "Yes" : "No"
        return one(v)
    }

    function rsvpSummary(ev) {
        var n = { going: 0, maybe: 0, no: 0 }, r = (ev && ev.rsvps) || {}
        for (var k in r) if (n[r[k]] !== undefined) n[r[k]]++
        return n.going + " going · " + n.maybe + " maybe · " + n.no + " no"
    }

    // ── toast ────────────────────────────────────────────────────────────────────
    property string toastMsg: ""
    property bool toastErr: false
    function notify(msg, isErr) { toastMsg = msg; toastErr = !!isErr; toastTimer.restart() }
    Timer { id: toastTimer; interval: 4000; onTriggered: root.toastMsg = "" }

    // ═════════════════════════════════════════════════════════════════════════════
    // Freequencies 0.6 — Track A (Freequencies plan, Lisbon 2026): the design language, more views,
    // search and filters, drag & drop, and the per-night tools (poster, tags, tickets, notes, files,
    // tasks, gear, budget, social posts, duplicate, repeat, venue clashes).
    // All new data rides in Scala the same way as before: ext items with ns "xyz.freequencies"
    // (ADR 0009), files in Scala's own `attachments` (Logos Storage, ADR 0017 in the Scala repo).
    // ═════════════════════════════════════════════════════════════════════════════

    // ── design language: fonts ──────────────────────────────────────────────────
    // Bebas Neue (OFL) is bundled. FT88 Serif (Velvetyne, OFL) goes in qml/fonts/FT88-Serif.otf;
    // until it is there the view falls back to the system monospace.
    FontLoader { id: bebas; source: "fonts/BebasNeue-Regular.ttf" }
    FontLoader { id: ft88; source: "fonts/FT88-Serif.otf" }
    readonly property string fDisplay: bebas.status === FontLoader.Ready ? bebas.font.family : "Impact"
    readonly property string fBody: ft88.status === FontLoader.Ready ? ft88.font.family : "monospace"

    // ── small helpers ───────────────────────────────────────────────────────────
    function master(o) { return o ? (eventById(o.seriesId || o.id) || o) : null }
    function rnd() { return Math.random().toString(36).slice(2, 10) }
    function dataOf(x) { return (x && x.data && typeof x.data === "object" && !Array.isArray(x.data)) ? x.data : {} }
    function num(v) { return (typeof v === "number" && isFinite(v)) ? v : null }
    function wallOf(x) { var h = (x && x.hlc && typeof x.hlc === "object") ? x.hlc : {}; return (typeof h.wall === "number" ? h.wall : 0) * 1000 + (typeof h.ctr === "number" ? h.ctr : 0) }
    function extOf(ev, kind) {
        var xs = (ev && Array.isArray(ev.ext)) ? ev.ext : [], out = []
        for (var i = 0; i < xs.length; i++) { var x = xs[i]; if (x && x.ns === "xyz.freequencies" && x.kind === kind && str(x.id)) out.push(x) }
        return out
    }
    // One value per night (tags, tickets, poster): the newest item wins, whoever wrote it. Writing
    // posts a fresh item and retires my older ones, so it works without editing someone else's item.
    function latestOf(ev, kind) {
        var xs = extOf(ev, kind), best = null
        for (var i = 0; i < xs.length; i++) if (!best || wallOf(xs[i]) > wallOf(best) || (wallOf(xs[i]) === wallOf(best) && xs[i].id > best.id)) best = xs[i]
        return best
    }
    function isMine(x, ev) { var c = ev ? calById(ev.calendarId) : null; return !!c && !!x && x.author === c.authorAddr }
    property bool extBusy: false
    function putLatest(ev, kind, data, okMsg) {
        if (!ev || extBusy) return
        var old = extOf(ev, kind).filter(function (x) { return isMine(x, ev) })
        var item = { ns: "xyz.freequencies", kind: kind, target: ev.id, id: kind + ":" + ev.id + ":" + rnd(), data: data }
        extBusy = true
        core("postExt", [ev.calendarId, JSON.stringify(item)], function (r) {
            extBusy = false
            var res = j(r, {})
            if (res && res.ok) {
                for (var i = 0; i < old.length; i++) core("deleteExt", [ev.calendarId, old[i].id], function () {})
                if (okMsg) notify(okMsg)
                refresh()
            } else notify("Couldn't save" + (res && res.error ? ": " + res.error : ". Update the ‘scala’ package to 0.12.0+."), true)
        })
    }
    // Lists (tasks, gear, budget lines, social posts): one item each, edited by id.
    function itemsOf(ev, kind) {
        var xs = extOf(ev, kind), out = []
        for (var i = 0; i < xs.length; i++) out.push({ id: str(xs[i].id), author: str(xs[i].author), d: dataOf(xs[i]) })
        return out
    }
    function saveItem(ev, kind, data, id, okMsg) {
        if (!ev || extBusy) return
        var item = { ns: "xyz.freequencies", kind: kind, target: ev.id, id: id || (kind + ":" + rnd()), data: data }
        extBusy = true
        core("postExt", [ev.calendarId, JSON.stringify(item)], function (r) {
            extBusy = false
            var res = j(r, {})
            if (res && res.ok) { if (okMsg) notify(okMsg); refresh() }
            else notify("Couldn't save" + (res && res.error ? ": " + res.error : ". Only the person who added it can change it."), true)
        })
    }
    function removeItem(ev, id, okMsg) {
        if (!ev || !id) return
        core("deleteExt", [ev.calendarId, id], function (r) {
            var res = j(r, {})
            if (res && res.ok) { notify(okMsg || "Removed"); refresh() } else notify("Couldn't remove it. Only the person who added it, or an editor, can.", true)
        })
    }
    function copyData(d) { var o = {}; for (var k in d) o[k] = d[k]; return o }
    function toggleDone(ev, kind, it) { var d = copyData(it.d); d.done = !(it.d.done === true); saveItem(ev, kind, d, it.id, "") }

    // Edit the night itself (notes, repeat, time) on the freshest copy — same rule as setField.
    function editNight(m, mutate, okMsg) {
        if (!m || saving) return
        saving = true
        core("getEvent", [m.id], function (raw) {
            var fresh = j(raw, null)
            if (!fresh || typeof fresh !== "object" || fresh.id !== m.id) { saving = false; notify("Couldn't load the night to change it. It may have been deleted.", true); refresh(); return }
            var up = JSON.parse(JSON.stringify(fresh))
            delete up.seriesId; delete up.occ; delete up.ext; delete up.rsvps
            if (!up.calendarId) up.calendarId = m.calendarId
            up.fields = (up.fields && typeof up.fields === "object") ? up.fields : {}
            mutate(up)
            core("updateEvent", [JSON.stringify(up)], function (r) {
                saving = false
                if (String(j(r, "")) === m.id) { if (okMsg) notify(okMsg); refresh() }
                else notify("Couldn't save the change. You may not have edit rights on this calendar.", true)
            })
        })
    }
    function saveNotes(text) { editNight(selMaster, function (up) { up.description = text }, "Notes saved") }
    readonly property var repeatOpts: [{ l: "Once", f: "", i: 1 }, { l: "Weekly", f: "weekly", i: 1 }, { l: "Every 2 weeks", f: "weekly", i: 2 }, { l: "Monthly", f: "monthly", i: 1 }]
    function repeatLabel(ev) {
        var r = ev && ev.recur
        if (!r || !r.freq) return "Once"
        for (var i = 0; i < repeatOpts.length; i++) if (repeatOpts[i].f === r.freq && repeatOpts[i].i === Math.max(1, r.interval || 1)) return repeatOpts[i].l
        return "Repeats " + r.freq
    }
    function setRepeat(opt) {
        editNight(selMaster, function (up) {
            if (!opt.f) delete up.recur
            else up.recur = { freq: opt.f, interval: opt.i }
        }, opt.f ? "Now repeats: " + opt.l.toLowerCase() : "No longer repeats")
    }

    // ── tags ────────────────────────────────────────────────────────────────────
    function tagsOf(ev) {
        var t = dataOf(latestOf(master(ev), "tags")).tags, out = []
        if (Array.isArray(t)) for (var i = 0; i < t.length; i++) if (typeof t[i] === "string" && t[i].trim() && out.indexOf(t[i].trim()) < 0) out.push(t[i].trim())
        return out
    }
    function addTag(t) {
        t = String(t || "").trim().toLowerCase()
        if (!t || !selMaster) return
        var cur = tagsOf(selMaster); if (cur.indexOf(t) >= 0) return
        cur.push(t); putLatest(selMaster, "tags", { tags: cur }, "Tagged “" + t + "”")
    }
    function removeTag(t) { var cur = tagsOf(selMaster).filter(function (x) { return x !== t }); putLatest(selMaster, "tags", { tags: cur }, "") }
    readonly property var suggestedTags: ["techno", "ambient", "live coding", "workshop", "talk", "fundraiser", "outdoor", "free entry"]
    readonly property var allTags: {
        var seen = {}, out = []
        for (var i = 0; i < events.length; i++) { var c = calById(events[i].calendarId); if (!c || !isFreqCal(c)) continue
            var ts = tagsOf(events[i]); for (var k = 0; k < ts.length; k++) if (!seen[ts[k]]) { seen[ts[k]] = true; out.push(ts[k]) } }
        out.sort(); return out
    }

    // ── tickets ─────────────────────────────────────────────────────────────────
    function ticketsOf(ev) { var x = latestOf(master(ev), "tickets"); return x ? dataOf(x) : null }
    function ticketRevenue(t) { return t && num(t.sold) !== null && num(t.price) !== null ? t.sold * t.price : 0 }
    function ticketLine(t) {
        if (!t) return ""
        var parts = []
        if (num(t.sold) !== null) parts.push(t.sold + (num(t.capacity) ? " / " + t.capacity : "") + " sold")
        if (num(t.price) !== null) parts.push(t.price === 0 ? "free entry" : t.price + " " + (str(t.currency) || "EUR"))
        return parts.join(" · ")
    }

    // ── poster (an image URL, or a file attached to the night) ───────────────────
    function posterOf(ev) { var x = latestOf(master(ev), "poster"); return x ? dataOf(x) : null }
    property var posterPaths: ({})          // cid -> local path, once fetched from Logos Storage
    function posterSrc(ev) {
        var p = posterOf(ev)
        if (!p) return ""
        var u = str(p.url)
        if (/^(https?|file):\/\//.test(u)) return u
        var cid = str(p.cid)
        if (!cid) return ""
        if (posterPaths[cid]) return "file://" + posterPaths[cid]
        var m = master(ev); if (m) fetchPoster(m.calendarId, cid, str(p.name) || "poster")
        return ""
    }
    property var posterAsked: ({})
    function fetchPoster(calId, cid, name) {
        if (posterAsked[cid]) return
        var a = {}; for (var k in posterAsked) a[k] = posterAsked[k]; a[cid] = true; posterAsked = a
        transfer("downloadAttachment", [calId, cid, name], function (r) {
            if (r.ok && str(r.path)) { var m = {}; for (var k2 in posterPaths) m[k2] = posterPaths[k2]; m[cid] = str(r.path); posterPaths = m }
        })
    }
    function setPosterUrl(u) { u = String(u || "").trim(); if (!selMaster) return; putLatest(selMaster, "poster", u ? { url: u } : {}, u ? "Poster set" : "Poster removed") }
    function setPosterFile(a) { if (!selMaster || !a) return; putLatest(selMaster, "poster", { cid: str(a.storageCid), name: str(a.name) }, "Poster set from “" + str(a.name) + "”") }

    // ── files: Scala's own attachments (Logos Storage, sealed with the calendar key) ─────
    // Every file is readable by the calendar's members only. "Community" marks the ones meant to be
    // shared further (rider templates, logos) so they can go public once Scala's public tier lands.
    function filesOf(ev) { var m = master(ev); return (m && Array.isArray(m.attachments)) ? m.attachments : [] }
    function fileVisibility(ev, cid) {
        var xs = extOf(master(ev), "file"), best = null
        for (var i = 0; i < xs.length; i++) if (str(dataOf(xs[i]).cid) === cid && (!best || wallOf(xs[i]) > wallOf(best))) best = xs[i]
        return best && str(dataOf(best).visibility) === "public" ? "public" : "private"
    }
    function setFileVisibility(cid, vis) {
        if (!selMaster) return
        var ev = selMaster, old = extOf(ev, "file").filter(function (x) { return str(dataOf(x).cid) === cid && isMine(x, ev) })
        var item = { ns: "xyz.freequencies", kind: "file", target: ev.id, id: "file:" + ev.id + ":" + cid + ":" + rnd(), data: { cid: cid, visibility: vis } }
        core("postExt", [ev.calendarId, JSON.stringify(item)], function (r) {
            var res = j(r, {})
            if (res && res.ok) { for (var i = 0; i < old.length; i++) core("deleteExt", [ev.calendarId, old[i].id], function () {}); refresh() }
            else notify("Couldn't change it.", true)
        })
    }
    function humanSize(n) { n = n || 0; if (n < 1024) return n + " B"; if (n < 1048576) return (n / 1024).toFixed(1) + " KB"; return (n / 1048576).toFixed(1) + " MB" }
    function isImage(a) { return /^image\//.test(str(a.mime)) || /\.(png|jpe?g|gif|webp)$/i.test(str(a.name)) }
    property string fileMsg: ""
    function onFilePicked(fileUrl) {
        var ev = selMaster
        if (!ev) return
        var path = decodeURIComponent(("" + fileUrl).replace(/^file:\/\//, "")), name = path.split("/").pop()
        fileMsg = "Sealing and uploading " + name + "…"
        transfer("uploadAttachment", [ev.calendarId, path, name, ""], function (r) {
            if (!r.ok) { fileMsg = "Upload failed: " + (r.error || "unknown"); return }
            var ref = { name: str(r.name) || name, mime: str(r.mime), size: r.size || 0, storageCid: str(r.cid), blobId: str(r.blobId) }
            editNight(ev, function (up) { up.attachments = (Array.isArray(up.attachments) ? up.attachments : []).concat([ref]) }, "Attached " + ref.name)
            fileMsg = ""
        })
    }
    function openFile(a) {
        var ev = selMaster
        if (!ev || !str(a.storageCid)) return
        fileMsg = "Fetching " + str(a.name) + "…"
        transfer("downloadAttachment", [ev.calendarId, str(a.storageCid), str(a.name)], function (r) {
            fileMsg = ""
            if (r.ok && str(r.path)) Qt.openUrlExternally("file://" + str(r.path)); else notify("Couldn't fetch it: " + (r.error || "unknown"), true)
        })
    }
    function removeFile(a) {
        editNight(selMaster, function (up) {
            up.attachments = (Array.isArray(up.attachments) ? up.attachments : []).filter(function (x) { return !(x && x.storageCid === a.storageCid) })
        }, "Removed " + str(a.name))
    }
    // Async Storage transfers: the core returns a ref, the view polls attachmentStatus (no blocking IPC).
    property var transfers: []              // [{ref, cb}]
    function transfer(method, args, cb) {
        core(method, args, function (r) {
            var ref = String(j(r, "") || "")
            if (!ref) { cb({ ok: false, error: "the ‘scala’ package didn't start the transfer (needs Logos Storage)" }); return }
            transfers = transfers.concat([{ ref: ref, cb: cb }])
        })
    }
    property bool pollBusy: false
    Timer {
        interval: 700; repeat: true; running: root.transfers.length > 0
        onTriggered: {
            if (root.pollBusy) return
            var t = root.transfers[0]
            root.pollBusy = true
            root.core("attachmentStatus", [t.ref], function (raw) {
                root.pollBusy = false
                var r = root.j(raw, {})
                if (r && r.pending) return
                root.transfers = root.transfers.filter(function (x) { return x.ref !== t.ref })
                t.cb(r || { ok: false })
            })
        }
    }

    // ── tasks, gear, budget, social posts ───────────────────────────────────────
    readonly property var taskCats: ["booking", "comms", "social", "payment", "contract", "print", "other"]
    function tasksOf(ev) {
        var xs = itemsOf(master(ev), "task")
        xs.sort(function (a, b) { return (a.d.done === true) - (b.d.done === true) || (num(a.d.due) || 9e15) - (num(b.d.due) || 9e15) })
        return xs
    }
    function overdue(it) { return it.d.done !== true && num(it.d.due) !== null && it.d.due < Date.now() }
    function dueSoon(it) { return it.d.done !== true && num(it.d.due) !== null && it.d.due >= Date.now() && it.d.due < Date.now() + 3 * 864e5 }
    function openTaskCount(ev) { return tasksOf(ev).filter(function (t) { return t.d.done !== true }).length }
    readonly property var myOverdue: {
        var n = 0
        for (var i = 0; i < events.length; i++) { var c = calById(events[i].calendarId); if (!c || !isFreqCal(c)) continue
            var ts = itemsOf(events[i], "task"); for (var k = 0; k < ts.length; k++) if (overdue(ts[k])) n++ }
        return n
    }
    readonly property var gearPresets: ["CDJs", "Mixer", "Monitors", "Projector", "Mics", "Laptop stand", "Extension leads", "Install station"]
    function gearOf(ev) { var xs = itemsOf(master(ev), "gear"); xs.sort(function (a, b) { return (a.d.done === true) - (b.d.done === true) || str(a.d.item).localeCompare(str(b.d.item)) }); return xs }
    function postsOf(ev) { var xs = itemsOf(master(ev), "post"); xs.sort(function (a, b) { return (num(a.d.when) || 9e15) - (num(b.d.when) || 9e15) }); return xs }
    readonly property var postChannels: ["Instagram", "Luma", "X", "Newsletter", "Radio", "Other"]
    function budgetOf(ev) { return itemsOf(master(ev), "budget") }
    // The night's money: budget lines + confirmed/asked artist fees (out) + ticket sales (in).
    function moneyOf(ev) {
        var m = master(ev), r = { inc: 0, out: 0, fees: 0, tickets: 0, cur: "EUR" }
        if (!m) return r
        var lines = budgetOf(m)
        for (var i = 0; i < lines.length; i++) { var a = num(lines[i].d.amount); if (a === null) continue; if (str(lines[i].d.currency)) r.cur = str(lines[i].d.currency); if (lines[i].d.dir === "in") r.inc += a; else r.out += a }
        var lu = lineupOf(m)
        for (var k = 0; k < lu.length; k++) if (lu[k].fee !== null && lu[k].status !== "cancelled") { r.fees += lu[k].fee; if (lu[k].currency) r.cur = lu[k].currency }
        r.tickets = ticketRevenue(ticketsOf(m))
        r.income = r.inc + r.tickets; r.costs = r.out + r.fees; r.profit = r.income - r.costs
        return r
    }
    function money(n, cur) { var s = Math.round(n * 100) / 100; return (s < 0 ? "−" : "") + Math.abs(s).toLocaleString(Qt.locale(), "f", s % 1 ? 2 : 0) + " " + (cur || "EUR") }

    // ── item editor (one popup for task / gear / budget line / social post) ──────
    property string itKind: ""
    property string itId: ""
    property string itCat: "other"
    property string itDir: "out"
    property string itChannel: "Instagram"
    property bool itDone: false
    function openItem(kind, it) {
        if (!selMaster) return
        itKind = kind; itId = it ? it.id : ""
        var d = it ? it.d : {}
        itText.text = str(d.text || d.item || d.label)
        itAmount.text = num(d.amount) !== null ? String(d.amount) : ""
        itCur.text = str(d.currency) || "EUR"
        itCat = str(d.cat) || "other"; itDir = d.dir === "in" ? "in" : "out"; itChannel = str(d.channel) || "Instagram"; itDone = d.done === true
        var when = num(d.due) !== null ? d.due : num(d.when)
        var dd = when !== null ? new Date(when) : null
        itDate.text = dd ? dd.getFullYear() + "-" + pad(dd.getMonth() + 1) + "-" + pad(dd.getDate()) : ""
        itTime.text = dd ? pad(dd.getHours()) + ":" + pad(dd.getMinutes()) : (kind === "post" ? "18:00" : "12:00")
        itemPopup.open(); itText.forceActiveFocus()
    }
    function saveItemFromPopup() {
        var t = itText.text.trim()
        if (!t) { notify("Write something first.", true); return }
        var d = {}
        var when = itDate.text.trim() ? parseLocal(itDate.text, itTime.text || "12:00") : null
        if (itDate.text.trim() && !when) { notify("Use a date like 2026-11-24 and a time like 18:00.", true); return }
        if (itKind === "task") { d = { text: t, cat: itCat, done: itDone }; if (when) d.due = when.getTime() }
        else if (itKind === "gear") d = { item: t, done: itDone }
        else if (itKind === "post") { d = { text: t, channel: itChannel, done: itDone }; if (when) d.when = when.getTime() }
        else if (itKind === "budget") {
            var a = Number(itAmount.text.trim().replace(",", "."))
            if (!(isFinite(a) && a >= 0) || itAmount.text.trim() === "") { notify("The amount should be a number, for example 250.", true); return }
            d = { label: t, amount: a, currency: itCur.text.trim().toUpperCase() || "EUR", dir: itDir }
        }
        saveItem(selMaster, itKind, d, itId, itId ? "Updated" : "Added")
        itemPopup.close()
    }
    readonly property var kindLabel: ({ task: "Task", gear: "Gear", budget: "Budget line", post: "Social post" })

    // ── duplicate a night in one click (next week, as a Hold, line-up asked again) ──
    function duplicateNight() {
        var m = selMaster
        if (!m || creating) return
        var wk = 7 * 864e5
        var ev = { title: (m.title || "Untitled night"), startTime: m.startTime + wk, endTime: (m.endTime || m.startTime) + wk, reminderMin: 60,
                   fields: { status: "Hold", venue: fieldOf(m, "venue"), type: fieldOf(m, "type") || "Club night" } }
        if (m.description) ev.description = m.description
        creating = true
        core("createEvent", [m.calendarId, JSON.stringify(ev)], function (r) {
            creating = false
            var id = String(j(r, "") || "")
            if (!id) { notify("Couldn't duplicate the night.", true); return }
            var copies = []
            var lu = lineupOf(m)
            for (var i = 0; i < lu.length; i++) if (lu[i].status !== "cancelled") {
                var d = { name: lu[i].name, status: "asked" }
                if (lu[i].contact) { d.contact = lu[i].contact; d.book = lu[i].book }
                if (lu[i].fee !== null) { d.fee = lu[i].fee; d.currency = lu[i].currency }
                if (lu[i].set) d.set = lu[i].set
                copies.push({ kind: "artist", data: d })
            }
            var cr = crewOf(m)
            for (var c = 0; c < cr.length; c++) if (cr[c].role && cr[c].status !== "cancelled") copies.push({ kind: "crew", data: { name: "", role: cr[c].role, status: "asked", call: cr[c].call } })
            var gs = gearOf(m)
            for (var g = 0; g < gs.length; g++) copies.push({ kind: "gear", data: { item: str(gs[g].d.item), done: false } })
            var tg = tagsOf(m)
            if (tg.length) copies.push({ kind: "tags", id: "tags:" + id + ":" + rnd(), data: { tags: tg } })
            for (var k = 0; k < copies.length; k++) {
                var it = { ns: "xyz.freequencies", kind: copies[k].kind, target: id, data: copies[k].data }
                if (copies[k].id) it.id = copies[k].id
                core("postExt", [m.calendarId, JSON.stringify(it)], function () {})
            }
            notify("Duplicated to " + Qt.formatDate(new Date(ev.startTime), "d MMM") + " as a Hold")
            Qt.callLater(function () { refresh(); var d0 = new Date(ev.startTime); d0.setHours(0, 0, 0, 0); goTo(d0) })
        })
    }

    // ── search & filters (apply to every view) ──────────────────────────────────
    property string q: ""
    property var fStatus: ({})               // status -> true; empty = all
    property string fType: ""
    property string fTag: ""
    property string fVenue: ""
    readonly property bool filtering: q.trim() !== "" || Object.keys(fStatus).length > 0 || fType !== "" || fTag !== "" || fVenue !== ""
    function toggleStatusFilter(s) { var o = {}; for (var k in fStatus) o[k] = true; if (o[s]) delete o[s]; else o[s] = true; fStatus = o }
    function clearFilters() { q = ""; searchBox.text = ""; fStatus = ({}); fType = ""; fTag = ""; fVenue = "" }
    function passes(o) {
        var m = master(o)
        if (Object.keys(fStatus).length && !fStatus[fieldOf(m, "status")]) return false
        if (fType && fieldOf(m, "type") !== fType) return false
        if (fVenue && fieldOf(m, "venue").toLowerCase() !== fVenue.toLowerCase()) return false
        if (fTag && tagsOf(m).indexOf(fTag) < 0) return false
        var qq = q.trim().toLowerCase()
        if (qq) {
            var hay = [m.title || "", fieldOf(m, "venue"), fieldOf(m, "type"), m.description || ""]
                .concat(lineupOf(m).map(function (b) { return b.name })).concat(crewOf(m).map(function (c) { return c.name }))
                .concat(tagsOf(m)).join(" \n ").toLowerCase()
            if (hay.indexOf(qq) < 0) return false
        }
        return true
    }
    readonly property var shownSrc: {
        var ids = {}, src = []
        for (var i = 0; i < shownCals.length; i++) ids[shownCals[i].id] = true
        for (var k = 0; k < events.length; k++) if (ids[events[k].calendarId]) src.push(events[k])
        return src
    }
    function occsIn(a, b) { return expandEvents(shownSrc, a, b).filter(function (o) { return o.startTime >= a && o.startTime < b && root.passes(o) }) }

    // ── colour by status / type / venue / calendar ──────────────────────────────
    property string colorBy: "status"
    readonly property var swatch: ["#6ef600", "#4aa8ff", "#ff6ad5", "#ffc531", "#3fe0d0", "#b98cff", "#ff8a3d", "#7bf686"]
    function hashColor(s) { var h = 0; s = String(s || ""); for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0; return swatch[Math.abs(h) % swatch.length] }
    function typeColor(t) { var i = types.indexOf(t); return i < 0 ? cFaint : ["#6ef600", "#4aa8ff", "#ff6ad5", "#ffc531"][i] }
    function nightColor(o) {
        var m = master(o)
        if (colorBy === "type") return typeColor(fieldOf(m, "type"))
        if (colorBy === "venue") return fieldOf(m, "venue") ? hashColor(fieldOf(m, "venue").toLowerCase()) : cFaint
        if (colorBy === "calendar") return hashColor(m.calendarId)
        return statusColor(fieldOf(m, "status"))
    }
    readonly property var legend: {
        var out = []
        if (colorBy === "status") for (var i = 0; i < statuses.length; i++) out.push({ label: statuses[i], color: statusColor(statuses[i]) })
        else if (colorBy === "type") for (var t = 0; t < types.length; t++) out.push({ label: types[t], color: typeColor(types[t]) })
        else if (colorBy === "calendar") for (var c = 0; c < freqCals.length; c++) out.push({ label: freqCals[c].name || "(unnamed)", color: hashColor(freqCals[c].id) })
        else for (var v = 0; v < venues.length && v < 10; v++) out.push({ label: venues[v].name, color: hashColor(venues[v].name.toLowerCase()) })
        return out
    }

    // ── views and their windows ─────────────────────────────────────────────────
    property string view: "month"            // board | month | week | timeline | venues | stats
    readonly property var viewTabs: [{ id: "month", l: "Month" }, { id: "week", l: "Week" }, { id: "board", l: "Board" }, { id: "timeline", l: "Timeline" },
                                     { id: "venues", l: "Venues" }, { id: "stats", l: "Analytics" }]
    property date monthAnchor: { var d = new Date(); return new Date(d.getFullYear(), d.getMonth(), 1) }
    property date weekStart: mondayOf(new Date())
    property bool tlPast: false
    function mondayOf(d) { var x = new Date(d); x.setHours(0, 0, 0, 0); x.setDate(x.getDate() - ((x.getDay() + 6) % 7)); return x }
    function addDays(t, n) { var d = new Date(t); d.setDate(d.getDate() + n); return d.getTime() }
    function today0() { var d = new Date(); d.setHours(0, 0, 0, 0); return d.getTime() }
    readonly property real gridStart: mondayOf(monthAnchor).getTime()
    readonly property real winStart: view === "board" ? new Date(firstDay).getTime() : view === "week" ? new Date(weekStart).getTime()
                                   : view === "month" ? gridStart : view === "timeline" ? (tlPast ? addDays(today0(), -365) : today0()) : addDays(today0(), -365)
    readonly property real winEnd: view === "board" ? addDays(new Date(firstDay).getTime(), nDays) : view === "week" ? addDays(new Date(weekStart).getTime(), 7)
                                 : view === "month" ? addDays(gridStart, 42) : view === "timeline" ? (tlPast ? today0() : addDays(today0(), 365)) : addDays(today0(), 365)
    function step(dir) {
        if (view === "board") shiftDays(7 * dir)
        else if (view === "week") weekStart = new Date(addDays(new Date(weekStart).getTime(), 7 * dir))
        else if (view === "month") monthAnchor = new Date(monthAnchor.getFullYear(), monthAnchor.getMonth() + dir, 1)
    }
    function goTo(d) {
        var x = new Date(d); x.setHours(0, 0, 0, 0)
        firstDay = x; weekStart = mondayOf(x); monthAnchor = new Date(x.getFullYear(), x.getMonth(), 1)
    }
    function viewLabel() {
        if (view === "board") return rangeLabel()
        if (view === "week") { var a = new Date(weekStart), b = new Date(addDays(a.getTime(), 6)); return Qt.formatDate(a, "d MMM") + " – " + Qt.formatDate(b, "d MMM yyyy") }
        if (view === "month") return Qt.formatDate(monthAnchor, "MMMM yyyy")
        if (view === "timeline") return tlPast ? "Past gatherings" : "Coming up"
        if (view === "venues") return "Venues"
        return "Analytics"
    }
    readonly property var monthDays: {
        var s = gridStart, occs = occsIn(s, addDays(s, 42)), out = [], t0 = today0()
        for (var i = 0; i < 42; i++) {
            var d = addDays(s, i), e = addDays(s, i + 1), xs = []
            for (var k = 0; k < occs.length; k++) if (occs[k].startTime >= d && occs[k].startTime < e) xs.push(occs[k])
            out.push({ date: d, inMonth: new Date(d).getMonth() === monthAnchor.getMonth(), today: d === t0, occs: xs })
        }
        return out
    }
    readonly property var weekDays: {
        var s = new Date(weekStart).getTime(), occs = occsIn(s, addDays(s, 7)), out = [], t0 = today0()
        for (var i = 0; i < 7; i++) {
            var d = addDays(s, i), e = addDays(s, i + 1), xs = []
            for (var k = 0; k < occs.length; k++) if (occs[k].startTime >= d && occs[k].startTime < e) xs.push(occs[k])
            out.push({ date: d, today: d === t0, occs: xs })
        }
        return out
    }
    readonly property var timeline: {
        var occs = occsIn(winStart, winEnd), groups = [], cur = null
        if (tlPast) occs.reverse()
        for (var i = 0; i < occs.length; i++) {
            var key = Qt.formatDate(new Date(occs[i].startTime), "MMMM yyyy")
            if (!cur || cur.label !== key) { cur = { label: key, occs: [] }; groups.push(cur) }
            cur.occs.push(occs[i])
        }
        return groups
    }

    // ── drag & drop: move a night to another day (and lane on the board) ─────────
    property var dragOcc: null
    function moveNight(o, dayMs, laneId) {
        if (!o) return
        var m = master(o)
        if (!canEdit(m)) { notify("You can't move nights on this calendar.", true); return }
        var from = new Date(o.startTime), to = new Date(dayMs)
        to.setHours(from.getHours(), from.getMinutes(), 0, 0)
        var shift = to.getTime() - from.getTime()
        var setVenue = view === "board" && laneBy === "venue" && laneId !== undefined && laneId !== "—" && laneId !== fieldOf(m, "venue")
        var setStatus = view === "board" && laneBy === "status" && laneId && statuses.indexOf(laneId) >= 0 && laneId !== fieldOf(m, "status")
        if (view === "board" && laneBy === "calendar" && laneId && laneId !== m.calendarId) notify("Nights can't move between calendars yet: duplicate it there instead.", true)
        if (shift === 0 && !setVenue && !setStatus) return
        editNight(m, function (up) {
            up.startTime += shift; up.endTime = (up.endTime || up.startTime) + shift
            if (setVenue) up.fields.venue = laneId
            if (setStatus) up.fields.status = laneId
        }, "Moved “" + (m.title || "night") + "” to " + Qt.formatDate(to, "ddd d MMM") + (setVenue ? " · " + laneId : "") + (setStatus ? " · " + laneId : "")
           + (m.recur && m.recur.freq ? " (whole series)" : ""))
    }

    // ── conflicts: the same venue double-booked (across all Freequencies calendars) ──
    readonly property var venueClashes: {
        var ids = {}, src = []
        for (var i = 0; i < freqCals.length; i++) ids[freqCals[i].id] = true
        for (var k = 0; k < events.length; k++) if (ids[events[k].calendarId]) src.push(events[k])
        var occs = expandEvents(src, winStart - 864e5, winEnd + 864e5).filter(function (o) { return fieldOf(o, "status") !== "Cancelled" && fieldOf(o, "venue") !== "" })
        var out = {}
        for (var a = 0; a < occs.length; a++) for (var b = a + 1; b < occs.length; b++) {
            var p = occs[a], q2 = occs[b]
            if (fieldOf(p, "venue").toLowerCase() !== fieldOf(q2, "venue").toLowerCase()) continue
            if (!(p.startTime < q2.endTime && q2.startTime < p.endTime)) continue
            ;(out[occKey(p)] = out[occKey(p)] || []).push(q2)
            ;(out[occKey(q2)] = out[occKey(q2)] || []).push(p)
        }
        return out
    }
    function hasClash(o) { var k = occKey(o); return !!doubles[k] || !!venueClashes[k] }
    function clashLine(o) { return "⚠ " + fieldOf(o, "venue") + " is also booked for " + (o.title || "another night") + ", " + Qt.formatDateTime(new Date(o.startTime), "d MMM hh:mm") }

    // ── venues (saved once, reused: every venue a night has used) ────────────────
    readonly property var venues: {
        var by = {}, out = [], t0 = today0()
        for (var i = 0; i < events.length; i++) {
            var c = calById(events[i].calendarId); if (!c || !isFreqCal(c)) continue
            var v = fieldOf(events[i], "venue").trim(); if (!v) continue
            var key = v.toLowerCase(), e = events[i]
            if (!by[key]) { by[key] = { name: v, nights: 0, upcoming: 0, next: 0, last: 0, attendance: 0, cals: {} }; out.push(by[key]) }
            var r = by[key]
            r.nights++; r.cals[c.name || "(unnamed)"] = true
            if (e.startTime >= t0) { r.upcoming++; if (!r.next || e.startTime < r.next) r.next = e.startTime }
            else if (e.startTime > r.last) r.last = e.startTime
            r.attendance += attendanceOf(e)
        }
        out.sort(function (a, b) { return b.nights - a.nights || a.name.localeCompare(b.name) })
        return out
    }
    function openMap(v) { Qt.openUrlExternally("https://www.openstreetmap.org/search?query=" + encodeURIComponent(v + ", Lisboa")) }

    // ── analytics: nights per month, attendance, revenue ─────────────────────────
    function goingOf(ev) { var n = 0, r = (ev && ev.rsvps) || {}; for (var k in r) if (r[k] === "going") n++; return n }
    function attendanceOf(ev) { var t = ticketsOf(ev); return t && num(t.sold) !== null ? t.sold : goingOf(ev) }
    readonly property var stats: {
        var now = new Date(), months = []
        for (var i = -5; i <= 2; i++) { var d = new Date(now.getFullYear(), now.getMonth() + i, 1); months.push({ label: Qt.formatDate(d, "MMM"), start: d.getTime(), end: new Date(d.getFullYear(), d.getMonth() + 1, 1).getTime(), nights: 0, cancelled: 0, attendance: 0, revenue: 0, profit: 0 }) }
        var ids = {}, src = []
        for (var c = 0; c < shownCals.length; c++) ids[shownCals[c].id] = true
        for (var k = 0; k < events.length; k++) if (ids[events[k].calendarId]) src.push(events[k])
        var occs = expandEvents(src, months[0].start, months[months.length - 1].end).filter(function (o) { return root.passes(o) })
        var tot = { nights: 0, attendance: 0, revenue: 0, profit: 0, confirmed: 0, hold: 0, cancelled: 0, artists: 0 }, seenArtist = {}, byTag = {}, byVenue = {}
        for (var a = 0; a < occs.length; a++) {
            var o = occs[a], m = master(o), st = fieldOf(m, "status")
            for (var b = 0; b < months.length; b++) if (o.startTime >= months[b].start && o.startTime < months[b].end) {
                var mo = months[b]
                if (st === "Cancelled") { mo.cancelled++; tot.cancelled++; break }
                var money_ = moneyOf(m), att = attendanceOf(m)
                mo.nights++; mo.attendance += att; mo.revenue += money_.income; mo.profit += money_.profit
                tot.nights++; tot.attendance += att; tot.revenue += money_.income; tot.profit += money_.profit
                if (st === "Confirmed") tot.confirmed++; else tot.hold++
                var lu = lineupOf(m); for (var l = 0; l < lu.length; l++) if (!seenArtist[artistKey(lu[l])]) { seenArtist[artistKey(lu[l])] = true; tot.artists++ }
                var tg = tagsOf(m); for (var t = 0; t < tg.length; t++) byTag[tg[t]] = (byTag[tg[t]] || 0) + 1
                var v = fieldOf(m, "venue"); if (v) byVenue[v] = (byVenue[v] || 0) + 1
                break
            }
        }
        var maxN = 1, maxA = 1, maxR = 1
        for (var x = 0; x < months.length; x++) { maxN = Math.max(maxN, months[x].nights); maxA = Math.max(maxA, months[x].attendance); maxR = Math.max(maxR, months[x].revenue) }
        var tags = Object.keys(byTag).map(function (k2) { return { label: k2, n: byTag[k2] } }).sort(function (p, q3) { return q3.n - p.n }).slice(0, 8)
        var vs = Object.keys(byVenue).map(function (k3) { return { label: k3, n: byVenue[k3] } }).sort(function (p, q4) { return q4.n - p.n }).slice(0, 6)
        return { months: months, tot: tot, maxN: maxN, maxA: maxA, maxR: maxR, tags: tags, venues: vs }
    }

    // ── permissions: what I can do on each calendar ─────────────────────────────
    function roleOf(c) {
        if (!c) return ""
        var me = c.authorAddr || ""
        if (me && c.owner === me) return "owner"
        var r = (c.roles || {})[me]
        return r === "admin" ? "editor" : (r || (c.collab ? "member" : "viewer"))
    }
    function memberCount(c) { var n = 1, r = (c && c.roles) || {}; for (var k in r) n++; return n }


    // ── small components (Freequencies design language: terminal ground, ruled lines, square corners) ──
    component FText: LogosText { textFormat: Text.PlainText; font.family: root.fBody; color: root.cText }
    component DText: LogosText { textFormat: Text.PlainText; font.family: root.fDisplay; color: root.cText; font.letterSpacing: 0.6 }
    // Pixel-bracket kicker: (( text )) — the signal motif from the posters.
    component Kicker: FText { property string label: ""; text: "( " + label + " )"; color: root.cLime; font.pixelSize: 12; font.letterSpacing: 1.2 }
    component Link: FText {
        id: lk
        signal clicked()
        property color tone: root.cAcid
        color: lkMA.containsMouse ? root.cText : tone; font.pixelSize: 12; font.underline: lkMA.containsMouse
        MouseArea { id: lkMA; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lk.clicked() }
    }
    component Chip: Rectangle {
        id: chip
        property string text: ""
        property bool on: false
        property color accent: root.cLime
        signal clicked()
        height: 26; width: chipT.implicitWidth + 20
        color: on ? accent : (chipMA.containsMouse ? root.cSurface : "transparent")
        border.width: 1; border.color: on ? accent : root.cLine
        FText { id: chipT; anchors.centerIn: parent; text: chip.text; color: chip.on ? root.cCrust : root.cSub; font.pixelSize: 12 }
        MouseArea { id: chipMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
    }
    // Text input styled with the tokens (the DS TextField would otherwise be light on light).
    component Input: TextField {
        color: root.cText; font.pixelSize: 13; font.family: root.fBody
        placeholderTextColor: root.cFaint; selectionColor: root.cLime; selectedTextColor: root.cCrust
        leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
        background: Rectangle { color: root.cMantle; border.width: 1; border.color: parent.activeFocus ? root.cLime : root.cLine }
    }
    component Btn: Rectangle {
        id: btn
        property string text: ""
        property bool primary: false
        property bool enabled_: true
        signal clicked()
        height: 32; width: btnT.implicitWidth + 26
        opacity: enabled_ ? 1 : 0.4
        color: primary ? (btnMA.containsMouse ? root.cAcid : root.cLime) : (btnMA.containsMouse ? root.cSurface : "transparent")
        border.width: primary ? 0 : 1; border.color: btnMA.containsMouse ? root.cLime : root.cLine
        FText { id: btnT; anchors.centerIn: parent; text: btn.text.toUpperCase(); color: btn.primary ? root.cCrust : root.cText; font.pixelSize: 12; font.letterSpacing: 1.1; font.bold: btn.primary }
        MouseArea { id: btnMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (btn.enabled_) btn.clicked() }
    }
    // Section heading in the night panel: ">_ LABEL ───────── + action"
    component Sec: RowLayout {
        id: sec
        property string label: ""
        property string action: ""
        signal act()
        Layout.fillWidth: true; Layout.topMargin: 16; spacing: 8
        FText { text: ">_ " + sec.label.toUpperCase(); color: root.cLime; font.pixelSize: 12; font.letterSpacing: 1.2 }
        Rectangle { Layout.fillWidth: true; height: 1; color: root.cLine }
        Link { visible: sec.action !== ""; text: sec.action; onClicked: sec.act() }
    }
    // Square status mark (the board's colour key), and a status badge.
    component Badge: Rectangle {
        id: bd
        property string text: ""
        property color tone: root.cLime
        height: 20; width: bdT.implicitWidth + 12; color: "transparent"; border.width: 1; border.color: tone
        FText { id: bdT; anchors.centerIn: parent; text: bd.text.toUpperCase(); color: bd.tone; font.pixelSize: 11; font.letterSpacing: 1 }
    }
    // A row in a checklist (tasks, gear, posts): [x] text · meta
    component CheckRow: Rectangle {
        id: crow
        property string text: ""
        property string meta: ""
        property bool done: false
        property color metaTone: root.cSub
        signal toggled()
        signal opened()
        Layout.fillWidth: true; Layout.preferredHeight: crowCol.implicitHeight + 12
        color: crowMA.containsMouse ? root.cSurface : "transparent"; border.width: 1; border.color: root.cLine
        MouseArea { id: crowMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: crow.opened() }
        Rectangle {
            id: box
            x: 8; anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14
            color: crow.done ? root.cLime : "transparent"; border.width: 1; border.color: crow.done ? root.cLime : root.cSub
            FText { anchors.centerIn: parent; visible: crow.done; text: "✓"; color: root.cCrust; font.pixelSize: 11; font.bold: true }
            MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: crow.toggled() }
        }
        Column {
            id: crowCol
            x: 30; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 38; spacing: 1
            FText { width: parent.width; elide: Text.ElideRight; text: crow.text; font.pixelSize: 13; color: crow.done ? root.cSub : root.cText; font.strikeout: crow.done }
            FText { width: parent.width; elide: Text.ElideRight; visible: crow.meta !== ""; text: crow.meta; font.pixelSize: 12; color: crow.metaTone }
        }
    }
    // A night as a card on the month / week / board views. Drag it to another day to move it.
    component NightCard: Rectangle {
        id: nc
        property var occ: null
        property bool compact: false
        readonly property var m: root.master(occ)
        readonly property string status: root.fieldOf(m, "status")
        readonly property bool isSel: !!root.selected && !!occ && root.selected.id === occ.id && root.selected.occ === occ.occ
        readonly property string poster: compact ? "" : root.posterSrc(m)
        height: compact ? 22 : Math.max(48, ncCol.implicitHeight + 10)
        color: isSel ? root.cSurface2 : (ncMA.containsMouse ? root.cSurface : root.cMantle)
        border.width: 1; border.color: isSel ? root.cLime : root.cLine
        opacity: root.dragOcc && root.dragOcc.id === (occ ? occ.id : "") && root.dragOcc.occ === (occ ? occ.occ : 0) ? 0.35 : 1
        Rectangle { width: 4; height: parent.height; color: root.nightColor(nc.occ) }
        Image {
            id: thumb
            visible: nc.poster !== "" && status === Image.Ready && nc.width >= 160
            source: nc.poster; asynchronous: true; fillMode: Image.PreserveAspectCrop
            width: visible ? 34 : 0; height: 42; x: parent.width - width - 4; anchors.verticalCenter: parent.verticalCenter
            sourceSize.width: 80
        }
        Row {
            visible: nc.compact; x: 8; spacing: 5; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 12; clip: true
            FText { text: nc.occ && !nc.occ.allDay ? Qt.formatTime(new Date(nc.occ.startTime), "hh:mm") : ""; color: root.cSub; font.pixelSize: 11 }
            FText { text: (root.hasClash(nc.occ) ? "⚠ " : "") + (nc.occ ? (nc.occ.title || "(untitled)") : ""); color: root.hasClash(nc.occ) ? root.cWarn : root.cText; font.pixelSize: 12; font.strikeout: nc.status === "Cancelled" }
        }
        Column {
            id: ncCol
            visible: !nc.compact
            x: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 16 - thumb.width; spacing: 1
            FText { width: parent.width; elide: Text.ElideRight; wrapMode: Text.Wrap; maximumLineCount: 2; font.pixelSize: 13; color: root.cText; font.strikeout: nc.status === "Cancelled"; text: nc.occ ? (nc.occ.title || "(untitled)") : "" }
            FText { width: parent.width; elide: Text.ElideRight; font.pixelSize: 11
                color: root.hasClash(nc.occ) ? root.cWarn : root.cSub
                text: nc.occ ? (root.hasClash(nc.occ) ? "⚠ " : "") + (nc.occ.allDay ? "All day" : Qt.formatTime(new Date(nc.occ.startTime), "hh:mm"))
                      + (root.fieldOf(nc.m, "venue") && !(root.view === "board" && root.laneBy === "venue") ? " · " + root.fieldOf(nc.m, "venue") : "")
                      + (nc.status && !(root.view === "board" && root.laneBy === "status") ? " · " + nc.status : "") : "" }
            FText { width: parent.width; elide: Text.ElideRight; font.pixelSize: 11; color: root.cFaint; visible: text !== ""
                text: { var t = root.tagsOf(nc.m), c = root.crewShort(nc.m); return [t.length ? "#" + t.slice(0, 2).join(" #") : "", c].filter(function (x) { return !!x }).join(" · ") } }
        }
        MouseArea {
            id: ncMA
            anchors.fill: parent; hoverEnabled: true; preventStealing: true
            cursorShape: root.dragOcc ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            property point p0
            onPressed: function (mouse) { p0 = Qt.point(mouse.x, mouse.y) }
            onPositionChanged: function (mouse) {
                if (!pressed) return
                if (!root.dragOcc && (Math.abs(mouse.x - p0.x) + Math.abs(mouse.y - p0.y)) > 8 && root.canEdit(nc.m)) root.dragOcc = nc.occ
                if (root.dragOcc) { var p = mapToItem(root, mouse.x, mouse.y); ghost.x = p.x - 12; ghost.y = p.y - 12 }
            }
            onReleased: {
                if (root.dragOcc) { ghost.Drag.drop(); root.dragOcc = null }
                else root.selected = nc.occ
            }
            onCanceled: root.dragOcc = null
        }
    }
    // A drop target: a day (and on the board, a lane).
    component DayDrop: DropArea {
        id: dd
        property real day: 0
        property var lane: undefined
        keys: ["night"]
        onDropped: root.moveNight(root.dragOcc, dd.day, dd.lane)
        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 2; border.color: root.cLime; visible: dd.containsDrag }
    }


    Rectangle { anchors.fill: parent; color: root.cBase }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── header: dish + wordmark, view tabs, new night ─────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 66; color: root.cBase; clip: true
            Repeater {   // CRT scanlines, as on the site's hero
                model: 17
                delegate: Rectangle { required property int index; y: index * 4 + 3; width: parent.width; height: 1; color: root.cLime; opacity: 0.05 }
            }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 14
                Image { source: "dish.png"; Layout.preferredWidth: 42; Layout.preferredHeight: 42; fillMode: Image.PreserveAspectFit; smooth: false; mipmap: false }
                ColumnLayout {
                    spacing: -6
                    DText { text: "FREEQUENCIES"; color: root.cLime; font.pixelSize: 38 }
                    FText { text: "( coordination tool · lisboa )"; color: root.cSub; font.pixelSize: 12; font.letterSpacing: 1 }
                }
                Item { Layout.fillWidth: true }
                Row {
                    spacing: -1
                    Repeater {
                        model: root.viewTabs
                        delegate: Rectangle {
                            id: tab
                            required property var modelData
                            readonly property bool on: root.view === modelData.id
                            height: 34; width: tabT.implicitWidth + 26
                            color: on ? root.cLime : (tabMA.containsMouse ? root.cSurface : "transparent"); border.width: 1; border.color: on ? root.cLime : root.cLine
                            FText { id: tabT; anchors.centerIn: parent; text: tab.modelData.l.toUpperCase(); color: tab.on ? root.cCrust : root.cSub; font.pixelSize: 12; font.letterSpacing: 1.2; font.bold: tab.on }
                            MouseArea { id: tabMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.view = tab.modelData.id }
                        }
                    }
                }
                Btn { text: "+ New night"; primary: true; enabled_: root.freqCals.length > 0; onClicked: root.openNew() }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.cLine }
        }

        // ── toolbar: range, search, filters, colour ───────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: toolCol.implicitHeight + 18; color: root.cBase
            ColumnLayout {
                id: toolCol
                x: 18; y: 9; width: parent.width - 36; spacing: 8
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    readonly property bool nav: root.view === "month" || root.view === "week" || root.view === "board"
                    Btn { visible: parent.nav; text: "‹"; onClicked: root.step(-1) }
                    Btn { visible: parent.nav; text: "Today"; onClicked: root.goTo(new Date()) }
                    Btn { visible: parent.nav; text: "›"; onClicked: root.step(1) }
                    Chip { visible: root.view === "timeline"; text: "Coming up"; on: !root.tlPast; onClicked: root.tlPast = false }
                    Chip { visible: root.view === "timeline"; text: "Past"; on: root.tlPast; onClicked: root.tlPast = true }
                    DText { text: root.viewLabel().toUpperCase(); color: root.cText; font.pixelSize: 32; Layout.leftMargin: 8 }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        visible: root.myOverdue > 0; height: 26; width: odT.implicitWidth + 16; color: "transparent"; border.width: 1; border.color: root.cWarn
                        FText { id: odT; anchors.centerIn: parent; text: "⚠ " + root.myOverdue + " overdue task" + (root.myOverdue === 1 ? "" : "s"); color: root.cWarn; font.pixelSize: 12 }
                    }
                    Input {
                        id: searchBox
                        objectName: "searchBox"
                        Layout.preferredWidth: 280; placeholderText: "Search nights, artists, crew, tags…"
                        onTextChanged: root.q = text
                    }
                }
                Flow {
                    Layout.fillWidth: true; spacing: 6
                    FText { text: "STATUS"; color: root.cFaint; font.pixelSize: 11; font.letterSpacing: 1.2; height: 26; verticalAlignment: Text.AlignVCenter }
                    Repeater { model: root.statuses
                        delegate: Chip { required property var modelData; text: modelData; accent: root.statusColor(modelData); on: !!root.fStatus[modelData]; onClicked: root.toggleStatusFilter(modelData) } }
                    Item { width: 10; height: 26 }
                    FText { text: "TYPE"; color: root.cFaint; font.pixelSize: 11; font.letterSpacing: 1.2; height: 26; verticalAlignment: Text.AlignVCenter }
                    Repeater { model: root.types
                        delegate: Chip { required property var modelData; text: modelData; on: root.fType === modelData; onClicked: root.fType = on ? "" : modelData } }
                    Item { width: 10; height: 26; visible: root.allTags.length > 0 }
                    FText { visible: root.allTags.length > 0; text: "TAG"; color: root.cFaint; font.pixelSize: 11; font.letterSpacing: 1.2; height: 26; verticalAlignment: Text.AlignVCenter }
                    Repeater { model: root.allTags.slice(0, 8)
                        delegate: Chip { required property var modelData; text: "#" + modelData; accent: root.cSignal; on: root.fTag === modelData; onClicked: root.fTag = on ? "" : modelData } }
                    Chip { visible: root.fVenue !== ""; text: "@ " + root.fVenue + "  ✕"; on: true; accent: root.cAcid; onClicked: root.fVenue = "" }
                    Link { visible: root.filtering; text: "clear filters"; height: 26; verticalAlignment: Text.AlignVCenter; onClicked: root.clearFilters() }
                }
                Flow {
                    Layout.fillWidth: true; spacing: 6
                    visible: root.view !== "venues" && root.view !== "stats"
                    FText { text: "COLOUR BY"; color: root.cFaint; font.pixelSize: 11; font.letterSpacing: 1.2; height: 26; verticalAlignment: Text.AlignVCenter }
                    Repeater { model: [{ id: "status", l: "Status" }, { id: "type", l: "Type" }, { id: "venue", l: "Venue" }, { id: "calendar", l: "Calendar" }]
                        delegate: Chip { required property var modelData; text: modelData.l; on: root.colorBy === modelData.id; onClicked: root.colorBy = modelData.id } }
                    Item { width: 10; height: 26; visible: root.view === "board" }
                    FText { visible: root.view === "board"; text: "COLUMNS"; color: root.cFaint; font.pixelSize: 11; font.letterSpacing: 1.2; height: 26; verticalAlignment: Text.AlignVCenter }
                    Repeater { model: root.view === "board" ? [{ id: "venue", l: "Venue" }, { id: "status", l: "Status" }, { id: "calendar", l: "Calendar" }] : []
                        delegate: Chip { required property var modelData; text: modelData.l; on: root.laneBy === modelData.id; onClicked: root.laneBy = modelData.id } }
                    Item { width: 14; height: 26 }
                    Repeater { model: root.legend
                        delegate: Row { required property var modelData; spacing: 5; height: 26
                            Rectangle { width: 10; height: 10; color: modelData.color; anchors.verticalCenter: parent.verticalCenter }
                            FText { text: modelData.label; color: root.cSub; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } } }
                    FText { text: "· drag a night to move it · double-click a day to add one"; color: root.cFaint; font.pixelSize: 11; height: 26; verticalAlignment: Text.AlignVCenter
                        visible: root.view === "month" || root.view === "week" || root.view === "board" }
                }
                FText { visible: root.loadError !== ""; text: root.loadError; color: root.cRed; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.Wrap }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.cLine }
        }

        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

            // ── sidebar: calendars, permissions ──────────────────────────────────
            Rectangle {
                Layout.fillHeight: true; Layout.preferredWidth: 236; color: root.cMantle
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: root.cLine }
                Flickable {
                    id: sideFlick
                    anchors.fill: parent; anchors.margins: 14; clip: true
                    contentWidth: width; contentHeight: sideCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {}
                    ColumnLayout {
                        id: sideCol
                        width: sideFlick.width; spacing: 8
                        FText { text: ">_ CALENDARS"; color: root.cLime; font.pixelSize: 12; font.letterSpacing: 1.2 }
                        FText { visible: !root.loading && root.freqCals.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                            text: "None yet. Pick a Scala calendar below and choose “Use for Freequencies”, or create one in Scala first." }
                        Repeater {
                            model: root.freqCals
                            delegate: ColumnLayout {
                                id: calRow
                                required property var modelData
                                readonly property bool hid: !!root.hiddenCals[modelData.id]
                                Layout.fillWidth: true; spacing: 3
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 8
                                    Rectangle {
                                        width: 12; height: 12
                                        color: calRow.hid ? "transparent" : (root.colorBy === "calendar" ? root.hashColor(calRow.modelData.id) : root.cLime)
                                        border.width: 1; border.color: calRow.hid ? root.cSub : color
                                        MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleCal(calRow.modelData.id) }
                                    }
                                    FText { text: calRow.modelData.name || "(unnamed)"; color: calRow.hid ? root.cSub : root.cText; font.pixelSize: 14; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                FText { Layout.leftMargin: 20; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cFaint; font.pixelSize: 11
                                    text: "you: " + root.roleOf(calRow.modelData) + " · " + root.memberCount(calRow.modelData) + " member" + (root.memberCount(calRow.modelData) === 1 ? "" : "s") }
                                Row {
                                    Layout.leftMargin: 20; spacing: 6; visible: root.isEditorOf(calRow.modelData)
                                    FText { text: "invite:"; color: root.cFaint; font.pixelSize: 11 }
                                    Link { text: "editor"; font.pixelSize: 11; onClicked: root.copyInvite(calRow.modelData.id, "editor") }
                                    FText { text: "·"; color: root.cFaint; font.pixelSize: 11 }
                                    Link { text: "viewer"; font.pixelSize: 11; onClicked: root.copyInvite(calRow.modelData.id, "viewer") }
                                }
                            }
                        }
                        FText { visible: root.otherCals.length > 0; text: ">_ OTHER SCALA CALENDARS"; color: root.cFaint; font.pixelSize: 11; font.letterSpacing: 1.2; Layout.topMargin: 14 }
                        Repeater {
                            model: root.otherCals
                            delegate: ColumnLayout {
                                id: oc
                                required property var modelData
                                readonly property string why: root.adoptBlocker(modelData)
                                Layout.fillWidth: true; spacing: 2
                                FText { text: oc.modelData.name || "(unnamed)"; color: root.cSub; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                                Link { visible: oc.why === ""; text: "use for Freequencies →"; onClicked: root.adoptCalendar(oc.modelData) }
                                FText { visible: oc.why !== ""; text: oc.why; color: root.cFaint; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }
                            }
                        }
                        Item { Layout.preferredHeight: 18 }
                        Rectangle { Layout.fillWidth: true; height: 1; color: root.cLine }
                        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cFaint; font.pixelSize: 11
                            text: "Nights are Scala events: they also show in Scala, and comments are shared. Everything stays on members' devices, synced peer to peer." }
                        FText { text: "( culture, in our own hands )"; color: root.cLime; font.pixelSize: 12; Layout.topMargin: 6 }
                        FText { text: "apoio: λ Logos"; color: root.cSub; font.pixelSize: 12 }
                    }
                }
            }

            // ── content: one view at a time ──────────────────────────────────────
            StackLayout {
                id: stack
                Layout.fillWidth: true; Layout.fillHeight: true
                currentIndex: ["month", "week", "board", "timeline", "venues", "stats"].indexOf(root.view)

                // MONTH ─────────────────────────────────────────────────────────
                Item {
                    id: monthView
                    objectName: "monthView"
                    readonly property real cw: width / 7
                    readonly property real ch: (height - 30) / 6
                    Row {
                        id: monthHead
                        Repeater { model: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
                            delegate: Item { required property var modelData; width: monthView.cw; height: 30
                                FText { x: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: root.cFaint; font.pixelSize: 12; font.letterSpacing: 1.4 } } }
                    }
                    Grid {
                        y: 30; columns: 7
                        Repeater {
                            model: root.monthDays
                            delegate: Rectangle {
                                id: mcell
                                required property var modelData
                                readonly property int cap: Math.max(1, Math.floor((height - 30) / 25))
                                width: monthView.cw; height: monthView.ch
                                color: modelData.inMonth ? root.cBase : root.cMantle
                                border.width: 1; border.color: root.cLine
                                MouseArea { anchors.fill: parent; onDoubleClicked: root.openNew(new Date(mcell.modelData.date), "") }
                                Rectangle {
                                    x: 6; y: 5; width: mdT.implicitWidth + 10; height: 22
                                    color: mcell.modelData.today ? root.cLime : "transparent"
                                    DText { id: mdT; anchors.centerIn: parent; text: new Date(mcell.modelData.date).getDate(); font.pixelSize: 20
                                        color: mcell.modelData.today ? root.cCrust : mcell.modelData.inMonth ? root.cText : root.cFaint }
                                }
                                Column {
                                    x: 4; y: 30; width: parent.width - 8; spacing: 3
                                    Repeater {
                                        model: mcell.modelData.occs.slice(0, mcell.modelData.occs.length > mcell.cap ? mcell.cap - 1 : mcell.cap)
                                        delegate: NightCard { required property var modelData; occ: modelData; compact: true; width: parent.width }
                                    }
                                    Link { visible: mcell.modelData.occs.length > mcell.cap; text: "+" + (mcell.modelData.occs.length - mcell.cap + 1) + " more"
                                        onClicked: { root.weekStart = root.mondayOf(new Date(mcell.modelData.date)); root.view = "week" } }
                                }
                                DayDrop { anchors.fill: parent; day: mcell.modelData.date }
                            }
                        }
                    }
                }

                // WEEK ──────────────────────────────────────────────────────────
                Row {
                    id: weekView
                    Repeater {
                        model: root.weekDays
                        delegate: Rectangle {
                            id: wcol
                            required property var modelData
                            width: weekView.width / 7; height: weekView.height
                            color: { var g = new Date(modelData.date).getDay(); return g === 5 || g === 6 ? root.cMantle : root.cBase }
                            border.width: 1; border.color: root.cLine
                            MouseArea { anchors.fill: parent; onDoubleClicked: root.openNew(new Date(wcol.modelData.date), "") }
                            Column {
                                x: 10; y: 8; spacing: -4
                                FText { text: Qt.formatDate(new Date(wcol.modelData.date), "ddd").toUpperCase(); color: wcol.modelData.today ? root.cLime : root.cFaint; font.pixelSize: 12; font.letterSpacing: 1.4 }
                                DText { text: Qt.formatDate(new Date(wcol.modelData.date), "dd.MM"); color: wcol.modelData.today ? root.cLime : root.cText; font.pixelSize: 34 }
                            }
                            Flickable {
                                x: 6; y: 62; width: parent.width - 12; height: parent.height - 68; clip: true
                                contentHeight: wkCol.implicitHeight; boundsBehavior: Flickable.StopAtBounds
                                Column {
                                    id: wkCol
                                    width: parent.width; spacing: 6
                                    Repeater { model: wcol.modelData.occs
                                        delegate: NightCard { required property var modelData; occ: modelData; width: wkCol.width } }
                                }
                            }
                            DayDrop { anchors.fill: parent; day: wcol.modelData.date }
                        }
                    }
                }

                // BOARD (lanes) ─────────────────────────────────────────────────
                Flickable {
                    id: boardFlick
                    clip: true
                    contentWidth: board.width + 28; contentHeight: board.height + 28
                    ScrollBar.vertical: ScrollBar {}
                    ScrollBar.horizontal: ScrollBar {}
                    FText { x: 14; y: 14; visible: !root.loading && root.loadError === "" && root.grid.lanes.length === 0
                        text: root.freqCals.length ? "No nights in these two weeks. Add one with “+ New night”." : "Set up a calendar on the left to start."
                        color: root.cSub; font.pixelSize: 14 }
                    Column {
                        id: board
                        x: 14; y: 14
                        readonly property int dateW: 74
                        readonly property int cellW: 190
                        Row {
                            Item { width: board.dateW; height: 32 }
                            Repeater {
                                model: root.grid.lanes
                                delegate: Item {
                                    required property var modelData
                                    width: board.cellW; height: 32
                                    Rectangle { visible: root.laneBy === "status"; width: 10; height: 10; x: 6; anchors.verticalCenter: parent.verticalCenter; color: root.statusColor(parent.modelData.id) }
                                    DText { text: parent.modelData.label.toUpperCase(); color: root.cText; font.pixelSize: 20
                                        elide: Text.ElideRight; x: root.laneBy === "status" ? 22 : 6; width: board.cellW - x - 6; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                        Repeater {
                            model: root.grid.days
                            delegate: Row {
                                id: dayRow
                                required property var modelData
                                readonly property bool isToday: new Date(modelData.date).toDateString() === new Date().toDateString()
                                readonly property bool weekend: { var g = new Date(modelData.date).getDay(); return g === 5 || g === 6 }
                                Rectangle {
                                    width: board.dateW; height: cellsRow.height
                                    color: dayRow.weekend ? root.cMantle : "transparent"; border.width: 1; border.color: root.cLine
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter; x: 8; spacing: -3
                                        FText { text: Qt.formatDate(new Date(dayRow.modelData.date), "ddd").toUpperCase(); color: dayRow.isToday ? root.cLime : root.cFaint; font.pixelSize: 11; font.letterSpacing: 1.2 }
                                        DText { text: Qt.formatDate(new Date(dayRow.modelData.date), "dd.MM"); color: dayRow.isToday ? root.cLime : root.cSub; font.pixelSize: 22 }
                                    }
                                }
                                Row {
                                    id: cellsRow
                                    Repeater {
                                        model: dayRow.modelData.cells
                                        delegate: Rectangle {
                                            id: cell
                                            required property var modelData
                                            required property int index
                                            width: board.cellW; height: Math.max(52, cellCol.implicitHeight + 8)
                                            color: dayRow.weekend ? root.cMantle : "transparent"; border.width: 1; border.color: root.cLine
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onDoubleClicked: root.openNew(new Date(dayRow.modelData.date), root.laneBy === "venue" && root.grid.lanes[cell.index] ? root.grid.lanes[cell.index].id : "")
                                            }
                                            Column {
                                                id: cellCol
                                                x: 4; y: 4; width: board.cellW - 8; spacing: 4
                                                Repeater { model: cell.modelData
                                                    delegate: NightCard { required property var modelData; occ: modelData; width: cellCol.width } }
                                            }
                                            DayDrop { anchors.fill: parent; day: dayRow.modelData.date; lane: root.grid.lanes[cell.index] ? root.grid.lanes[cell.index].id : undefined }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // TIMELINE ──────────────────────────────────────────────────────
                Flickable {
                    id: tlFlick
                    objectName: "tlFlick"
                    clip: true; contentWidth: width; contentHeight: tlCol.implicitHeight + 40
                    ScrollBar.vertical: ScrollBar {}
                    ColumnLayout {
                        id: tlCol
                        x: 22; y: 18; width: tlFlick.width - 44; spacing: 10
                        FText { visible: root.timeline.length === 0; text: root.filtering ? "Nothing matches these filters." : (root.tlPast ? "No past nights in the last year." : "Nothing coming up yet."); color: root.cSub; font.pixelSize: 14 }
                        Repeater {
                            model: root.timeline
                            delegate: ColumnLayout {
                                id: grp
                                required property var modelData
                                Layout.fillWidth: true; spacing: 8
                                RowLayout {
                                    Layout.fillWidth: true; Layout.topMargin: 10; spacing: 12
                                    DText { text: grp.modelData.label.toUpperCase(); color: root.cLime; font.pixelSize: 36 }
                                    Rectangle { Layout.fillWidth: true; height: 1; color: root.cLine }
                                    FText { text: grp.modelData.occs.length + (grp.modelData.occs.length === 1 ? " night" : " nights"); color: root.cFaint; font.pixelSize: 12 }
                                }
                                Repeater {
                                    model: grp.modelData.occs
                                    delegate: Rectangle {
                                        id: tli
                                        required property var modelData
                                        readonly property var m: root.master(modelData)
                                        readonly property var t: root.ticketsOf(m)
                                        readonly property string poster: root.posterSrc(m)
                                        readonly property bool isSel: !!root.selected && root.selected.id === modelData.id && root.selected.occ === modelData.occ
                                        Layout.fillWidth: true; Layout.preferredHeight: Math.max(118, tliRow.implicitHeight + 24)
                                        color: tliMA.containsMouse || isSel ? root.cSurface : root.cMantle; border.width: 1; border.color: isSel ? root.cLime : root.cLine
                                        Rectangle { width: 5; height: parent.height; color: root.nightColor(tli.modelData) }
                                        MouseArea { id: tliMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selected = tli.modelData }
                                        RowLayout {
                                            id: tliRow
                                            x: 20; y: 12; width: parent.width - 34; spacing: 18
                                            ColumnLayout {
                                                Layout.preferredWidth: 108; Layout.alignment: Qt.AlignTop; spacing: -6
                                                DText { text: Qt.formatDate(new Date(tli.modelData.startTime), "dd.MM"); color: root.cText; font.pixelSize: 52 }
                                                FText { text: Qt.formatDate(new Date(tli.modelData.startTime), "dddd").toUpperCase(); color: root.cSub; font.pixelSize: 11; font.letterSpacing: 1.2 }
                                            }
                                            Rectangle {
                                                visible: tli.poster !== ""; Layout.preferredWidth: 74; Layout.preferredHeight: 92; Layout.alignment: Qt.AlignTop
                                                color: root.cBase; border.width: 1; border.color: root.cLine
                                                Image { anchors.fill: parent; anchors.margins: 1; source: tli.poster; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 160 }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: 4
                                                RowLayout {
                                                    Layout.fillWidth: true; spacing: 8
                                                    DText { text: (tli.modelData.title || "(untitled)").toUpperCase(); font.pixelSize: 28; color: root.cText; elide: Text.ElideRight; Layout.fillWidth: true
                                                        font.strikeout: root.fieldOf(tli.m, "status") === "Cancelled" }
                                                    Badge { text: root.fieldOf(tli.m, "status") || "—"; tone: root.statusColor(root.fieldOf(tli.m, "status")) }
                                                }
                                                FText { Layout.fillWidth: true; elide: Text.ElideRight; color: root.cSub; font.pixelSize: 13
                                                    text: [Qt.formatTime(new Date(tli.modelData.startTime), "hh:mm") + "–" + Qt.formatTime(new Date(tli.modelData.endTime), "hh:mm"),
                                                           root.fieldOf(tli.m, "venue"), root.fieldOf(tli.m, "type"), (root.calById(tli.m.calendarId) || {}).name || "",
                                                           tli.m.recur && tli.m.recur.freq ? "↻ " + root.repeatLabel(tli.m).toLowerCase() : ""].filter(function (x) { return !!x }).join("  ·  ") }
                                                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cText; font.pixelSize: 13; visible: text !== ""
                                                    text: { var lu = root.lineupOf(tli.m).filter(function (b) { return b.status !== "cancelled" }); return lu.length ? "(( " + lu.map(function (b) { return b.name }).join("  ·  ") + " ))" : "" } }
                                                FText { Layout.fillWidth: true; elide: Text.ElideRight; color: root.cSignal; font.pixelSize: 12; visible: text !== ""
                                                    text: root.tagsOf(tli.m).map(function (x) { return "#" + x }).join("  ") }
                                                RowLayout {
                                                    Layout.fillWidth: true; spacing: 14; visible: !!tli.t || root.openTaskCount(tli.m) > 0 || root.hasClash(tli.modelData)
                                                    Rectangle {
                                                        visible: !!tli.t && root.num(tli.t.capacity) > 0; Layout.preferredWidth: 120; height: 6; color: root.cSurface2
                                                        Rectangle { height: parent.height; width: tli.t && root.num(tli.t.capacity) > 0 ? parent.width * Math.min(1, (root.num(tli.t.sold) || 0) / tli.t.capacity) : 0; color: root.cLime }
                                                    }
                                                    FText { visible: !!tli.t; text: root.ticketLine(tli.t); color: root.cSub; font.pixelSize: 12 }
                                                    FText { visible: root.openTaskCount(tli.m) > 0; text: root.openTaskCount(tli.m) + " open task" + (root.openTaskCount(tli.m) === 1 ? "" : "s"); color: root.cSub; font.pixelSize: 12 }
                                                    FText { visible: root.hasClash(tli.modelData); text: "⚠ clash"; color: root.cWarn; font.pixelSize: 12 }
                                                    Item { Layout.fillWidth: true }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // VENUES ────────────────────────────────────────────────────────
                Flickable {
                    id: venFlick
                    clip: true; contentWidth: width; contentHeight: venCol.implicitHeight + 40
                    ScrollBar.vertical: ScrollBar {}
                    ColumnLayout {
                        id: venCol
                        x: 22; y: 18; width: venFlick.width - 44; spacing: 12
                        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 13
                            text: "Every venue your nights have used, saved once and reused: the new-night form offers them, and a night's venue can be set in one click." }
                        FText { visible: root.venues.length === 0; text: "No venues yet. Give a night a venue and it shows up here."; color: root.cSub; font.pixelSize: 14 }
                        GridLayout {
                            Layout.fillWidth: true; columns: Math.max(1, Math.floor(venCol.width / 300)); columnSpacing: -1; rowSpacing: -1
                            Repeater {
                                model: root.venues
                                delegate: Rectangle {
                                    id: vt
                                    required property var modelData
                                    Layout.fillWidth: true; Layout.preferredHeight: vtCol.implicitHeight + 28
                                    color: root.cMantle; border.width: 1; border.color: root.cLine
                                    Rectangle { width: parent.width; height: 4; color: root.hashColor(vt.modelData.name.toLowerCase()) }
                                    ColumnLayout {
                                        id: vtCol
                                        x: 16; y: 16; width: parent.width - 32; spacing: 4
                                        DText { text: vt.modelData.name.toUpperCase(); font.pixelSize: 34; color: root.cText; elide: Text.ElideRight; Layout.fillWidth: true }
                                        FText { text: vt.modelData.nights + " night" + (vt.modelData.nights === 1 ? "" : "s") + " · " + vt.modelData.upcoming + " coming up"; color: root.cSub; font.pixelSize: 13 }
                                        FText { text: vt.modelData.next ? "Next: " + Qt.formatDate(new Date(vt.modelData.next), "ddd d MMM") : vt.modelData.last ? "Last: " + Qt.formatDate(new Date(vt.modelData.last), "d MMM yyyy") : ""; color: root.cSub; font.pixelSize: 13; visible: text !== "" }
                                        FText { text: vt.modelData.attendance ? vt.modelData.attendance + " people through the door" : ""; color: root.cSub; font.pixelSize: 13; visible: text !== "" }
                                        FText { text: Object.keys(vt.modelData.cals).join(" · "); color: root.cFaint; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Flow {
                                            Layout.fillWidth: true; Layout.topMargin: 6; spacing: 14
                                            Link { text: "show nights"; onClicked: { root.fVenue = vt.modelData.name; root.view = "timeline" } }
                                            Link { text: "new night here"; onClicked: root.openNew(null, vt.modelData.name) }
                                            Link { text: "map ↗"; onClicked: root.openMap(vt.modelData.name) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ANALYTICS ─────────────────────────────────────────────────────
                Flickable {
                    id: stFlick
                    objectName: "stFlick"
                    clip: true; contentWidth: width; contentHeight: stCol.implicitHeight + 40
                    ScrollBar.vertical: ScrollBar {}
                    ColumnLayout {
                        id: stCol
                        x: 22; y: 18; width: stFlick.width - 44; spacing: 14
                        FText { text: "Last six months and the next two, across the calendars shown" + (root.filtering ? ", filtered" : "") + "."; color: root.cSub; font.pixelSize: 13 }
                        GridLayout {
                            Layout.fillWidth: true; columns: stCol.width > 1000 ? 6 : 3; columnSpacing: -1; rowSpacing: -1
                            Repeater {
                                model: [{ l: "Nights", v: String(root.stats.tot.nights), s: root.stats.tot.confirmed + " confirmed · " + root.stats.tot.hold + " on hold" },
                                        { l: "Attendance", v: String(root.stats.tot.attendance), s: "tickets sold, or RSVPs going" },
                                        { l: "Revenue", v: root.money(root.stats.tot.revenue), s: "tickets + income lines" },
                                        { l: "Result", v: root.money(root.stats.tot.profit), s: "after fees and costs" },
                                        { l: "Artists", v: String(root.stats.tot.artists), s: "different acts booked" },
                                        { l: "Cancelled", v: String(root.stats.tot.cancelled), s: "nights called off" }]
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true; Layout.preferredHeight: 104; color: root.cMantle; border.width: 1; border.color: root.cLine
                                    Column {
                                        x: 14; y: 12; width: parent.width - 28; spacing: -2
                                        FText { text: modelData.l.toUpperCase(); color: root.cLime; font.pixelSize: 12; font.letterSpacing: 1.2 }
                                        DText { text: modelData.v; color: root.cText; font.pixelSize: 40; width: parent.width; elide: Text.ElideRight }
                                        FText { text: modelData.s; color: root.cFaint; font.pixelSize: 11; width: parent.width; elide: Text.ElideRight }
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: [{ l: "Nights per month", k: "nights", mx: root.stats.maxN, fmt: false },
                                    { l: "Attendance per month", k: "attendance", mx: root.stats.maxA, fmt: false },
                                    { l: "Revenue per month", k: "revenue", mx: root.stats.maxR, fmt: true }]
                            delegate: ColumnLayout {
                                id: chart
                                required property var modelData
                                Layout.fillWidth: true; spacing: 6
                                FText { text: ">_ " + chart.modelData.l.toUpperCase(); color: root.cLime; font.pixelSize: 12; font.letterSpacing: 1.2; Layout.topMargin: 6 }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 170; color: "transparent"; border.width: 1; border.color: root.cLine
                                    Row {
                                        id: bars
                                        x: 12; y: 10; width: parent.width - 24; height: parent.height - 20
                                        Repeater {
                                            model: root.stats.months
                                            delegate: Item {
                                                id: bar
                                                required property var modelData
                                                readonly property real v: modelData[chart.modelData.k]
                                                readonly property bool future: modelData.start > Date.now()
                                                width: bars.width / root.stats.months.length; height: bars.height
                                                FText { anchors.horizontalCenter: parent.horizontalCenter; y: barR.y - 18; text: bar.v ? (chart.modelData.fmt ? Math.round(bar.v) : bar.v) : ""; color: root.cSub; font.pixelSize: 11 }
                                                Rectangle {
                                                    id: barR
                                                    width: parent.width * 0.56; anchors.horizontalCenter: parent.horizontalCenter
                                                    height: Math.max(bar.v > 0 ? 2 : 0, (parent.height - 40) * bar.v / Math.max(1, chart.modelData.mx)); y: parent.height - 20 - height
                                                    color: bar.future ? "transparent" : root.cLime; border.width: bar.future ? 1 : 0; border.color: root.cLime
                                                }
                                                FText { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 16; text: bar.modelData.label.toUpperCase(); color: bar.future ? root.cFaint : root.cSub; font.pixelSize: 11 }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 24; Layout.topMargin: 6
                            Repeater {
                                model: [{ l: "Top tags", xs: root.stats.tags, pre: "#" }, { l: "Top venues", xs: root.stats.venues, pre: "" }]
                                delegate: ColumnLayout {
                                    id: top
                                    required property var modelData
                                    readonly property string pre: modelData ? modelData.pre : ""
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: 4
                                    FText { text: ">_ " + top.modelData.l.toUpperCase(); color: root.cLime; font.pixelSize: 12; font.letterSpacing: 1.2 }
                                    FText { visible: top.modelData.xs.length === 0; text: "—"; color: root.cFaint; font.pixelSize: 12 }
                                    Repeater { model: top.modelData.xs
                                        delegate: RowLayout { required property var modelData; Layout.fillWidth: true
                                            FText { text: top.pre + modelData.label; color: root.cText; font.pixelSize: 13; Layout.fillWidth: true }
                                            FText { text: modelData.n; color: root.cSub; font.pixelSize: 13 } } }
                                }
                            }
                        }
                    }
                }
            }


            // ── night panel ───────────────────────────────────────────────────────
            Rectangle {
                visible: root.selMaster !== null
                Layout.fillHeight: true; Layout.preferredWidth: 400; color: root.cMantle
                Rectangle { width: 1; height: parent.height; color: root.cLine }
                Flickable {
                    id: panelFlick
                    objectName: "panelFlick"
                    anchors.fill: parent; anchors.leftMargin: 1; clip: true
                    contentWidth: width; contentHeight: panelCol.implicitHeight + 30
                    ScrollBar.vertical: ScrollBar {}
                    ColumnLayout {
                        id: panelCol
                        width: panelFlick.width; spacing: 0

                        // Poster block: acid green, ink type — the event poster's own look.
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: hdr.implicitHeight + 30; color: root.cAcid
                            ColumnLayout {
                                id: hdr
                                x: 16; y: 15; width: parent.width - 32; spacing: 2
                                RowLayout {
                                    Layout.fillWidth: true
                                    FText { text: root.selected ? (root.selected.endTime < Date.now() ? "( past gathering )" : "( next gathering )") : ""; color: root.cCrust; font.pixelSize: 12; font.letterSpacing: 1.2; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    FText { text: "✕"; color: root.cCrust; font.pixelSize: 16
                                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: root.selected = null } }
                                }
                                DText { text: root.selected ? Qt.formatDate(new Date(root.selected.startTime), "dd.MM") : ""; color: root.cCrust; font.pixelSize: 72; Layout.topMargin: -4 }
                                DText { text: root.selMaster ? (root.selMaster.title || "(untitled)").toUpperCase() : ""; color: root.cCrust; font.pixelSize: 32; wrapMode: Text.Wrap; Layout.fillWidth: true; Layout.topMargin: -10 }
                                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cCrust; font.pixelSize: 13
                                    text: root.selected ? Qt.formatDate(new Date(root.selected.startTime), "dddd") + "  ·  " + Qt.formatTime(new Date(root.selected.startTime), "hh'h'mm") + " às " + Qt.formatTime(new Date(root.selected.endTime), "hh'h'mm")
                                        + (root.fieldOf(root.selMaster, "venue") ? "  ·  " + root.fieldOf(root.selMaster, "venue") : "") : "" }
                                Flow {
                                    Layout.fillWidth: true; Layout.topMargin: 6; spacing: 6
                                    Badge { text: root.fieldOf(root.selMaster, "status") || "no status"; tone: root.cCrust }
                                    Badge { visible: root.fieldOf(root.selMaster, "type") !== ""; text: root.fieldOf(root.selMaster, "type"); tone: root.cCrust }
                                    Badge { visible: !!root.selCal; text: root.selCal ? root.selCal.name || "" : ""; tone: root.cCrust }
                                    Badge { visible: !!root.selMaster && !!root.selMaster.recur && !!root.selMaster.recur.freq; text: "↻ " + root.repeatLabel(root.selMaster); tone: root.cCrust }
                                }
                            }
                        }
                        Image {
                            id: bigPoster
                            readonly property string src: root.posterSrc(root.selMaster)
                            visible: src !== "" && status === Image.Ready
                            source: src; asynchronous: true; fillMode: Image.PreserveAspectFit
                            Layout.fillWidth: true; Layout.preferredHeight: visible ? Math.min(420, panelCol.width * (implicitHeight / Math.max(1, implicitWidth))) : 0
                            sourceSize.width: 800
                        }

                        ColumnLayout {
                            Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.topMargin: 4; spacing: 6

                            FText { visible: !!root.selMaster && !root.canEdit(root.selMaster); Layout.fillWidth: true; Layout.topMargin: 10; wrapMode: Text.Wrap; color: root.cWarn; font.pixelSize: 12
                                text: "Read-only: you're a " + root.roleOf(root.selCal) + " on this calendar." }
                            Repeater {
                                model: root.selected ? (root.doubles[root.occKey(root.selected)] || []) : []
                                delegate: FText { required property var modelData; Layout.fillWidth: true; Layout.topMargin: 8; wrapMode: Text.Wrap; color: root.cWarn; font.pixelSize: 12; text: root.doubleLine(modelData) }
                            }
                            Repeater {
                                model: root.selected ? (root.venueClashes[root.occKey(root.selected)] || []) : []
                                delegate: FText { required property var modelData; Layout.fillWidth: true; Layout.topMargin: 8; wrapMode: Text.Wrap; color: root.cWarn; font.pixelSize: 12; text: root.clashLine(modelData) }
                            }

                            Sec { label: "Status" }
                            Flow {
                                Layout.fillWidth: true; spacing: 6
                                Repeater { model: root.statuses
                                    delegate: Chip { required property var modelData; text: modelData; accent: root.statusColor(modelData)
                                        on: root.fieldOf(root.selMaster, "status") === modelData; opacity: root.canEdit(root.selMaster) ? 1 : 0.5
                                        onClicked: if (root.canEdit(root.selMaster) && !on) root.setField("status", modelData) } }
                            }
                            Sec { label: "Venue"; action: root.fieldOf(root.selMaster, "venue") ? "map ↗" : ""; onAct: root.openMap(root.fieldOf(root.selMaster, "venue")) }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 6
                                Input { id: venueInput; Layout.fillWidth: true; enabled: root.canEdit(root.selMaster); text: root.fieldOf(root.selMaster, "venue"); placeholderText: "Where it happens"
                                    onAccepted: root.setField("venue", text.trim()) }
                                Btn { text: "Save"; enabled_: root.canEdit(root.selMaster) && venueInput.text.trim() !== root.fieldOf(root.selMaster, "venue"); onClicked: root.setField("venue", venueInput.text.trim()) }
                            }
                            Flow {
                                Layout.fillWidth: true; spacing: 6; visible: root.canEdit(root.selMaster)
                                Repeater { model: root.venues.filter(function (v) { return v.name.toLowerCase() !== root.fieldOf(root.selMaster, "venue").toLowerCase() }).slice(0, 5)
                                    delegate: Chip { required property var modelData; text: modelData.name; onClicked: root.setField("venue", modelData.name) } }
                            }
                            Sec { label: "Type" }
                            Flow {
                                Layout.fillWidth: true; spacing: 6
                                Repeater { model: root.types
                                    delegate: Chip { required property var modelData; text: modelData; accent: root.typeColor(modelData); on: root.fieldOf(root.selMaster, "type") === modelData
                                        opacity: root.canEdit(root.selMaster) ? 1 : 0.5; onClicked: if (root.canEdit(root.selMaster) && !on) root.setField("type", modelData) } }
                            }
                            Sec { label: "Repeats" }
                            Flow {
                                Layout.fillWidth: true; spacing: 6
                                Repeater { model: root.repeatOpts
                                    delegate: Chip { required property var modelData; text: modelData.l; on: root.repeatLabel(root.selMaster) === modelData.l
                                        opacity: root.canEdit(root.selMaster) ? 1 : 0.5; onClicked: if (root.canEdit(root.selMaster) && !on) root.setRepeat(modelData) } }
                            }
                            Sec { label: "Tags" }
                            Flow {
                                Layout.fillWidth: true; spacing: 6
                                Repeater { model: root.tagsOf(root.selMaster)
                                    delegate: Chip { required property var modelData; text: "#" + modelData + "  ✕"; on: true; accent: root.cSignal; onClicked: root.removeTag(modelData) } }
                                Input { id: tagInput; width: 130; placeholderText: "+ tag"; onAccepted: { root.addTag(text); text = "" } }
                            }
                            Flow {
                                Layout.fillWidth: true; spacing: 6
                                Repeater { model: root.suggestedTags.concat(root.allTags).filter(function (t, i, a) { return a.indexOf(t) === i && root.tagsOf(root.selMaster).indexOf(t) < 0 }).slice(0, 6)
                                    delegate: Link { required property var modelData; text: "#" + modelData; tone: root.cFaint; onClicked: root.addTag(modelData) } }
                            }

                            // Line-up: artists from Kith (ADR 0004).
                            Sec { label: "Line-up (" + root.lineupOf(root.selMaster).length + ")"; action: "+ artist"; onAct: root.openArtist(null) }
                            FText { visible: root.lineupOf(root.selMaster).length === 0; text: "No artists yet."; color: root.cSub; font.pixelSize: 12 }
                            Repeater {
                                model: root.lineupOf(root.selMaster)
                                delegate: Rectangle {
                                    id: bk
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true; Layout.preferredHeight: bkCol.implicitHeight + 12
                                    color: bkMA.containsMouse ? root.cSurface : "transparent"; border.width: 1; border.color: root.cLine
                                    MouseArea { id: bkMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openArtist(bk.modelData) }
                                    Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; color: root.bookingColor(bk.modelData.status) }
                                    Column {
                                        id: bkCol
                                        x: 24; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 32; spacing: -2
                                        Row {
                                            spacing: 6
                                            FText { visible: bk.index % 2 === 0; text: "(("; color: root.cBracket; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; font.bold: true }
                                            DText { text: root.kithName(bk.modelData).toUpperCase(); font.pixelSize: 24; color: bk.modelData.status === "cancelled" ? root.cSub : root.cText; font.strikeout: bk.modelData.status === "cancelled" }
                                            FText { visible: bk.index % 2 === 1; text: "))"; color: root.cBracket; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; font.bold: true }
                                        }
                                        FText { width: parent.width; elide: Text.ElideRight; color: root.cSub; font.pixelSize: 12
                                            text: [bk.modelData.set, root.cap(bk.modelData.status), root.feeLabel(bk.modelData), bk.modelData.contact ? "" : "not in Kith"].filter(function (x) { return !!x }).join(" · ") }
                                    }
                                }
                            }
                            FText { visible: root.feesTotal(root.lineupOf(root.selMaster)) !== ""; text: "Fees: " + root.feesTotal(root.lineupOf(root.selMaster)); color: root.cSub; font.pixelSize: 12 }

                            // Tickets: paste the ticket link, track the numbers.
                            Sec { label: "Tickets"; action: root.ticketsOf(root.selMaster) ? "edit" : "+ add"; onAct: root.openTickets() }
                            ColumnLayout {
                                id: tk
                                readonly property var t: root.ticketsOf(root.selMaster)
                                Layout.fillWidth: true; spacing: 5
                                FText { visible: !tk.t; Layout.fillWidth: true; wrapMode: Text.Wrap; text: "No ticket link yet. Paste one from Luma, 3cket, Shotgun… and keep the numbers here."; color: root.cSub; font.pixelSize: 12 }
                                RowLayout {
                                    visible: !!tk.t; Layout.fillWidth: true; spacing: 10
                                    DText { text: tk.t && root.num(tk.t.sold) !== null ? String(tk.t.sold) : "—"; font.pixelSize: 40; color: root.cLime }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        FText { text: root.ticketLine(tk.t); color: root.cText; font.pixelSize: 13 }
                                        Rectangle {
                                            visible: !!tk.t && root.num(tk.t.capacity) > 0
                                            Layout.fillWidth: true; height: 8; color: root.cSurface2
                                            Rectangle { height: parent.height; color: root.cLime
                                                width: { var t = tk.t; return t && root.num(t.capacity) > 0 ? parent.width * Math.min(1, (root.num(t.sold) || 0) / t.capacity) : 0 } }
                                        }
                                    }
                                }
                                Link { visible: !!tk.t && root.str(tk.t.url) !== ""; text: tk.t ? "open ticket page ↗  " + root.str(tk.t.url).replace(/^https?:\/\//, "") : ""; onClicked: Qt.openUrlExternally(root.str(tk.t.url)) }
                            }

                            // Budget: income and costs; artist fees and ticket sales come in by themselves.
                            Sec { label: "Budget"; action: "+ line"; onAct: root.openItem("budget", null) }
                            ColumnLayout {
                                id: mon
                                readonly property var mo: root.moneyOf(root.selMaster)
                                Layout.fillWidth: true; spacing: 0
                                Repeater {
                                    model: root.budgetOf(root.selMaster)
                                    delegate: Rectangle {
                                        id: bl
                                        required property var modelData
                                        Layout.fillWidth: true; Layout.preferredHeight: 30; color: blMA.containsMouse ? root.cSurface : "transparent"
                                        MouseArea { id: blMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openItem("budget", bl.modelData) }
                                        FText { x: 6; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 120; elide: Text.ElideRight; text: root.str(bl.modelData.d.label); color: root.cText; font.pixelSize: 13 }
                                        FText { anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                                            text: (bl.modelData.d.dir === "in" ? "+ " : "− ") + root.money(root.num(bl.modelData.d.amount) || 0, root.str(bl.modelData.d.currency))
                                            color: bl.modelData.d.dir === "in" ? root.cLime : root.cText; font.pixelSize: 13 }
                                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.cLine }
                                    }
                                }
                                Repeater {
                                    model: [{ l: "Artist fees (line-up)", v: mon.mo.fees, dir: "out" }, { l: "Ticket sales", v: mon.mo.tickets, dir: "in" }].filter(function (x) { return x.v > 0 })
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true; Layout.preferredHeight: 30; color: "transparent"
                                        FText { x: 6; anchors.verticalCenter: parent.verticalCenter; text: modelData.l; color: root.cSub; font.pixelSize: 13; font.italic: true }
                                        FText { anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                                            text: (modelData.dir === "in" ? "+ " : "− ") + root.money(modelData.v, mon.mo.cur); color: modelData.dir === "in" ? root.cLime : root.cText; font.pixelSize: 13 }
                                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.cLine }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true; Layout.topMargin: 8; spacing: 6
                                    Repeater {
                                        model: [{ l: "In", v: mon.mo.income }, { l: "Out", v: mon.mo.costs }, { l: "Result", v: mon.mo.profit }]
                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true; Layout.preferredHeight: 52; color: "transparent"; border.width: 1; border.color: modelData.l === "Result" ? (modelData.v >= 0 ? root.cLime : root.cRed) : root.cLine
                                            Column { x: 8; anchors.verticalCenter: parent.verticalCenter; spacing: -3
                                                FText { text: modelData.l.toUpperCase(); color: root.cFaint; font.pixelSize: 11; font.letterSpacing: 1.2 }
                                                DText { text: root.money(modelData.v, mon.mo.cur); font.pixelSize: 22; color: modelData.l === "Result" ? (modelData.v >= 0 ? root.cLime : root.cRed) : root.cText } }
                                        }
                                    }
                                }
                            }

                            // Crew: roles, call times and check-in (ADR 0007).
                            Sec { label: "Crew" + (root.crewSummaryLabel(root.crewSummary(root.crewOf(root.selMaster))) ? " (" + root.crewSummaryLabel(root.crewSummary(root.crewOf(root.selMaster))) + ")" : ""); action: "+ crew"; onAct: root.openCrew(null) }
                            FText { visible: root.crewOf(root.selMaster).length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                                text: "No crew yet. Add people, or a role with no name as an open slot." }
                            Repeater {
                                model: root.crewOf(root.selMaster)
                                delegate: Rectangle {
                                    id: cr
                                    required property var modelData
                                    readonly property bool canToggle: !!modelData.name && modelData.status !== "cancelled" && (!modelData.checkedIn || root.canUndoCheckin(modelData))
                                    Layout.fillWidth: true; Layout.preferredHeight: crCol.implicitHeight + 12
                                    color: crMA.containsMouse ? root.cSurface : "transparent"; border.width: 1; border.color: root.cLine
                                    MouseArea { id: crMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openCrew(cr.modelData) }
                                    Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; color: cr.modelData.name ? root.bookingColor(cr.modelData.status) : root.cFaint }
                                    Column {
                                        id: crCol
                                        x: 24; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 32 - (here.visible ? here.width + 8 : 0); spacing: 1
                                        FText { width: parent.width; elide: Text.ElideRight; font.pixelSize: 13
                                            color: cr.modelData.status === "cancelled" || !cr.modelData.name ? root.cSub : root.cText
                                            font.strikeout: cr.modelData.status === "cancelled"; font.italic: !cr.modelData.name
                                            text: (cr.modelData.role ? cr.modelData.role.toUpperCase() + "  " : "") + (cr.modelData.name ? root.kithName(cr.modelData) : "open slot") }
                                        FText { width: parent.width; elide: Text.ElideRight; color: root.cSub; font.pixelSize: 12; visible: text !== ""
                                            text: [cr.modelData.call ? "call " + cr.modelData.call : "", cr.modelData.name ? root.cap(cr.modelData.status) : "",
                                                   cr.modelData.checkedIn ? "here since " + Qt.formatTime(new Date(cr.modelData.checkedIn.at), "hh:mm") : ""].filter(function (x) { return !!x }).join(" · ") }
                                    }
                                    Chip {
                                        id: here
                                        visible: !!cr.modelData.name && cr.modelData.status !== "cancelled" || !!cr.modelData.checkedIn
                                        anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                        text: cr.modelData.checkedIn ? "HERE ✓" : "I'M HERE"
                                        on: !!cr.modelData.checkedIn; accent: root.cLime
                                        opacity: cr.canToggle && !root.crewBusy ? 1 : 0.6
                                        onClicked: if (cr.canToggle) root.toggleCheckin(cr.modelData)
                                    }
                                }
                            }

                            // Tasks with deadlines and reminders (social posts, payments, contracts…).
                            Sec { label: "Tasks (" + root.openTaskCount(root.selMaster) + " open)"; action: "+ task"; onAct: root.openItem("task", null) }
                            FText { visible: root.tasksOf(root.selMaster).length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                                text: "Book artist, announce, print posters, pay the deposit… Tasks with a deadline turn amber three days before and flag when overdue." }
                            Repeater {
                                model: root.tasksOf(root.selMaster)
                                delegate: CheckRow {
                                    required property var modelData
                                    text: root.str(modelData.d.text); done: modelData.d.done === true
                                    meta: [root.overdue(modelData) ? "OVERDUE" : "", root.num(modelData.d.due) !== null ? "due " + Qt.formatDateTime(new Date(modelData.d.due), "ddd d MMM hh:mm") : "", root.str(modelData.d.cat)].filter(function (x) { return !!x }).join(" · ")
                                    metaTone: root.overdue(modelData) ? root.cRed : root.dueSoon(modelData) ? root.cWarn : root.cSub
                                    onToggled: root.toggleDone(root.selMaster, "task", modelData)
                                    onOpened: root.openItem("task", modelData)
                                }
                            }

                            // Equipment checklist.
                            Sec { label: "Gear (" + root.gearOf(root.selMaster).filter(function (g) { return g.d.done === true }).length + "/" + root.gearOf(root.selMaster).length + " packed)"; action: "+ item"; onAct: root.openItem("gear", null) }
                            Repeater {
                                model: root.gearOf(root.selMaster)
                                delegate: CheckRow { required property var modelData; text: root.str(modelData.d.item); done: modelData.d.done === true
                                    onToggled: root.toggleDone(root.selMaster, "gear", modelData); onOpened: root.openItem("gear", modelData) }
                            }
                            Flow {
                                Layout.fillWidth: true; spacing: 10
                                Repeater { model: root.gearPresets.filter(function (p) { return !root.gearOf(root.selMaster).some(function (g) { return root.str(g.d.item).toLowerCase().indexOf(p.toLowerCase()) >= 0 }) }).slice(0, 6)
                                    delegate: Link { required property var modelData; text: "+ " + modelData; tone: root.cFaint; onClicked: root.saveItem(root.selMaster, "gear", { item: modelData, done: false }, "", "") } }
                            }

                            // Social media planner.
                            Sec { label: "Social posts"; action: "+ post"; onAct: root.openItem("post", null) }
                            FText { visible: root.postsOf(root.selMaster).length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                                text: "Plan what goes out and when: announcement, line-up reveal, day-of stories, recap." }
                            Repeater {
                                model: root.postsOf(root.selMaster)
                                delegate: CheckRow { required property var modelData
                                    text: root.str(modelData.d.text); done: modelData.d.done === true
                                    meta: [root.str(modelData.d.channel), root.num(modelData.d.when) !== null ? Qt.formatDateTime(new Date(modelData.d.when), "ddd d MMM hh:mm") : "unscheduled"].join(" · ")
                                    metaTone: root.dueSoon({ d: { due: modelData.d.when, done: modelData.d.done } }) ? root.cWarn : root.cSub
                                    onToggled: root.toggleDone(root.selMaster, "post", modelData); onOpened: root.openItem("post", modelData) }
                            }

                            // Files: contracts, riders, posters, logos — in Logos Storage, sealed for members.
                            Sec { label: "Files (" + root.filesOf(root.selMaster).length + ")"; action: root.canEdit(root.selMaster) ? "+ upload" : ""; onAct: fileDialog.open() }
                            FText { visible: root.filesOf(root.selMaster).length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                                text: "Contracts, riders, posters, logos. Stored in Logos Storage, sealed with this calendar's key: only its members can open them." }
                            Repeater {
                                model: root.filesOf(root.selMaster)
                                delegate: Rectangle {
                                    id: fl
                                    required property var modelData
                                    readonly property string vis: root.fileVisibility(root.selMaster, root.str(modelData.storageCid))
                                    Layout.fillWidth: true; Layout.preferredHeight: flCol.implicitHeight + 14; color: "transparent"; border.width: 1; border.color: root.cLine
                                    ColumnLayout {
                                        id: flCol
                                        x: 10; y: 7; width: parent.width - 20; spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true
                                            FText { Layout.fillWidth: true; elide: Text.ElideMiddle; text: root.str(fl.modelData.name); color: root.cText; font.pixelSize: 13 }
                                            Chip { text: fl.vis === "public" ? "COMMUNITY" : "MEMBERS ONLY"; on: fl.vis === "public"; accent: root.cSignal
                                                onClicked: root.setFileVisibility(root.str(fl.modelData.storageCid), fl.vis === "public" ? "private" : "public") }
                                        }
                                        FText { text: root.humanSize(fl.modelData.size) + (root.str(fl.modelData.mime) ? " · " + root.str(fl.modelData.mime) : ""); color: root.cFaint; font.pixelSize: 11 }
                                        Row {
                                            spacing: 14
                                            Link { text: "open"; onClicked: root.openFile(fl.modelData) }
                                            Link { visible: root.isImage(fl.modelData); text: "use as poster"; onClicked: root.setPosterFile(fl.modelData) }
                                            Link { visible: root.canEdit(root.selMaster); text: "remove"; tone: root.cRed; onClicked: root.removeFile(fl.modelData) }
                                        }
                                    }
                                }
                            }
                            FText { visible: root.fileMsg !== ""; text: root.fileMsg; color: root.cWarn; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.Wrap }

                            Sec { label: "Poster"; action: root.posterOf(root.selMaster) ? "change" : "+ set"; onAct: root.openPoster() }
                            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                                text: root.posterOf(root.selMaster) ? "Shows on the calendar, the timeline and at the top of this panel." : "Pick an image file attached to the night, or paste an image link. It previews right in the calendar." }

                            // Public: a copy in a public calendar, kept in step (ADR 0008).
                            Sec { label: "Public / private" }
                            Rectangle {
                                id: pubBox
                                readonly property var link: root.publicLinkOf(root.selMaster)
                                readonly property var pcal: link ? root.calById(link.calendar) : null
                                Layout.fillWidth: true; Layout.preferredHeight: pubCol.implicitHeight + 16; color: "transparent"; border.width: 1; border.color: link ? root.cLime : root.cLine
                                ColumnLayout {
                                    id: pubCol
                                    x: 10; width: parent.width - 20; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cText; font.pixelSize: 13
                                        text: !pubBox.link ? "PRIVATE · only this calendar's members see it." : pubBox.pcal ? "PUBLIC in “" + pubBox.pcal.name + "”" : "PUBLIC in a calendar not on this computer" }
                                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                                        text: !pubBox.link ? "Internal planning (fees, crew, budget, tasks, notes, files) always stays private."
                                            : root.putMissing ? "The public copy can't be updated from here: update the ‘scala’ package to 0.12.4 or newer."
                                            : root.mirrorBlocked[root.selMaster ? root.selMaster.id : ""] ? "You can't update the public copy: ask an editor of the public calendar to open Freequencies."
                                            : "Attendees see the time, venue, confirmed artists and the guest-list link. Nothing else." }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 14
                                        Link { visible: !pubBox.link; text: "make public →"; onClicked: pubPopup.open() }
                                        Link { visible: !!pubBox.pcal && root.isEditorOf(pubBox.pcal); text: "copy link for attendees"; onClicked: root.copyInvite(pubBox.pcal.id, "viewer") }
                                        Link { visible: !!pubBox.pcal && root.isEditorOf(pubBox.pcal); text: "invite an organiser"; onClicked: root.copyInvite(pubBox.pcal.id, "editor") }
                                        Link { visible: !!pubBox.link && (!!root.selCal && pubBox.link.author === root.selCal.authorAddr || root.isEditorOf(root.selCal)); text: "make private"; tone: root.cRed; onClicked: root.stopPublic() }
                                    }
                                }
                            }

                            // Forms: WhisperBox forms attached to this night (ADR 0005).
                            Sec { label: "Forms (" + root.formsOf(root.selMaster).length + ")"; action: "+ form"; onAct: formPopup.open() }
                            FText { visible: root.formsOf(root.selMaster).length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                                text: "Artist bookings, crew sign-up, guest list or feedback: private forms, answers sealed for you." }
                            Repeater {
                                model: root.formsOf(root.selMaster)
                                delegate: Rectangle {
                                    id: fm
                                    required property var modelData
                                    readonly property bool mine: !!root.wbSummaries[modelData.formId] && root.wbSummaries[modelData.formId].canRead === true
                                    Layout.fillWidth: true; Layout.preferredHeight: fmCol.implicitHeight + 14; color: "transparent"; border.width: 1; border.color: root.cLine
                                    ColumnLayout {
                                        id: fmCol
                                        x: 10; y: 7; width: parent.width - 20; spacing: 3
                                        FText { Layout.fillWidth: true; elide: Text.ElideRight; color: root.cText; font.pixelSize: 13; text: root.formTitle(fm.modelData) }
                                        FText { Layout.fillWidth: true; elide: Text.ElideRight; color: root.cSub; font.pixelSize: 12; text: root.formLine(fm.modelData) }
                                        Row {
                                            spacing: 14
                                            Link { visible: fm.modelData.uri !== ""; text: "copy link"; onClicked: root.copyText(fm.modelData.uri) }
                                            Link { visible: fm.mine; text: "answers"; onClicked: root.openResponses(fm.modelData) }
                                            Link { visible: (!!root.selCal && fm.modelData.author === root.selCal.authorAddr) || root.isEditorOf(root.selCal); text: "remove"; tone: root.cRed; onClicked: root.detachForm(fm.modelData) }
                                        }
                                    }
                                }
                            }

                            // Notes: the night's description (never part of the public copy).
                            Sec { label: "Notes"; action: notesArea.text !== (root.selMaster ? (root.selMaster.description || "") : "") && root.canEdit(root.selMaster) ? "save" : ""; onAct: root.saveNotes(notesArea.text) }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: Math.max(80, notesArea.implicitHeight + 4); color: root.cBase; border.width: 1; border.color: notesArea.activeFocus ? root.cLime : root.cLine
                                TextArea {
                                    id: notesArea
                                    anchors.fill: parent; wrapMode: TextEdit.Wrap; readOnly: !root.canEdit(root.selMaster)
                                    text: root.selMaster ? (root.selMaster.description || "") : ""
                                    color: root.cText; font.family: root.fBody; font.pixelSize: 13; placeholderText: "Private notes for the team: load-in, contacts, what to remember…"
                                    placeholderTextColor: root.cFaint; selectionColor: root.cLime; selectedTextColor: root.cCrust
                                    background: Item {}
                                }
                            }

                            Sec { label: "Attendance" }
                            FText { text: root.rsvpSummary(root.selMaster) + (root.ticketsOf(root.selMaster) && root.num(root.ticketsOf(root.selMaster).sold) !== null ? "  ·  " + root.ticketsOf(root.selMaster).sold + " tickets" : ""); color: root.cSub; font.pixelSize: 12 }

                            // Comments: Scala's ext items, so the same thread shows in Scala.
                            Sec { label: "Comments (" + root.commentsOf(root.selMaster).length + ")" }
                            Repeater {
                                model: root.commentsOf(root.selMaster)
                                delegate: ColumnLayout {
                                    id: cm
                                    required property var modelData
                                    readonly property bool mine: !!root.selCal && modelData.author === root.selCal.authorAddr
                                    Layout.fillWidth: true; spacing: 2
                                    RowLayout {
                                        Layout.fillWidth: true
                                        FText { Layout.fillWidth: true; elide: Text.ElideRight; color: root.cLime; font.pixelSize: 11
                                            text: (cm.mine ? "you" : String(cm.modelData.author).substring(0, 8) + "…") + " · " + Qt.formatDateTime(new Date(cm.modelData.hlc.wall), "d MMM hh:mm") }
                                        Link { visible: cm.mine || root.isEditorOf(root.selCal); text: "delete"; tone: root.cRed; font.pixelSize: 11; onClicked: root.deleteComment(cm.modelData.id) }
                                    }
                                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cText; font.pixelSize: 13
                                        text: (cm.modelData.data && typeof cm.modelData.data.text === "string") ? cm.modelData.data.text : "(empty)" }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 6
                                Input { id: commentInput; Layout.fillWidth: true; placeholderText: "Add a comment…"; onAccepted: root.postComment(text) }
                                Btn { text: root.commentBusy ? "…" : "Post"; enabled_: commentInput.text.trim() !== "" && !root.commentBusy; onClicked: root.postComment(commentInput.text) }
                            }

                            Rectangle { Layout.fillWidth: true; Layout.topMargin: 18; height: 1; color: root.cLine }
                            RowLayout {
                                Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
                                Btn { text: root.creating ? "Copying…" : "Duplicate night"; enabled_: !root.creating && root.canEdit(root.selMaster); onClicked: root.duplicateNight() }
                                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cFaint; font.pixelSize: 11
                                    text: "One week later, as a Hold: line-up asked again, crew roles open, gear unpacked." }
                            }
                        }
                    }
                }
            }
        }
    }

    // The ghost that follows the pointer while a night is dragged.
    Rectangle {
        id: ghost
        visible: root.dragOcc !== null
        z: 9999; width: ghostT.implicitWidth + 24; height: 30
        color: root.cLime
        Drag.active: root.dragOcc !== null
        Drag.keys: ["night"]
        Drag.hotSpot.x: 12; Drag.hotSpot.y: 12
        FText { id: ghostT; anchors.centerIn: parent; text: root.dragOcc ? "(( " + (root.dragOcc.title || "night") + " ))" : ""; color: root.cCrust; font.pixelSize: 12; font.bold: true }
    }

    FileDialog {
        id: fileDialog
        title: "Attach a file to this night"
        onAccepted: root.onFilePicked(fileDialog.selectedFile)
    }


    // ── new night ────────────────────────────────────────────────────────────────
    property string newCalId: ""
    property string newStatus: "Hold"
    property string newType: "Club night"
    property int newRepeat: 0                 // index into repeatOpts
    function pad(n) { return (n < 10 ? "0" : "") + n }
    function openNew(day, venue) {
        if (freqCals.length === 0) return
        var d = day ? new Date(day) : (view === "month" ? new Date(Math.max(today0(), new Date(monthAnchor).getTime())) : view === "week" ? new Date(weekStart) : new Date(firstDay))
        newCalId = newCalId && calById(newCalId) && isFreqCal(calById(newCalId)) ? newCalId : freqCals[0].id
        newStatus = "Hold"; newType = "Club night"; newRepeat = 0
        nTitle.text = ""; nVenue.text = venue && venue !== "—" ? venue : ""
        nDate.text = d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
        nStart.text = "22:00"; nEnd.text = "04:00"; nUntil.text = ""
        newPopup.open()
        nTitle.forceActiveFocus()
    }
    function parseLocal(dateStr, timeStr) {
        var dm = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(dateStr).trim()), tm = /^(\d{1,2}):(\d{2})$/.exec(String(timeStr).trim())
        if (!dm || !tm) return null
        return new Date(+dm[1], +dm[2] - 1, +dm[3], +tm[1], +tm[2], 0, 0)
    }
    property bool creating: false
    function createNight() {
        if (creating) return
        var title = nTitle.text.trim()
        var s = parseLocal(nDate.text, nStart.text), e = parseLocal(nDate.text, nEnd.text)
        if (!title) { notify("Give the night a name.", true); return }
        if (!s || !e) { notify("Use a date like 2026-10-24 and times like 22:00.", true); return }
        if (e.getTime() <= s.getTime()) e = new Date(e.getTime() + 864e5)   // ends after midnight
        var ev = { title: title, startTime: s.getTime(), endTime: e.getTime(), reminderMin: 60,
                   fields: { status: newStatus, venue: nVenue.text.trim(), type: newType } }
        var rp = repeatOpts[newRepeat]
        if (rp && rp.f) {
            ev.recur = { freq: rp.f, interval: rp.i }
            if (nUntil.text.trim()) {
                var u = parseLocal(nUntil.text, "23:59")
                if (!u) { notify("Repeat until: use a date like 2026-12-31.", true); return }
                ev.recur.until = u.getTime()
            }
        }
        creating = true
        core("createEvent", [newCalId, JSON.stringify(ev)], function (r) {
            creating = false
            var id = String(j(r, "") || "")
            if (id) { newPopup.close(); notify("Added “" + title + "”"); refresh() }
            else notify("Couldn't add the night. You may not be allowed to add events to this calendar.", true)
        })
    }
    component Label_: FText { color: root.cFaint; font.pixelSize: 12; font.letterSpacing: 1.2 }
    component WinTitle: Rectangle {
        id: wt
        property string title: ""
        signal close()
        Layout.fillWidth: true; Layout.preferredHeight: 30; Layout.topMargin: -20; Layout.leftMargin: -20; Layout.rightMargin: -20; Layout.bottomMargin: 6
        color: root.cLime
        FText { x: 10; anchors.verticalCenter: parent.verticalCenter; text: wt.title.toUpperCase(); color: root.cCrust; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.4 }
        FText { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: "✕"; color: root.cCrust; font.pixelSize: 13
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: wt.close() } }
    }
    Popup {
        id: newPopup
        anchors.centerIn: Overlay.overlay
        width: 460; modal: true; padding: 20
        background: Rectangle { color: root.cBase; border.width: 2; border.color: root.cLime }
        ColumnLayout {
            anchors.fill: parent; spacing: 7
            WinTitle { title: "new_night.exe"; onClose: newPopup.close() }
            Label_ { text: "CALENDAR" }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater { model: root.freqCals
                    delegate: Chip { required property var modelData; text: modelData.name || "(unnamed)"; on: root.newCalId === modelData.id; onClicked: root.newCalId = modelData.id } }
            }
            Label_ { text: "NAME" }
            Input { id: nTitle; Layout.fillWidth: true; placeholderText: "e.g. Freequencies 03" }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout { Layout.fillWidth: true; spacing: 4
                    Label_ { text: "DATE" }
                    Input { id: nDate; Layout.fillWidth: true } }
                ColumnLayout { spacing: 4
                    Label_ { text: "DOORS" }
                    Input { id: nStart; Layout.preferredWidth: 80 } }
                ColumnLayout { spacing: 4
                    Label_ { text: "ENDS" }
                    Input { id: nEnd; Layout.preferredWidth: 80 } }
            }
            Label_ { text: "VENUE" }
            Input { id: nVenue; Layout.fillWidth: true; placeholderText: "Where it happens" }
            Flow {
                Layout.fillWidth: true; spacing: 6; visible: root.venues.length > 0
                Repeater { model: root.venues.slice(0, 8)
                    delegate: Chip { required property var modelData; text: modelData.name; on: nVenue.text.trim().toLowerCase() === modelData.name.toLowerCase(); onClicked: nVenue.text = modelData.name } }
            }
            Label_ { text: "TYPE" }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater { model: root.types
                    delegate: Chip { required property var modelData; text: modelData; accent: root.typeColor(modelData); on: root.newType === modelData; onClicked: root.newType = modelData } }
            }
            Label_ { text: "STATUS" }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater { model: root.statuses
                    delegate: Chip { required property var modelData; text: modelData; accent: root.statusColor(modelData); on: root.newStatus === modelData; onClicked: root.newStatus = modelData } }
            }
            Label_ { text: "REPEATS (RESIDENCIES, MONTHLY NIGHTS)" }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater { model: root.repeatOpts
                    delegate: Chip { required property var modelData; required property int index; text: modelData.l; on: root.newRepeat === index; onClicked: root.newRepeat = index } }
            }
            RowLayout {
                visible: root.newRepeat > 0; Layout.fillWidth: true; spacing: 8
                Label_ { text: "UNTIL" }
                Input { id: nUntil; Layout.fillWidth: true; placeholderText: "2026-12-31 (optional)" }
            }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
                Item { Layout.fillWidth: true }
                Btn { text: "Cancel"; onClicked: newPopup.close() }
                Btn { text: root.creating ? "Adding…" : "Add night"; primary: true; enabled_: !root.creating; onClicked: root.createNight() }
            }
        }
    }

    // ── tickets ──────────────────────────────────────────────────────────────────
    function openTickets() {
        if (!selMaster) return
        var t = ticketsOf(selMaster) || {}
        tUrl.text = str(t.url); tSold.text = num(t.sold) !== null ? String(t.sold) : ""; tCap.text = num(t.capacity) !== null ? String(t.capacity) : ""
        tPrice.text = num(t.price) !== null ? String(t.price) : ""; tCur.text = str(t.currency) || "EUR"
        ticketPopup.open()
    }
    function saveTickets() {
        function n(s) { s = String(s).trim().replace(",", "."); if (s === "") return null; var v = Number(s); return isFinite(v) && v >= 0 ? v : NaN }
        var d = {}, sold = n(tSold.text), cap = n(tCap.text), price = n(tPrice.text)
        if (isNaN(sold) || isNaN(cap) || isNaN(price)) { notify("Sold, capacity and price should be numbers.", true); return }
        if (tUrl.text.trim()) d.url = tUrl.text.trim()
        if (sold !== null) d.sold = sold
        if (cap !== null) d.capacity = cap
        if (price !== null) { d.price = price; d.currency = tCur.text.trim().toUpperCase() || "EUR" }
        putLatest(selMaster, "tickets", d, "Tickets updated")
        ticketPopup.close()
    }
    Popup {
        id: ticketPopup
        anchors.centerIn: Overlay.overlay
        width: 440; modal: true; padding: 20
        background: Rectangle { color: root.cBase; border.width: 2; border.color: root.cLime }
        ColumnLayout {
            anchors.fill: parent; spacing: 7
            WinTitle { title: "tickets.exe"; onClose: ticketPopup.close() }
            Label_ { text: "TICKET PAGE LINK" }
            Input { id: tUrl; Layout.fillWidth: true; placeholderText: "https://lu.ma/… or 3cket, Shotgun, RA" }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: "SOLD" } Input { id: tSold; Layout.fillWidth: true; placeholderText: "0" } }
                ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: "CAPACITY" } Input { id: tCap; Layout.fillWidth: true; placeholderText: "180" } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: "PRICE (0 = FREE ENTRY)" } Input { id: tPrice; Layout.fillWidth: true; placeholderText: "10" } }
                ColumnLayout { spacing: 4; Label_ { text: "CURRENCY" } Input { id: tCur; Layout.preferredWidth: 90 } }
            }
            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cFaint; font.pixelSize: 11
                text: "Numbers are typed in for now. Sales count towards attendance and revenue in Analytics and the night's budget." }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
                Item { Layout.fillWidth: true }
                Btn { text: "Cancel"; onClicked: ticketPopup.close() }
                Btn { text: "Save"; primary: true; enabled_: !root.extBusy; onClicked: root.saveTickets() }
            }
        }
    }

    // ── poster ───────────────────────────────────────────────────────────────────
    function openPoster() { if (!selMaster) return; var p = posterOf(selMaster) || {}; pUrl.text = str(p.url); posterPopup.open() }
    Popup {
        id: posterPopup
        anchors.centerIn: Overlay.overlay
        width: 460; modal: true; padding: 20
        background: Rectangle { color: root.cBase; border.width: 2; border.color: root.cLime }
        ColumnLayout {
            anchors.fill: parent; spacing: 7
            WinTitle { title: "poster.exe"; onClose: posterPopup.close() }
            Label_ { text: "FROM THE NIGHT'S FILES" }
            FText { visible: root.filesOf(root.selMaster).filter(root.isImage).length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                text: "No image files on this night yet. Upload the poster under Files, or paste a link below." }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater { model: root.filesOf(root.selMaster).filter(root.isImage)
                    delegate: Chip { required property var modelData; text: root.str(modelData.name); on: (root.posterOf(root.selMaster) || {}).cid === modelData.storageCid
                        onClicked: { root.setPosterFile(modelData); posterPopup.close() } } }
            }
            Label_ { text: "OR AN IMAGE LINK"; Layout.topMargin: 6 }
            Input { id: pUrl; Layout.fillWidth: true; placeholderText: "https://…/poster.png" }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
                Btn { visible: !!root.posterOf(root.selMaster); text: "Remove"; onClicked: { root.setPosterUrl(""); posterPopup.close() } }
                Item { Layout.fillWidth: true }
                Btn { text: "Cancel"; onClicked: posterPopup.close() }
                Btn { text: "Use link"; primary: true; enabled_: pUrl.text.trim() !== ""; onClicked: { root.setPosterUrl(pUrl.text); posterPopup.close() } }
            }
        }
    }

    // ── task / gear / budget line / social post ──────────────────────────────────
    Popup {
        id: itemPopup
        anchors.centerIn: Overlay.overlay
        width: 460; modal: true; padding: 20
        background: Rectangle { color: root.cBase; border.width: 2; border.color: root.cLime }
        ColumnLayout {
            anchors.fill: parent; spacing: 7
            WinTitle { title: (root.itId ? "edit " : "new ") + (root.kindLabel[root.itKind] || "item"); onClose: itemPopup.close() }
            Label_ { text: root.itKind === "budget" ? "WHAT" : root.itKind === "gear" ? "ITEM" : root.itKind === "post" ? "POST" : "TASK" }
            Input { id: itText; Layout.fillWidth: true; onAccepted: root.saveItemFromPopup()
                placeholderText: root.itKind === "budget" ? "e.g. Venue hire" : root.itKind === "gear" ? "e.g. CDJ-3000 ×2" : root.itKind === "post" ? "e.g. Line-up reveal carousel" : "e.g. Send contract to Oseias" }
            ColumnLayout {
                visible: root.itKind === "budget"; Layout.fillWidth: true; spacing: 7
                Flow { Layout.fillWidth: true; spacing: 6
                    Chip { text: "Cost (out)"; on: root.itDir === "out"; onClicked: root.itDir = "out" }
                    Chip { text: "Income (in)"; on: root.itDir === "in"; onClicked: root.itDir = "in" } }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: "AMOUNT" } Input { id: itAmount; Layout.fillWidth: true; placeholderText: "250" } }
                    ColumnLayout { spacing: 4; Label_ { text: "CURRENCY" } Input { id: itCur; Layout.preferredWidth: 90 } }
                }
            }
            ColumnLayout {
                visible: root.itKind === "task" || root.itKind === "post"; Layout.fillWidth: true; spacing: 7
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: root.itKind === "post" ? "GOES OUT ON" : "DEADLINE" } Input { id: itDate; Layout.fillWidth: true; placeholderText: "2026-11-24" } }
                    ColumnLayout { spacing: 4; Label_ { text: "AT" } Input { id: itTime; Layout.preferredWidth: 90 } }
                }
                Label_ { text: root.itKind === "post" ? "CHANNEL" : "KIND" }
                Flow { Layout.fillWidth: true; spacing: 6
                    Repeater { model: root.itKind === "post" ? root.postChannels : root.taskCats
                        delegate: Chip { required property var modelData; text: modelData
                            on: root.itKind === "post" ? root.itChannel === modelData : root.itCat === modelData
                            onClicked: { if (root.itKind === "post") root.itChannel = modelData; else root.itCat = modelData } } } }
            }
            Flow { visible: root.itKind !== "budget"; Layout.fillWidth: true; spacing: 6
                Chip { text: root.itKind === "gear" ? "Packed" : root.itKind === "post" ? "Posted" : "Done"; on: root.itDone; onClicked: root.itDone = !root.itDone } }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
                Btn { visible: root.itId !== ""; text: "Remove"; onClicked: { root.removeItem(root.selMaster, root.itId, "Removed"); itemPopup.close() } }
                Item { Layout.fillWidth: true }
                Btn { text: "Cancel"; onClicked: itemPopup.close() }
                Btn { text: root.itId ? "Save" : "Add"; primary: true; enabled_: !root.extBusy; onClicked: root.saveItemFromPopup() }
            }
        }
    }


    // ── artist booking ───────────────────────────────────────────────────────────
    Popup {
        id: artistPopup
        anchors.centerIn: Overlay.overlay
        width: 440; modal: true; padding: 20
        background: Rectangle { color: root.cBase; border.width: 2; border.color: root.cLime }
        ColumnLayout {
            anchors.fill: parent; spacing: 8
            FText { Layout.fillWidth: true; elide: Text.ElideRight; color: root.cText; font.pixelSize: 18; font.weight: Theme.typography.weightMedium
                text: root.aId ? root.kithName({ contact: root.aContact, name: aName.text }) : "Add an artist" }
            FText { visible: !root.aMine; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cFaint; font.pixelSize: 12
                text: "Only the person who added this booking can change it. Editors can remove it." }
            FText { visible: !root.aId; text: "From Kith"; color: root.cFaint; font.pixelSize: 11 }
            FText { visible: !root.aId && root.kithState !== "ok"; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                text: root.kithState === "loading" ? "Reading Kith…"
                    : root.kithState === "missing" ? "Kith isn't installed or isn't answering. Install the ‘kith’ package to pick artists from your crew's address book, or type a name below."
                    : "No Kith books yet. Join your crew's artist book in Kith, or type a name below." }
            Input { id: aSearch; visible: !root.aId && root.kithState === "ok"; Layout.fillWidth: true; placeholderText: "Search artists"; color: root.cText; font.pixelSize: 13; onTextChanged: root.aQuery = text }
            Flow {
                visible: !root.aId && root.kithState === "ok"; Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: root.aMatches
                    delegate: Chip { required property var modelData; text: modelData.name; on: root.aContact === modelData.id
                        onClicked: { root.aContact = modelData.id; root.aBook = modelData.bookId; aName.text = modelData.name } }
                }
            }
            FText { text: "Name" + (root.aContact ? "  ·  linked to Kith" : ""); color: root.cFaint; font.pixelSize: 11 }
            Input { id: aName; Layout.fillWidth: true; enabled: root.aMine; placeholderText: "Artist name"; color: root.cText; font.pixelSize: 13
                // Typing a different name unlinks the Kith contact.
                onTextEdited: { root.aContact = ""; root.aBook = "" } }
            FText { text: "Set"; color: root.cFaint; font.pixelSize: 11 }
            Input { id: aSet; Layout.fillWidth: true; enabled: root.aMine; placeholderText: "e.g. 23:00–01:00"; color: root.cText; font.pixelSize: 13 }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout { Layout.fillWidth: true; spacing: 4
                    FText { text: "Fee"; color: root.cFaint; font.pixelSize: 11 }
                    Input { id: aFee; Layout.fillWidth: true; enabled: root.aMine; placeholderText: "—"; color: root.cText; font.pixelSize: 13 } }
                ColumnLayout { spacing: 4
                    FText { text: "Currency"; color: root.cFaint; font.pixelSize: 11 }
                    Input { id: aCur; Layout.preferredWidth: 80; enabled: root.aMine; maximumLength: 4; color: root.cText; font.pixelSize: 13 } }
            }
            FText { text: "Everyone in this calendar can see fees."; color: root.cSub; font.pixelSize: 11 }
            FText { text: "Status"; color: root.cFaint; font.pixelSize: 11 }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: root.bookingStatuses
                    delegate: Chip { required property var modelData; text: root.cap(modelData); accent: root.bookingColor(modelData); on: root.aStatus === modelData
                        opacity: root.aMine ? 1 : 0.5; onClicked: if (root.aMine) root.aStatus = modelData }
                }
            }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
                Btn { visible: root.aCanRemove; text: "Remove"; enabled_: !root.artistBusy; onClicked: root.removeArtist() }
                Item { Layout.fillWidth: true }
                Btn { text: root.aMine ? "Cancel" : "Close"; onClicked: artistPopup.close() }
                Btn { visible: root.aMine; text: root.artistBusy ? "Saving…" : (root.aId ? "Save" : "Add"); primary: true; enabled_: !root.artistBusy; onClicked: root.saveArtist() }
            }
        }
    }

    // ── make public ──────────────────────────────────────────────────────────────
    Popup {
        id: pubPopup
        anchors.centerIn: Overlay.overlay
        width: 440; modal: true; padding: 20
        background: Rectangle { color: root.cBase; border.width: 2; border.color: root.cLime }
        ColumnLayout {
            anchors.fill: parent; spacing: 8
            FText { text: "Make this night public"; color: root.cText; font.pixelSize: 18; font.weight: Theme.typography.weightMedium }
            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                text: "Freequencies keeps a copy of this night in a public calendar and updates it whenever the night changes. The copy has the time, venue, confirmed artists and the guest-list link; never fees, crew, holds, notes or comments." }
            FText { text: "Publish to"; color: root.cFaint; font.pixelSize: 11 }
            Repeater {
                model: root.publicTargets
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 36; color: root.cBase
                    Rectangle { x: 10; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; color: modelData.color || root.cBlue }
                    FText { x: 26; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText; text: modelData.name; color: root.cText; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.makePublic(modelData.id) }
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 36; color: root.cBase
                FText { x: 10; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText; text: root.pubBusy ? "Creating…" : "+ New public calendar"; color: root.cBlue; font.pixelSize: 13 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.newPublicCalendar() }
            }
            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cFaint; font.pixelSize: 11
                text: "Only Closed calendars you own or edit are listed: anyone can read a public calendar, only organisers change it. Copy its link for attendees from the night once it's public." }
            RowLayout { Layout.fillWidth: true; Item { Layout.fillWidth: true } Btn { text: "Cancel"; onClicked: pubPopup.close() } }
        }
    }

    // ── crew slot ────────────────────────────────────────────────────────────────
    Popup {
        id: crewPopup
        anchors.centerIn: Overlay.overlay
        width: 440; modal: true; padding: 20
        background: Rectangle { color: root.cBase; border.width: 2; border.color: root.cLime }
        ColumnLayout {
            anchors.fill: parent; spacing: 8
            FText { Layout.fillWidth: true; elide: Text.ElideRight; color: root.cText; font.pixelSize: 18; font.weight: Theme.typography.weightMedium
                text: !root.cId ? "Add to the crew" : cName.text ? root.kithName({ contact: root.cContact, name: cName.text }) : "Open: " + cRole.text }
            FText { visible: !root.cMine; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cFaint; font.pixelSize: 12
                text: "Only the person who added this can change it. Editors can remove it." }
            FText { text: "Role"; color: root.cFaint; font.pixelSize: 11 }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: root.crewRoles
                    delegate: Chip { required property var modelData; text: modelData; on: cRole.text === modelData
                        opacity: root.cMine ? 1 : 0.5; onClicked: if (root.cMine) cRole.text = modelData }
                }
            }
            Input { id: cRole; Layout.fillWidth: true; enabled: root.cMine; placeholderText: "Or type a role"; color: root.cText; font.pixelSize: 13 }
            FText { visible: root.cMine && root.kithState === "ok"; text: "From Kith"; color: root.cFaint; font.pixelSize: 11 }
            Input { id: cSearch; visible: root.cMine && root.kithState === "ok"; Layout.fillWidth: true; placeholderText: "Search contacts"; color: root.cText; font.pixelSize: 13; onTextChanged: root.cQuery = text }
            Flow {
                visible: root.cMine && root.kithState === "ok"; Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: root.cMatches
                    delegate: Chip { required property var modelData; text: modelData.name; on: root.cContact === modelData.id
                        onClicked: { root.cContact = modelData.id; root.cBook = modelData.bookId; cName.text = modelData.name } }
                }
            }
            FText { text: "Name" + (root.cContact ? "  ·  linked to Kith" : ""); color: root.cFaint; font.pixelSize: 11 }
            Input { id: cName; Layout.fillWidth: true; enabled: root.cMine; placeholderText: "Leave empty for an open slot"; color: root.cText; font.pixelSize: 13
                onTextEdited: { root.cContact = ""; root.cBook = "" } }
            FText { text: "Call time"; color: root.cFaint; font.pixelSize: 11 }
            Input { id: cCall; Layout.fillWidth: true; enabled: root.cMine; placeholderText: "e.g. 21:30"; color: root.cText; font.pixelSize: 13 }
            FText { visible: cName.text.trim() !== ""; text: "Status"; color: root.cFaint; font.pixelSize: 11 }
            Flow {
                visible: cName.text.trim() !== ""; Layout.fillWidth: true; spacing: 6
                Repeater {
                    model: root.bookingStatuses
                    delegate: Chip { required property var modelData; text: root.cap(modelData); accent: root.bookingColor(modelData); on: root.cStatus === modelData
                        opacity: root.cMine ? 1 : 0.5; onClicked: if (root.cMine) root.cStatus = modelData }
                }
            }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
                Btn { visible: root.cCanRemove; text: "Remove"; enabled_: !root.crewBusy; onClicked: root.removeCrew() }
                Item { Layout.fillWidth: true }
                Btn { text: root.cMine ? "Cancel" : "Close"; onClicked: crewPopup.close() }
                Btn { visible: root.cMine; text: root.crewBusy ? "Saving…" : (root.cId ? "Save" : "Add"); primary: true; enabled_: !root.crewBusy; onClicked: root.saveCrew() }
            }
        }
    }

    // ── add a form ───────────────────────────────────────────────────────────────
    Popup {
        id: formPopup
        anchors.centerIn: Overlay.overlay
        width: 440; modal: true; padding: 20
        background: Rectangle { color: root.cBase; border.width: 2; border.color: root.cLime }
        ColumnLayout {
            anchors.fill: parent; spacing: 8
            FText { text: "Add a form"; color: root.cText; font.pixelSize: 18; font.weight: Theme.typography.weightMedium }
            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cSub; font.pixelSize: 12
                text: "A WhisperBox form for " + (root.selMaster ? (root.selMaster.title || "this night") : "this night") + ". Share its link; people answer in the WhisperBox app, and only you can read the answers." }
            Repeater {
                model: root.formPurposes
                delegate: Rectangle {
                    id: pr
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 44;
                    color: prMa.containsMouse ? root.cSurface2 : root.cMantle; border.width: 1; border.color: root.cSurface2
                    opacity: root.formBusy ? 0.5 : 1
                    FText { anchors.verticalCenter: parent.verticalCenter; x: 14; text: pr.modelData.label; color: root.cText; font.pixelSize: 14 }
                    MouseArea { id: prMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !root.formBusy; onClicked: root.addForm(pr.modelData.id) }
                }
            }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 8
                FText { visible: root.formBusy; text: "Creating…"; color: root.cSub; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Btn { text: "Cancel"; onClicked: formPopup.close() }
            }
        }
    }

    // ── form answers ─────────────────────────────────────────────────────────────
    Popup {
        id: respPopup
        anchors.centerIn: Overlay.overlay
        width: 520; height: Math.min(root.height - 80, 560); modal: true; padding: 20
        background: Rectangle { color: root.cBase; border.width: 2; border.color: root.cLime }
        ColumnLayout {
            anchors.fill: parent; spacing: 8
            FText { Layout.fillWidth: true; elide: Text.ElideRight; text: root.respTitle; color: root.cText; font.pixelSize: 18; font.weight: Theme.typography.weightMedium }
            FText { visible: root.respRows.length === 0; text: "Reading the answers…"; color: root.cSub; font.pixelSize: 12 }
            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                contentHeight: respCol.implicitHeight
                ColumnLayout {
                    id: respCol
                    width: parent.width; spacing: 10
                    Repeater {
                        model: root.respRows
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true; spacing: 2
                            FText { text: parent.modelData.head; color: root.cFaint; font.pixelSize: 11 }
                            Repeater {
                                model: parent.modelData.lines
                                delegate: FText { required property var modelData; textFormat: Text.PlainText; Layout.fillWidth: true; wrapMode: Text.Wrap; color: root.cText; font.pixelSize: 13; text: modelData }
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Btn { text: "Close"; onClicked: respPopup.close() }
            }
        }
    }

    // ── toast ────────────────────────────────────────────────────────────────────
    Rectangle {
        visible: root.toastMsg !== ""
        z: 10000
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 22
        width: Math.min(parent.width - 40, toastT.implicitWidth + 36); height: toastT.implicitHeight + 20
        color: root.cBase; border.width: 2; border.color: root.toastErr ? root.cRed : root.cLime
        FText { id: toastT; anchors.centerIn: parent; width: Math.min(implicitWidth, root.width - 76); wrapMode: Text.Wrap
            text: (root.toastErr ? "!_ " : ">_ ") + root.toastMsg; color: root.toastErr ? root.cRed : root.cLime; font.pixelSize: 13 }
    }
}
