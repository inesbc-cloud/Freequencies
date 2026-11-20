.pragma library
// Tickets (#13): ext kind "tickets" {url?, sold?, capacity?, price?, currency?}, newest wins.
.import "ext.js" as Ext

function ticketsOf(ev) { return Ext.latestData(ev, "tickets") }
function revenue(t) { return t && Ext.num(t.sold) !== null && Ext.num(t.price) !== null ? t.sold * t.price : 0 }
function soldShare(t) { return t && Ext.num(t.capacity) > 0 ? Math.min(1, (Ext.num(t.sold) || 0) / t.capacity) : 0 }
function line(t) {
    if (!t) return ""
    var parts = []
    if (Ext.num(t.sold) !== null) parts.push(t.sold + (Ext.num(t.capacity) ? " / " + t.capacity : "") + " sold")
    if (Ext.num(t.price) !== null) parts.push(t.price === 0 ? "free entry" : t.price + " " + (Ext.str(t.currency) || "EUR"))
    return parts.join(" · ")
}
// From the dialog's text fields: {data} or {error}.
function parse(url, sold, capacity, price, currency) {
    function n(s) { s = String(s).trim().replace(",", "."); if (s === "") return null; var v = Number(s); return isFinite(v) && v >= 0 ? v : NaN }
    var d = {}, so = n(sold), ca = n(capacity), pr = n(price)
    if (isNaN(so) || isNaN(ca) || isNaN(pr)) return { error: "Sold, capacity and price should be numbers." }
    url = String(url || "").trim()
    if (url && !/^https?:\/\//i.test(url)) url = "https://" + url
    if (url) d.url = url
    if (so !== null) d.sold = so
    if (ca !== null) d.capacity = ca
    if (pr !== null) { d.price = pr; d.currency = String(currency || "").trim().toUpperCase() || "EUR" }
    return { data: d }
}
