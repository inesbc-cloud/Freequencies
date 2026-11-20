// Freequencies header: dish mark, wordmark, and the faint CRT scanlines of the site's hero.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: hdr
    default property alias tools: toolRow.data     // buttons on the right (mode switch, + Night…)
    implicitHeight: 62
    color: Fq.ground
    clip: true
    Repeater {
        model: Math.ceil(hdr.height / 4)
        delegate: Rectangle { required property int index; y: index * 4 + 3; width: hdr.width; height: 1; color: Fq.lime; opacity: 0.05 }
    }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
        Image { source: "dish.png"; Layout.preferredWidth: 40; Layout.preferredHeight: 40; fillMode: Image.PreserveAspectFit; smooth: false }
        ColumnLayout {
            spacing: -6
            DText { text: "FREEQUENCIES"; color: Fq.lime; font.pixelSize: 40 }
            FText { text: "( coordination tool · lisboa )"; color: Fq.sub; font.pixelSize: 12; font.letterSpacing: 1 }
        }
        Item { Layout.fillWidth: true }
        RowLayout { id: toolRow; spacing: 8 }
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fq.line }
}
