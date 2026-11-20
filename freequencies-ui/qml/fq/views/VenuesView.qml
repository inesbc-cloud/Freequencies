// Venues (#26): every venue the nights have used; show its nights, start a night there, open a map.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../lib/venues.js" as Venues
import "../lib/filters.js" as Filters

Flickable {
    id: vv
    property var app
    readonly property var list: Venues.venues(app.freqNights, app.nowTick, app.calName)
    clip: true; contentWidth: width; contentHeight: col.implicitHeight + 20
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: col
        width: vv.width - 12; spacing: 12
        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
            text: "Every venue your nights have used, saved once and reused: a night's venue is one click in its panel." }
        FText { visible: vv.list.length === 0; text: "No venues yet. Give a night a venue and it shows up here."; color: Fq.sub; font.pixelSize: 14 }
        GridLayout {
            Layout.fillWidth: true; columns: Math.max(1, Math.floor(col.width / 290)); columnSpacing: -1; rowSpacing: -1
            Repeater {
                model: vv.list
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: tc.implicitHeight + 28; color: Fq.mantle; border.width: 1; border.color: Fq.line
                    Rectangle { width: parent.width; height: 4; color: Fq.swatch[Math.abs(tile.modelData.name.toLowerCase().split("").reduce(function (h, c) { return (h * 31 + c.charCodeAt(0)) >>> 0 }, 0)) % Fq.swatch.length] }
                    ColumnLayout {
                        id: tc
                        x: 16; y: 16; width: parent.width - 32; spacing: 4
                        DText { Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 32; text: tile.modelData.name.toUpperCase() }
                        FText { color: Fq.sub; font.pixelSize: 13; text: tile.modelData.nights + " night" + (tile.modelData.nights === 1 ? "" : "s") + " · " + tile.modelData.upcoming + " coming up" }
                        FText { color: Fq.sub; font.pixelSize: 13; visible: text !== ""
                            text: tile.modelData.next ? "Next: " + Qt.formatDate(new Date(tile.modelData.next), "ddd d MMM") : tile.modelData.last ? "Last: " + Qt.formatDate(new Date(tile.modelData.last), "d MMM yyyy") : "" }
                        FText { color: Fq.sub; font.pixelSize: 13; visible: tile.modelData.attendance > 0; text: tile.modelData.attendance + " people through the door" }
                        FText { color: Fq.faint; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight; text: tile.modelData.cals.join(" · ") }
                        Flow {
                            Layout.fillWidth: true; Layout.topMargin: 6; spacing: 14
                            Link { text: "show nights"; onClicked: { vv.app.nightFilter = Filters.with_(Filters.empty(), "venue", tile.modelData.name); vv.app.calMode = "timeline" } }
                            Link { text: "map ↗"; onClicked: Qt.openUrlExternally("https://www.openstreetmap.org/search?query=" + encodeURIComponent(tile.modelData.name + ", Lisboa")) }
                        }
                    }
                }
            }
        }
    }
}
