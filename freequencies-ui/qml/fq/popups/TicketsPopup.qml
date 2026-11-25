// Ticket link and numbers (#13).
import QtQuick
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/tickets.js" as Tickets

Win {
    id: tp
    property var app
    property var night
    title: "tickets.exe"
    function openFor() {
        var t = Tickets.ticketsOf(night) || {}
        url.text = t.url || ""; sold.text = t.sold !== undefined ? String(t.sold) : ""; cap.text = t.capacity !== undefined ? String(t.capacity) : ""
        price.text = t.price !== undefined ? String(t.price) : ""; cur.text = t.currency || "EUR"
        open()
    }
    function save() {
        var r = Tickets.parse(url.text, sold.text, cap.text, price.text, cur.text)
        if (r.error) { app.notify(r.error, true); return }
        app.putLatest(night, "tickets", r.data, "Tickets updated"); close()
    }
    Label_ { text: Fq.t("TICKET PAGE LINK") }
    Field { id: url; Layout.fillWidth: true; placeholderText: "https://lu.ma/… or 3cket, Shotgun, RA" }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: Fq.t("SOLD") } Field { id: sold; Layout.fillWidth: true; placeholderText: "0" } }
        ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: Fq.t("CAPACITY") } Field { id: cap; Layout.fillWidth: true; placeholderText: "180" } }
    }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: Fq.t("PRICE (0 = FREE ENTRY)") } Field { id: price; Layout.fillWidth: true; placeholderText: "10" } }
        ColumnLayout { spacing: 4; Label_ { text: Fq.t("CURRENCY") } Field { id: cur; Layout.preferredWidth: 90 } }
    }
    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 12
        text: Fq.t("Numbers are typed in for now. Sales count towards attendance and revenue in Analytics and the event's budget.") }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        Item { Layout.fillWidth: true }
        FqButton { text: Fq.t("Cancel"); onClicked: tp.close() }
        FqButton { text: Fq.t("Save"); primary: true; enabled: !tp.app || !tp.app.extBusy; onClicked: tp.save() }
    }
}
