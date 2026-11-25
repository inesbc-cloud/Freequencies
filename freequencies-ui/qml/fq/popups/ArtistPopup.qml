// Add or change a booking (#10): pick from Kith (or type a name), status, set time, fee.
import QtQuick
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/lineup.js" as Lineup
import "../lib/ext.js" as Ext

Win {
    id: ap
    property var app
    property var night
    title: id_ ? "booking.exe" : "new_booking.exe"
    property string id_: ""
    property string contact: ""
    property string book: ""
    property string status: "asked"
    property bool canRemove: false
    property string query: ""
    property bool fLocal: false
    property bool fWnb: false
    property bool fFirst: false
    readonly property var matches: {
        var q = query.trim().toLowerCase(), out = [], ks = app ? app.kithArtists : []
        for (var i = 0; i < ks.length && out.length < 12; i++) if (!q || ks[i].name.toLowerCase().indexOf(q) >= 0) out.push(ks[i])
        return out
    }
    function openFor(b) {
        var cal = app.calById(night.calendarId)
        id_ = b ? b.id : ""; contact = b ? b.contact : ""; book = b ? b.book : ""; status = b ? b.status : "asked"
        canRemove = !!b && ((!!cal && b.author === cal.authorAddr) || app.isEditorOf(cal))
        query = ""; search.text = ""
        nameIn.text = b ? b.name : ""; setIn.text = b ? b.set : ""
        fLocal = !!b && b.local === true; fWnb = !!b && b.wnb === true; fFirst = !!b && b.first === true
        feeIn.text = b && b.fee !== null ? String(b.fee) : ""
        var cur = "EUR", lu = Lineup.lineupOf(night)
        for (var i = 0; i < lu.length; i++) if (lu[i].currency) { cur = lu[i].currency; break }
        curIn.text = b && b.currency ? b.currency : cur
        open()
        app.loadKith()
    }
    function save() {
        var name = nameIn.text.trim()
        if (!name) { app.notify(Fq.t("Pick an artist or type a name."), true); return }
        var feeT = feeIn.text.trim().replace(",", "."), fee = feeT === "" ? null : Number(feeT)
        if (fee !== null && !(isFinite(fee) && fee >= 0)) { app.notify(Fq.t("The fee should be a number, for example 250 or 99.50."), true); return }
        var data = Lineup.bookingData(name, status, contact, book, fee, curIn.text.trim().toUpperCase(), setIn.text.trim(), { local: fLocal, wnb: fWnb, first: fFirst })
        app.postItem(night, Ext.item("artist", night.id, data, id_), id_ ? Fq.t("Booking updated") : Fq.t("Added ") + name, function (ok) { if (ok) ap.close() })
    }

    Label_ { text: Fq.t("FROM KITH") }
    Field { id: search; Layout.fillWidth: true; placeholderText: ap.app && ap.app.kithState === "missing" ? Fq.t("Kith isn't installed: type the name below") : Fq.t("Search your Kith books…")
            onTextChanged: ap.query = text }
    Flow {
        Layout.fillWidth: true; spacing: 6
        Repeater { model: ap.matches
            delegate: Chip { required property var modelData; text: modelData.name; on: ap.contact === modelData.id
                onClicked: { ap.contact = modelData.id; ap.book = modelData.bookId; nameIn.text = modelData.name } } }
    }
    FText { visible: !!ap.app && ap.app.kithState === "none"; text: Fq.t("No Kith books yet."); color: Fq.faint; font.pixelSize: 12 }
    Label_ { text: Fq.t("NAME") }
    Field { id: nameIn; Layout.fillWidth: true; placeholderText: Fq.t("Artist or act"); onTextEdited: ap.contact = "" }
    Label_ { text: Fq.t("STATUS") }
    Flow { Layout.fillWidth: true; spacing: 6
        Repeater { model: Lineup.bookingStatuses
            delegate: Chip { required property var modelData; text: Fq.t(Lineup.cap(modelData)); accent: ap.app ? ap.app.bookingColor(modelData) : Fq.lime
                on: ap.status === modelData; onClicked: ap.status = modelData } } }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        ColumnLayout { spacing: 4; Label_ { text: Fq.t("SET") } Field { id: setIn; Layout.preferredWidth: 90; placeholderText: "23:00" } }
        ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: Fq.t("FEE") } Field { id: feeIn; Layout.fillWidth: true; placeholderText: "250" } }
        ColumnLayout { spacing: 4; Label_ { text: Fq.t("CURRENCY") } Field { id: curIn; Layout.preferredWidth: 80 } }
    }
    Label_ { text: Fq.t("FOR FUNDER REPORTS (OPTIONAL, PRIVATE)") }
    Flow { Layout.fillWidth: true; spacing: 6
        Chip { text: Fq.t("Based in Lisbon"); on: ap.fLocal; onClicked: ap.fLocal = !ap.fLocal }
        Chip { text: Fq.t("Woman or non-binary"); on: ap.fWnb; onClicked: ap.fWnb = !ap.fWnb }
        Chip { text: Fq.t("First time on stage"); on: ap.fFirst; onClicked: ap.fFirst = !ap.fFirst } }
    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 11
        text: Fq.t("Only counted, never shown by name: Reports adds them up for applications. Ask the artist first.") }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        FqButton { visible: ap.canRemove; text: Fq.t("Remove"); onClicked: ap.app.deleteItem(ap.night, ap.id_, Fq.t("Removed from the line-up"), function (ok) { if (ok) ap.close() }) }
        Item { Layout.fillWidth: true }
        FqButton { text: Fq.t("Cancel"); onClicked: ap.close() }
        FqButton { text: ap.id_ ? Fq.t("Save") : Fq.t("Add"); primary: true; enabled: !ap.app || !ap.app.extBusy; onClicked: ap.save() }
    }
}
