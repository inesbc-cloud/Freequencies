// A checklist on the night: tasks (#16), gear (#17) or social posts (#19). Tick to mark done.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/checklist.js" as Checklist

ColumnLayout {
    id: cl
    property var app
    property var night
    property bool canEdit: false
    property string kind: "task"           // "task" | "gear" | "post"
    property string label: "Tasks"
    property string addLabel: "+ task"
    property string emptyText: ""
    property var items: []                 // [{id, author, d}] from fq/lib/checklist.js
    property var meta: function (it) { return "" }        // the grey line under an item
    property var tone: function (it) { return Fq.sub }    // its colour (overdue, due soon)
    signal editItem(string kind, var item) // null = add
    default property alias extra: tail.data
    Layout.fillWidth: true; spacing: 6

    Sec { label: cl.label; action: cl.canEdit ? cl.addLabel : ""; onAct: cl.editItem(cl.kind, null) }
    FText { visible: cl.items.length === 0 && cl.emptyText !== ""; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; text: cl.emptyText }
    Repeater {
        model: cl.items
        delegate: Rectangle {
            id: row
            required property var modelData
            readonly property bool done: modelData.d.done === true
            readonly property string metaText: cl.meta(modelData)
            Layout.fillWidth: true; Layout.preferredHeight: rc.implicitHeight + 12
            color: rm.containsMouse ? Fq.surface : "transparent"; border.width: 1; border.color: Fq.line
            MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cl.editItem(cl.kind, row.modelData) }
            Rectangle {
                x: 8; anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14
                color: row.done ? Fq.lime : "transparent"; border.width: 1; border.color: row.done ? Fq.lime : Fq.sub
                FText { anchors.centerIn: parent; visible: row.done; text: "✓"; color: Fq.ink; font.pixelSize: 11; font.bold: true }
                MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; enabled: cl.canEdit
                    onClicked: { var d = {}; for (var k in row.modelData.d) d[k] = row.modelData.d[k]; d.done = !row.done
                                 cl.app.postItem(cl.night, { ns: "xyz.freequencies", kind: cl.kind, target: cl.night.id, id: row.modelData.id, data: d }, "") } }
            }
            Column {
                id: rc
                x: 30; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 38; spacing: 1
                FText { width: parent.width; elide: Text.ElideRight; font.pixelSize: 13; color: row.done ? Fq.sub : Fq.text; font.strikeout: row.done
                        text: row.modelData.d.text || row.modelData.d.item || "" }
                FText { width: parent.width; elide: Text.ElideRight; visible: row.metaText !== ""; text: row.metaText; font.pixelSize: 12; color: cl.tone(row.modelData) }
            }
        }
    }
    ColumnLayout { id: tail; Layout.fillWidth: true; spacing: 6 }
}
