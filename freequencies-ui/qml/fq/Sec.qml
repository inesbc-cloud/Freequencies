// Section head in the night panel: ">_ LABEL ─────────── action"
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: sec
    property string label: ""
    property string action: ""             // e.g. "+ artist"; empty = none
    signal act()
    Layout.fillWidth: true; Layout.topMargin: 16; spacing: 8
    FText { text: ">_ " + sec.label.toUpperCase(); color: Fq.lime; font.pixelSize: 12; font.letterSpacing: 1.2 }
    Rectangle { Layout.fillWidth: true; height: 1; color: Fq.line }
    FText {
        visible: sec.action !== ""; text: sec.action; color: am.containsMouse ? Fq.text : Fq.acid; font.pixelSize: 12
        MouseArea { id: am; anchors.fill: parent; anchors.margins: -5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sec.act() }
    }
}
