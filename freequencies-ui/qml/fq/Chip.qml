// A toggle chip: ruled square; filled with its accent when on.
import QtQuick

Rectangle {
    id: chip
    property string text: ""
    property bool on: false
    property color accent: Fq.lime
    property bool enabled_: true
    signal clicked()
    height: 26; width: t.implicitWidth + 20
    opacity: enabled_ ? 1 : 0.5
    color: on ? accent : (m.containsMouse ? Fq.surface : "transparent")
    border.width: 1; border.color: on ? accent : Fq.line
    FText { id: t; anchors.centerIn: parent; text: chip.text; color: chip.on ? Fq.ink : Fq.sub; font.pixelSize: 12 }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (chip.enabled_) chip.clicked() }
}
