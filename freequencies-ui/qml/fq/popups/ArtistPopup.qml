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
        feeIn.text = b && b.fee !== null ? String(b.fee) : ""
        var cur = "EUR", lu = Lineup.lineupOf(night)
        for (var i = 0; i < lu.length; i++) if (lu[i].currency) { cur = lu[i].currency; break }
        curIn.text = b && b.currency ? b.currency : cur
        open()
        app.loadKith()
    }
    function save() {
        var name = nameIn.text.trim()
        if (!name) { app.notify("Pick an artist or type a name.", true); return }
        var feeT = feeIn.text.trim().replace(",", "."), fee = feeT === "" ? null : Number(feeT)
        if (fee !== null && !(isFinite(fee) && fee >= 0)) { app.notify("The fee should be a number, for example 250 or 99.50.", true); return }
        var data = Lineup.bookingData(name, status, contact, book, fee, curIn.text.trim().toUpperCase(), setIn.text.trim())
        app.postItem(night, Ext.item("artist", night.id, data, id_), id_ ? "Booking updated" : "Added " + name, function (ok) { if (ok) ap.close() })
    }

    Label_ { text: "FROM KITH" }
    Field { id: search; Layout.fillWidth: true; placeholderText: ap.app && ap.app.kithState === "missing" ? "Kith isn't installed: type the name below" : "Search your Kith books…"
            onTextChanged: ap.query = text }
    Flow {
        Layout.fillWidth: true; spacing: 6
        Repeater { model: ap.matches
            delegate: Chip { required property var modelData; text: modelData.name; on: ap.contact === modelData.id
                onClicked: { ap.contact = modelData.id; ap.book = modelData.bookId; nameIn.text = modelData.name } } }
    }
    FText { visible: !!ap.app && ap.app.kithState === "none"; text: "No Kith books yet."; color: Fq.faint; font.pixelSize: 12 }
    Label_ { text: "NAME" }
    Field { id: nameIn; Layout.fillWidth: true; placeholderText: "Artist or act"; onTextEdited: ap.contact = "" }
    Label_ { text: "STATUS" }
    Flow { Layout.fillWidth: true; spacing: 6
        Repeater { model: Lineup.bookingStatuses
            delegate: Chip { required property var modelData; text: Lineup.cap(modelData); accent: ap.app ? ap.app.bookingColor(modelData) : Fq.lime
                on: ap.status === modelData; onClicked: ap.status = modelData } } }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        ColumnLayout { spacing: 4; Label_ { text: "SET" } Field { id: setIn; Layout.preferredWidth: 90; placeholderText: "23:00" } }
        ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: "FEE" } Field { id: feeIn; Layout.fillWidth: true; placeholderText: "250" } }
        ColumnLayout { spacing: 4; Label_ { text: "CURRENCY" } Field { id: curIn; Layout.preferredWidth: 80 } }
    }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        FqButton { visible: ap.canRemove; text: "Remove"; onClicked: ap.app.deleteItem(ap.night, ap.id_, "Removed from the line-up", function (ok) { if (ok) ap.close() }) }
        Item { Layout.fillWidth: true }
        FqButton { text: "Cancel"; onClicked: ap.close() }
        FqButton { text: ap.id_ ? "Save" : "Add"; primary: true; enabled: !ap.app || !ap.app.extBusy; onClicked: ap.save() }
    }
}
