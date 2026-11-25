// Colour-by switch and legend above the grid (#6).
import QtQuick
import QtQuick.Layouts
import "lib/colour.js" as Colour

Flow {
    id: cb
    property var app
    spacing: 6
    FText { text: Fq.t("COLOUR BY"); color: Fq.faint; font.pixelSize: 12; font.letterSpacing: 1.2; height: 24; verticalAlignment: Text.AlignVCenter }
    Repeater {
        model: Colour.modes
        delegate: Rectangle {
            required property var modelData
            readonly property bool on: cb.app.colorBy === modelData.id
            height: 24; width: t.implicitWidth + 18
            color: on ? Fq.lime : (m.containsMouse ? Fq.surface : "transparent"); border.width: 1; border.color: on ? Fq.lime : Fq.line
            FText { id: t; anchors.centerIn: parent; text: Fq.t(modelData.label); font.pixelSize: 12; color: parent.on ? Fq.ink : Fq.sub }
            MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cb.app.colorBy = modelData.id }
        }
    }
    Item { width: 10; height: 24 }
    Repeater {
        model: cb.app.legend
        delegate: Row {
            required property var modelData
            height: 24; spacing: 5
            Rectangle { width: 10; height: 10; color: modelData.color; anchors.verticalCenter: parent.verticalCenter }
            FText { text: Fq.t(modelData.label); color: Fq.sub; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
