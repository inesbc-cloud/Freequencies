// A text action.
import QtQuick

FText {
    id: lk
    signal clicked()
    property color tone: Fq.acid
    color: m.containsMouse ? Fq.text : tone; font.pixelSize: 12; font.underline: m.containsMouse
    MouseArea { id: m; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lk.clicked() }
}
