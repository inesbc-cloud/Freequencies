// A night as a card on the month and week grids (#6): colour bar (colour-by), time, title, ⚠ on a
// clash, struck through when cancelled. Compact = one line for month cells. Click opens the night.
import QtQuick
import "lib/nights.js" as Nights

Rectangle {
    id: nc
    property var app                        // FreequenciesView root
    property var occ: null                  // an occurrence (expandEvents)
    property bool compact: false
    readonly property string status: Nights.fieldOf(occ, "status")
    readonly property bool clash: !!occ && app.clashMark(occ) !== ""
    readonly property bool isSel: !!occ && !!app.selectedNight && app.selectedNight.seriesId === occ.seriesId && app.selectedNight.occ === occ.occ
    signal opened()

    height: compact ? 22 : Math.max(44, col.implicitHeight + 10)
    color: isSel ? Fq.surface2 : (ma.containsMouse ? Fq.surface : Fq.mantle)
    border.width: 1; border.color: isSel ? Fq.lime : Fq.line
    Rectangle { width: 4; height: parent.height; color: nc.occ ? nc.app.evColor(nc.occ) : "transparent" }

    Row {
        visible: nc.compact
        x: 8; width: parent.width - 12; anchors.verticalCenter: parent.verticalCenter; spacing: 5; clip: true
        FText { text: nc.occ && !nc.occ.allDay ? Qt.formatTime(new Date(nc.occ.startTime), "hh:mm") : ""; color: Fq.sub; font.pixelSize: 12 }
        FText { text: (nc.clash ? "⚠ " : "") + (nc.occ ? (nc.occ.title || "(untitled)") : ""); color: nc.clash ? Fq.warn : Fq.text; font.pixelSize: 12
                font.strikeout: nc.status === "Cancelled" }
    }
    Column {
        id: col
        visible: !nc.compact
        x: 10; width: parent.width - 14; anchors.verticalCenter: parent.verticalCenter; spacing: 1
        FText { width: parent.width; elide: Text.ElideRight; wrapMode: Text.Wrap; maximumLineCount: 2; font.pixelSize: 13
                text: nc.occ ? (nc.occ.title || "(untitled)") : ""; font.strikeout: nc.status === "Cancelled" }
        FText { width: parent.width; elide: Text.ElideRight; font.pixelSize: 12; color: nc.clash ? Fq.warn : Fq.sub
                text: nc.occ ? [(nc.clash ? "⚠ " : "") + (nc.occ.allDay ? "All day" : Qt.formatTime(new Date(nc.occ.startTime), "hh:mm")),
                                Nights.fieldOf(nc.occ, "venue"), nc.status].filter(function (x) { return !!x }).join(" · ") : "" }
    }
    MouseArea {
        id: ma
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: { nc.opened(); nc.app.openNight(nc.occ) }
    }
}
