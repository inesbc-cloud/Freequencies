// Tickets (#13): the ticket page and the numbers (sold / capacity / price).
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/tickets.js" as Tickets

ColumnLayout {
    id: tk
    property var app
    property var night
    property bool canEdit: false
    signal editTickets()
    readonly property var t: Tickets.ticketsOf(night)
    Layout.fillWidth: true; spacing: 5

    Sec { label: "Tickets"; action: tk.canEdit ? (tk.t ? "edit" : "+ add") : ""; onAct: tk.editTickets() }
    FText { visible: !tk.t; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: "No ticket link yet. Paste one from Luma, 3cket, Shotgun… and keep the numbers here." }
    RowLayout {
        visible: !!tk.t; Layout.fillWidth: true; spacing: 10
        DText { text: tk.t && tk.t.sold !== undefined ? String(tk.t.sold) : "—"; font.pixelSize: 40; color: Fq.lime }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            FText { text: Tickets.line(tk.t); color: Fq.text; font.pixelSize: 13 }
            Rectangle {
                visible: Tickets.soldShare(tk.t) > 0 || (!!tk.t && tk.t.capacity > 0)
                Layout.fillWidth: true; height: 8; color: Fq.surface2
                Rectangle { height: parent.height; width: parent.width * Tickets.soldShare(tk.t); color: Fq.lime }
            }
        }
    }
    Link { visible: !!tk.t && !!tk.t.url; text: tk.t && tk.t.url ? "open ticket page ↗  " + String(tk.t.url).replace(/^https?:\/\//, "") : ""
           onClicked: Qt.openUrlExternally(tk.t.url) }
}
