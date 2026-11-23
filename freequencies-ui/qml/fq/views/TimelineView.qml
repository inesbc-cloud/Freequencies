// The timeline (#23): what's coming up (or what happened): date, poster, line-up, tags, tickets, tasks.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../lib/timeline.js" as Timeline
import "../lib/nights.js" as Nights
import "../lib/lineup.js" as Lineup
import "../lib/tags.js" as Tags
import "../lib/tickets.js" as Tickets
import "../lib/checklist.js" as Checklist

ColumnLayout {
    id: tv
    property var app
    property bool past: false
    readonly property var win: Timeline.window_(app.nowTick, past)
    readonly property var groups: Timeline.group(app.expandEvents(app.eventsFiltered(), win[0], win[1]).filter(function (o) { return o.startTime >= tv.win[0] && o.startTime < tv.win[1] }), past)
    spacing: 8
    Flow {
        Layout.fillWidth: true; spacing: 6
        Chip { text: "Coming up"; on: !tv.past; onClicked: tv.past = false }
        Chip { text: "Past"; on: tv.past; onClicked: tv.past = true }
    }
    Flickable {
        id: fl
        objectName: "timelineFlick"
        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
        contentWidth: width; contentHeight: col.implicitHeight + 20
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        ColumnLayout {
            id: col
            width: fl.width - 12; spacing: 8
            FText { visible: tv.groups.length === 0; text: tv.past ? "No past events in the last year." : "Nothing coming up yet."; color: Fq.sub; font.pixelSize: 14 }
            Repeater {
                model: tv.groups
                delegate: ColumnLayout {
                    id: grp
                    required property var modelData
                    Layout.fillWidth: true; spacing: 8
                    RowLayout {
                        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 12
                        DText { text: Qt.formatDate(new Date(grp.modelData.first), "MMMM yyyy").toUpperCase(); color: Fq.lime; font.pixelSize: 34 }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Fq.line }
                        FText { text: grp.modelData.occs.length + (grp.modelData.occs.length === 1 ? " event" : " events"); color: Fq.faint; font.pixelSize: 12 }
                    }
                    Repeater {
                        model: grp.modelData.occs
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            readonly property var m: tv.app.eventById(modelData.seriesId) || modelData
                            readonly property var t: Tickets.ticketsOf(m)
                            readonly property string poster: tv.app.posterSrc(m)
                            readonly property int open: Checklist.openCount(m)
                            readonly property bool clash: tv.app.clashMark(modelData) !== ""
                            Layout.fillWidth: true; Layout.preferredHeight: Math.max(112, rr.implicitHeight + 24)
                            color: rm.containsMouse ? Fq.surface : Fq.mantle; border.width: 1; border.color: Fq.line
                            Rectangle { width: 5; height: parent.height; color: tv.app.evColor(row.modelData) }
                            MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tv.app.openNight(row.modelData) }
                            RowLayout {
                                id: rr
                                x: 20; y: 12; width: parent.width - 34; spacing: 18
                                ColumnLayout {
                                    Layout.preferredWidth: 104; Layout.alignment: Qt.AlignTop; spacing: -6
                                    DText { text: Qt.formatDate(new Date(row.modelData.startTime), "dd.MM"); font.pixelSize: 50 }
                                    FText { text: Qt.formatDate(new Date(row.modelData.startTime), "dddd").toUpperCase(); color: Fq.sub; font.pixelSize: 12; font.letterSpacing: 1.2 }
                                }
                                Rectangle {
                                    visible: row.poster !== ""; Layout.preferredWidth: 70; Layout.preferredHeight: 88; Layout.alignment: Qt.AlignTop
                                    color: Fq.ground; border.width: 1; border.color: Fq.line
                                    Image { anchors.fill: parent; anchors.margins: 1; source: row.poster; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 160 }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        DText { Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 26; text: (row.modelData.title || "(untitled)").toUpperCase()
                                                font.strikeout: Nights.fieldOf(row.m, "status") === "Cancelled" }
                                        Badge { visible: Nights.fieldOf(row.m, "status") !== ""; text: Nights.fieldOf(row.m, "status"); tone: tv.app.evColor(row.modelData) }
                                    }
                                    FText { Layout.fillWidth: true; elide: Text.ElideRight; color: Fq.sub; font.pixelSize: 13
                                        text: [row.modelData.allDay ? "all day" : Qt.formatTime(new Date(row.modelData.startTime), "hh:mm") + "–" + Qt.formatTime(new Date(row.modelData.endTime), "hh:mm"),
                                               Nights.fieldOf(row.m, "venue"), Nights.fieldOf(row.m, "type"), tv.app.calName(row.m.calendarId)].filter(function (x) { return !!x }).join("  ·  ") }
                                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13; visible: text !== ""
                                        text: { var lu = Lineup.lineupOf(row.m).filter(function (b) { return b.status !== "cancelled" }); return lu.length ? "(( " + lu.map(function (b) { return b.name }).join("  ·  ") + " ))" : "" } }
                                    FText { Layout.fillWidth: true; elide: Text.ElideRight; color: Fq.signal; font.pixelSize: 12; visible: text !== ""
                                        text: Tags.tagsOf(row.m).map(function (x) { return "#" + x }).join("  ") }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14; visible: !!row.t || row.open > 0 || row.clash
                                        Rectangle { visible: Tickets.soldShare(row.t) > 0; Layout.preferredWidth: 120; height: 6; color: Fq.surface2
                                            Rectangle { height: parent.height; width: parent.width * Tickets.soldShare(row.t); color: Fq.lime } }
                                        FText { visible: !!row.t; text: Tickets.line(row.t); color: Fq.sub; font.pixelSize: 12 }
                                        FText { visible: row.open > 0; text: row.open + " open task" + (row.open === 1 ? "" : "s"); color: Fq.sub; font.pixelSize: 12 }
                                        FText { visible: row.clash; text: "⚠ clash"; color: Fq.warn; font.pixelSize: 12 }
                                        Item { Layout.fillWidth: true }
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
