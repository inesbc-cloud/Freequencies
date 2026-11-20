// A Freequencies dialog: lime frame and title bar ("name.exe"), modal, centred.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: win
    property string title: ""
    default property alias body: content.data
    anchors.centerIn: Overlay.overlay
    width: 460; modal: true; padding: 0
    background: Rectangle { color: Fq.ground; border.width: 2; border.color: Fq.lime }
    contentItem: ColumnLayout {
        spacing: 0
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 30; color: Fq.lime
            FText { x: 12; anchors.verticalCenter: parent.verticalCenter; text: win.title.toUpperCase(); color: Fq.ink; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.4 }
            FText { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "✕"; color: Fq.ink; font.pixelSize: 13
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: win.close() } }
        }
        ColumnLayout { id: content; Layout.fillWidth: true; Layout.margins: 18; spacing: 7 }
    }
}
