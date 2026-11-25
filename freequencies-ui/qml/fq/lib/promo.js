.pragma library
// Promo studio: posts and stories made from a night's own data. Each template is one stage of a
// campaign (announce, line-up, artist cards, timetable, countdown, tickets, thank you); "plan the
// campaign" puts them in the night's social planner with dates. Words on the images in PT or EN.
// Pure functions, no Qt: the canvas (fq/views/PromoCanvas.qml) draws what fill() returns.
.import "ext.js" as Ext

var DAY = 86400000
var SIZES = {
    feed:   { w: 1080, h: 1350, label: "Feed 4:5" },
    square: { w: 1080, h: 1080, label: "Square" },
    story:  { w: 1080, h: 1920, label: "Story" }
}
var SIZE_ORDER = ["feed", "square", "story"]

var TEMPLATES = {
    announce:  { label: "Announce", blurb: "Save the date: name, date, venue", t: 28 },
    lineup:    { label: "Line-up", blurb: "Every artist on the bill", t: 14 },
    artist:    { label: "Artist card", blurb: "One post per artist", t: 10 },
    timetable: { label: "Timetable", blurb: "Set times, for the day before", t: 1 },
    countdown: { label: "Countdown", blurb: "Tonight / tomorrow / this Saturday", t: 0 },
    tickets:   { label: "Tickets", blurb: "On sale, last tickets, sold out", t: 7 },
    thanks:    { label: "Thank you", blurb: "The recap the day after", t: -1 }
}
var TEMPLATE_ORDER = ["announce", "lineup", "artist", "timetable", "countdown", "tickets", "thanks"]
var TICKET_STATES = ["onsale", "last", "soldout", "free"]

var WORDS = {
    en: { tonight: "TONIGHT", tomorrow: "TOMORROW", this_: "THIS ", inDays: "IN %d DAYS", lineup: "LINE-UP", timetable: "TIMETABLE",
          onsale: "TICKETS ON SALE", last: "LAST TICKETS", soldout: "SOLD OUT", free: "FREE ENTRY", thanks: "THANK YOU", with_: "WITH",
          days: ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"],
          months: ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"] },
    pt: { tonight: "HOJE", tomorrow: "AMANHÃ", this_: "ESTE ", inDays: "DAQUI A %d DIAS", lineup: "CARTAZ", timetable: "HORÁRIOS",
          onsale: "BILHETES À VENDA", last: "ÚLTIMOS BILHETES", soldout: "ESGOTADO", free: "ENTRADA LIVRE", thanks: "OBRIGADA", with_: "COM",
          days: ["DOMINGO", "SEGUNDA", "TERÇA", "QUARTA", "QUINTA", "SEXTA", "SÁBADO"],
          months: ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"] }
}
function W(lang) { return WORDS[lang] || WORDS.en }
function pad(n) { return (n < 10 ? "0" : "") + n }
function hm(ms) { var d = new Date(ms); return pad(d.getHours()) + ":" + pad(d.getMinutes()) }
// "SAT 28 NOV · 23:00–05:00"
function whenLine(start, end, lang) {
    if (typeof start !== "number") return ""
    var w = W(lang), d = new Date(start)
    var s = w.days[d.getDay()].slice(0, 3) + " " + d.getDate() + " " + w.months[d.getMonth()] + " · " + hm(start)
    return typeof end === "number" && end > start ? s + "–" + hm(end) : s
}
// "TONIGHT" on show day, "TOMORROW", "THIS SATURDAY" within a week, "IN 12 DAYS" further; "" once past.
function countdown(start, now, lang) {
    var w = W(lang)
    var a = new Date(now), b = new Date(start)
    var days = Math.round((new Date(b.getFullYear(), b.getMonth(), b.getDate()) - new Date(a.getFullYear(), a.getMonth(), a.getDate())) / DAY)
    if (days < 0) return ""
    if (days === 0) return w.tonight
    if (days === 1) return w.tomorrow
    if (days < 7) return w.this_ + w.days[b.getDay()]
    return w.inDays.replace("%d", days)
}
function up(s) { return Ext.str(s).toUpperCase() }

// What the canvas draws. f: { title, venue, start, end, lineup: [{name, set}], artist, extra, ticket, price, lang, now }
// Returns { kicker, big, lines: [..], rows: [[time, name]], foot }
function fill(tpl, f) {
    f = f || {}
    var w = W(f.lang), title = up(f.title) || (f.lang === "pt" ? "NOME DO EVENTO" : "NAME OF THE EVENT")
    var when = whenLine(f.start, f.end, f.lang), venue = up(f.venue)
    var foot = [when, venue].filter(function (x) { return !!x }).join("\n")
    var names = (f.lineup || []).map(function (b) { return up(b.name) }).filter(function (x) { return !!x })
    var extra = Ext.str(f.extra).trim()
    if (tpl === "artist") return { kicker: title, big: up(f.artist) || "ARTIST NAME", lines: extra ? [extra] : [], rows: [], foot: foot }
    if (tpl === "lineup") return { kicker: w.lineup, big: title, lines: names.length ? names : ["ARTIST ONE", "ARTIST TWO"], rows: [], foot: foot }
    if (tpl === "timetable") {
        var rows = (f.lineup || []).filter(function (b) { return Ext.str(b.name) }).map(function (b) {
            var m = /(\d{1,2})[:.h](\d{2})/.exec(Ext.str(b.set)); return [m ? pad(Number(m[1])) + ":" + m[2] : "", up(b.name)] })
        rows.sort(function (a, b) { return setKey(a[0]) - setKey(b[0]) })
        return { kicker: w.timetable, big: title, lines: [], rows: rows.length ? rows : [["23:00", "ARTIST ONE"], ["01:00", "ARTIST TWO"]], foot: foot }
    }
    if (tpl === "countdown") return { kicker: title, big: countdown(f.start, f.now || Date.now(), f.lang) || title, lines: names.length ? [w.with_ + " " + names.join(" · ")] : [], rows: [], foot: foot }
    if (tpl === "tickets") {
        var st = TICKET_STATES.indexOf(f.ticket) >= 0 ? f.ticket : "onsale"
        return { kicker: title, big: w[st], lines: [Ext.str(f.price).trim(), extra].filter(function (x) { return !!x }), rows: [], foot: foot }
    }
    if (tpl === "thanks") return { kicker: title, big: w.thanks, lines: extra ? [extra] : [], rows: [], foot: venue }
    return { kicker: "", big: title, lines: [names.length ? w.with_ + " " + names.join(" · ") : "", extra].filter(function (x) { return !!x }), rows: [], foot: foot }
}
function setKey(t) { var m = /^(\d{2}):(\d{2})$/.exec(t || ""); if (!m) return 1e6; var h = Number(m[1]); return (h < 12 ? h + 24 : h) * 60 + Number(m[2]) }
// Big text shrinks with its length so a long name still fits on one or two lines.
function bigSize(text, width) {
    var n = Math.max(1, Ext.str(text).length)
    return Math.max(72, Math.min(260, Math.round(width * 1.9 / Math.max(6, n))))
}

// File name: "freequencies-02-artist-dj-um-feed.png"
function slug(s) { return Ext.str(s).toLowerCase().normalize ? Ext.str(s).toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 40) : Ext.str(s).toLowerCase().replace(/[^a-z0-9]+/g, "-") }
function fileName(tpl, title, artist, size) {
    return [slug(title) || "night", tpl, tpl === "artist" ? slug(artist) : "", size].filter(function (x) { return !!x }).join("-") + ".png"
}

// The campaign: one social post per stage, dated from show day (artists spread over T-10…T-3).
// Stages already in the planner (same text) are skipped. Returns post data for ext kind "post".
function campaign(night, lineupNames, existing) {
    var start = night && night.startTime
    if (typeof start !== "number") return []
    var title = Ext.str(night.title) || "the event", out = [], have = {}
    ;(existing || []).forEach(function (p) { have[Ext.str(p.d && p.d.text)] = true })
    function add(t, text) {
        var at = new Date(start - t * DAY); at.setHours(t <= 0 ? 12 : 18, 0, 0, 0)
        if (!have[text]) out.push({ text: text, channel: "Instagram", when: at.getTime(), done: false })
    }
    add(28, "Announce: " + title)
    add(14, "Line-up reveal: " + title)
    var names = (lineupNames || []).filter(function (x) { return !!x })
    for (var i = 0; i < names.length; i++) {
        var t = names.length === 1 ? 7 : Math.round(10 - i * 7 / (names.length - 1))
        add(t, "Artist card: " + names[i])
    }
    add(7, "Tickets: " + title)
    add(1, "Timetable story: " + title)
    add(0, "Countdown story: tonight")
    add(-1, "Thank you / recap: " + title)
    return out
}
