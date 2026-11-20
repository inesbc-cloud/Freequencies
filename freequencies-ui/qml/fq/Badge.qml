// An outlined label: status, type, calendar.
import QtQuick

Rectangle {
    id: bd
    property string text: ""
    property color tone: Fq.lime
    height: 20; width: t.implicitWidth + 12; color: "transparent"; border.width: 1; border.color: tone
    FText { id: t; anchors.centerIn: parent; text: bd.text.toUpperCase(); color: bd.tone; font.pixelSize: 12; font.letterSpacing: 1 }
}
