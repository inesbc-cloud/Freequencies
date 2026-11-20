// Notes (#8): the night's description, edited in place. Never part of the public copy (ADR 0008).
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

ColumnLayout {
    id: ns
    property var app
    property var night
    property bool canEdit: false
    readonly property string saved: night ? (night.description || "") : ""
    Layout.fillWidth: true; spacing: 6
    Sec { label: "Notes"; action: area.text !== ns.saved && ns.canEdit ? "save" : ""
          onAct: ns.app.editNight(ns.night, function (up) { up.description = area.text }, "Notes saved") }
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: Math.max(80, area.implicitHeight + 4)
        color: Fq.ground; border.width: 1; border.color: area.activeFocus ? Fq.lime : Fq.line
        TextArea {
            id: area
            anchors.fill: parent; wrapMode: TextEdit.Wrap; readOnly: !ns.canEdit
            text: ns.saved
            color: Fq.text; font.family: Fq.body; font.pixelSize: 13
            placeholderText: "Private notes for the team: load-in, contacts, what to remember…"
            placeholderTextColor: Fq.faint; selectionColor: Fq.lime; selectedTextColor: Fq.ink
            background: Item {}
        }
    }
}
