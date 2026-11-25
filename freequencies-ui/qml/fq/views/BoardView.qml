// The board (#9): two weeks down, one column per venue (or status, or calendar) across.
// Drop a night in a cell to move it to that day, and to that venue or status.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../lib/lanes.js" as Lanes

ColumnLayout {
    id: bv
    property var app
    readonly property real first: { var d = new Date(app.selectedDay); d.setHours(0, 0, 0, 0); d.setDate(d.getDate() - ((d.getDay() + 6) % 7)); return d.getTime() }
    readonly property int nDays: 14
    readonly property var grid: Lanes.buildLanes(app.expandEvents(app.eventsFiltered(), first, first + (nDays + 1) * 864e5), app.laneBy, first, nDays, app.freqCals)
    readonly property int dateW: 74
    readonly property int cellW: 190
    spacing: 6

    Flow {
        Layout.fillWidth: true; spacing: 6
        FText { text: Fq.t("COLUMNS"); color: Fq.faint; font.pixelSize: 12; font.letterSpacing: 1.2; height: 26; verticalAlignment: Text.AlignVCenter }
        Repeater { model: [{ id: "venue", l: Fq.t("Venue") }, { id: "status", l: Fq.t("Status") }, { id: "calendar", l: Fq.t("Calendar") }]
            delegate: Chip { required property var modelData; text: Fq.t(modelData.l); on: bv.app.laneBy === modelData.id; onClicked: bv.app.laneBy = modelData.id } }
        FText { text: Fq.t("· drop an event in another column to change its ") + bv.app.laneBy; color: Fq.faint; font.pixelSize: 12; height: 26; verticalAlignment: Text.AlignVCenter
                visible: bv.app.laneBy !== "calendar" }
    }
    Flickable {
        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
        contentWidth: board.width + 8; contentHeight: board.height + 8
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        ScrollBar.horizontal: ScrollBar {}
        FText { visible: bv.grid.lanes.length === 0; text: Fq.t("No events in these two weeks. Add one with “+ Event”."); color: Fq.sub; font.pixelSize: 14 }
        Column {
            id: board
            Row {
                Item { width: bv.dateW; height: 32 }
                Repeater {
                    model: bv.grid.lanes
                    delegate: Item {
                        required property var modelData
                        width: bv.cellW; height: 32
                        DText { x: 6; width: bv.cellW - 12; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; size: 20
                                text: Fq.t(parent.modelData.label).toUpperCase() }
                    }
                }
            }
            Repeater {
                model: bv.grid.days
                delegate: Row {
                    id: dayRow
                    required property var modelData
                    readonly property bool isToday: new Date(modelData.date).toDateString() === new Date().toDateString()
                    readonly property bool weekend: { var g = new Date(modelData.date).getDay(); return g === 5 || g === 6 }
                    readonly property int maxN: { var m = 0; for (var i = 0; i < modelData.cells.length; i++) m = Math.max(m, modelData.cells[i].length); return m }
                    Rectangle {
                        width: bv.dateW; height: cells.height
                        color: dayRow.weekend ? Fq.mantle : "transparent"; border.width: 1; border.color: Fq.line
                        Column {
                            x: 8; anchors.verticalCenter: parent.verticalCenter; spacing: -3
                            FText { text: Fq.fmtDate(new Date(dayRow.modelData.date), "ddd").toUpperCase(); color: dayRow.isToday ? Fq.lime : Fq.faint; font.pixelSize: 12; font.letterSpacing: 1.2 }
                            DText { text: Fq.fmtDate(new Date(dayRow.modelData.date), "dd.MM"); color: dayRow.isToday ? Fq.lime : Fq.sub; size: 22 }
                        }
                    }
                    Row {
                        id: cells
                        Repeater {
                            model: dayRow.modelData.cells
                            delegate: Rectangle {
                                id: cell
                                required property var modelData
                                required property int index
                                width: bv.cellW; height: Math.max(52, dayRow.maxN * 48 + 8)   // one height per day row
                                color: dayRow.weekend ? Fq.mantle : "transparent"; border.width: 1; border.color: Fq.line
                                MouseArea {
                                    anchors.fill: parent
                                    onDoubleClicked: { bv.app.selectedDay = new Date(dayRow.modelData.date); bv.app.openNewEvent() }
                                }
                                Column {
                                    id: cellCol
                                    x: 4; y: 4; width: bv.cellW - 8; spacing: 4; z: 2
                                    Repeater { model: cell.modelData
                                        delegate: NightCard { required property var modelData; app: bv.app; occ: modelData; width: cellCol.width } }
                                }
                                DropArea {
                                    anchors.fill: parent
                                    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 2; border.color: Fq.lime; visible: parent.containsDrag }
                                    onDropped: function (drop) {
                                        if (drop.source && drop.source.dragEv)
                                            bv.app.moveNightTo(drop.source.dragEv, new Date(dayRow.modelData.date), bv.app.laneBy, bv.grid.lanes[cell.index].id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
