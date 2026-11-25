// Sidebar: the Scala calendars that aren't Freequencies calendars (#5). Shown until you untick them; "use for Freequencies" adds the Status / Venue / Type fields (or says why it can't).
import QtQuick
import QtQuick.Layouts
import "lib/nights.js" as Nights

ColumnLayout {
    id: oc
    property var app                       // FreequenciesView root
    visible: app.otherCals.length > 0
    spacing: 4
    FText { text: Fq.t(">_ OTHER SCALA CALENDARS"); color: Fq.faint; font.pixelSize: 12; font.letterSpacing: 1.2; Layout.topMargin: 6 }
    Repeater {
        model: oc.app.otherCals
        delegate: ColumnLayout {
            id: row
            required property var modelData
            readonly property string why: oc.app.adoptReason(modelData)
            Layout.fillWidth: true; spacing: 1
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Rectangle {
                    width: 12; height: 12
                    color: oc.app.calHidden(row.modelData.id) ? "transparent" : oc.app.calColor(row.modelData.id)
                    border.width: 1; border.color: oc.app.calHidden(row.modelData.id) ? Fq.sub : color
                    MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: oc.app.toggleCalVisible(row.modelData.id) }
                }
                FText { text: row.modelData.name || Fq.t("(unnamed)"); color: Fq.sub; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            FText {
                visible: row.why === ""; Layout.leftMargin: 20; text: Fq.t("use for Freequencies →"); color: Fq.acid; font.pixelSize: 12
                MouseArea { anchors.fill: parent; anchors.margins: -3; cursorShape: Qt.PointingHandCursor; onClicked: oc.app.adoptCalendar(row.modelData) }
            }
            FText { visible: row.why !== ""; Layout.leftMargin: 20; Layout.fillWidth: true; wrapMode: Text.Wrap; text: Fq.t(row.why); color: Fq.faint; font.pixelSize: 12 }
        }
    }
}
