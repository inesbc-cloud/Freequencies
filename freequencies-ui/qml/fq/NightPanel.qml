// The night panel (#8): everything about one night in the right pane. The acid-green block at the
// top is the poster's look; below it, one section per file in fq/sections/, each added by its issue.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "lib/nights.js" as Nights
import "sections"

Rectangle {
    id: panel
    property var app                                   // FreequenciesView root
    readonly property var occ: app.selectedNight        // the occurrence that was clicked
    readonly property var night: app.selNight           // its master event, fresh from the last refresh
    readonly property var cal: night ? app.calById(night.calendarId) : null
    readonly property bool canEdit: Nights.canEdit(night, cal)
    color: Fq.mantle

    Flickable {
        id: flick
        objectName: "nightPanelFlick"
        anchors.fill: parent; clip: true
        contentWidth: width; contentHeight: col.implicitHeight + 30
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        ColumnLayout {
            id: col
            width: flick.width; spacing: 0

            Rectangle {   // poster block
                Layout.fillWidth: true; Layout.preferredHeight: hdr.implicitHeight + 30; color: Fq.acid
                ColumnLayout {
                    id: hdr
                    x: 16; y: 15; width: parent.width - 32; spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        FText { text: panel.occ ? (panel.occ.endTime < Date.now() ? "( past gathering )" : "( next gathering )") : ""; color: Fq.ink; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2 }
                        Item { Layout.fillWidth: true }
                        FText { text: "✕"; color: Fq.ink; font.pixelSize: 16
                            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: panel.app.selectedNight = null } }
                    }
                    DText { text: panel.occ ? Qt.formatDate(new Date(panel.occ.startTime), "dd.MM") : ""; color: Fq.ink; font.pixelSize: 72; Layout.topMargin: -4 }
                    DText { text: panel.night ? (panel.night.title || "(untitled)").toUpperCase() : ""; color: Fq.ink; font.pixelSize: 32; wrapMode: Text.Wrap; Layout.fillWidth: true; Layout.topMargin: -10 }
                    FText {
                        Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.ink; font.pixelSize: 13
                        text: panel.occ ? Qt.formatDate(new Date(panel.occ.startTime), "dddd") + "  ·  "
                              + (panel.occ.allDay ? "all day" : Qt.formatTime(new Date(panel.occ.startTime), "hh'h'mm") + " às " + Qt.formatTime(new Date(panel.occ.endTime), "hh'h'mm"))
                              + (Nights.fieldOf(panel.night, "venue") ? "  ·  " + Nights.fieldOf(panel.night, "venue") : "") : ""
                    }
                    Flow {
                        Layout.fillWidth: true; Layout.topMargin: 6; spacing: 6
                        Badge { text: Nights.fieldOf(panel.night, "status") || "no status"; tone: Fq.ink }
                        Badge { visible: Nights.fieldOf(panel.night, "type") !== ""; text: Nights.fieldOf(panel.night, "type"); tone: Fq.ink }
                        Badge { visible: !!panel.cal; text: panel.cal ? (panel.cal.name || "") : ""; tone: Fq.ink }
                        Badge { visible: !!panel.night && !!panel.night.recur && !!panel.night.recur.freq; text: "↻ " + (panel.night ? panel.app.recurLabel(panel.night.recur) : ""); tone: Fq.ink }
                    }
                }
            }

            ColumnLayout {
                id: sections
                objectName: "nightSections"
                Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.topMargin: 6; spacing: 6

                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
                    FqButton { text: "Edit details"; onClicked: panel.app.openEditEvent(panel.occ) }
                    Item { Layout.fillWidth: true }
                }
                FText { visible: !!panel.night && !panel.canEdit; Layout.fillWidth: true; Layout.topMargin: 8; wrapMode: Text.Wrap; color: Fq.warn; font.pixelSize: 12
                    text: "Read-only: you're a " + Nights.roleOf(panel.cal) + " on this calendar." }

                QuickFields { app: panel.app; night: panel.night; canEdit: panel.canEdit }
                NotesSection { app: panel.app; night: panel.night; canEdit: panel.canEdit }
            }
        }
    }
}
