// A night as a card on the month and week grids (#6): colour bar (colour-by), time, title, ⚠ on a
// clash, struck through when cancelled. Compact = one line for month cells. Click opens the night;
// drag it onto another day to move it (#7: Scala's own dragProxy + moveEventToDay).
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
        FText { text: nc.occ && !nc.occ.allDay ? Fq.fmtTime(new Date(nc.occ.startTime), "hh:mm") : ""; color: Fq.sub; font.pixelSize: 12 }
        FText { text: (nc.clash ? "⚠ " : "") + (nc.occ ? (nc.occ.title || Fq.t("(untitled)")) : ""); color: nc.clash ? Fq.warn : Fq.text; font.pixelSize: 12
                font.strikeout: nc.status === "Cancelled" }
    }
    Image {   // poster thumbnail (#15) on full cards wide enough for it
        id: thumb
        readonly property string src: nc.compact ? "" : nc.app.posterSrc(nc.app.eventById(nc.occ ? nc.occ.seriesId : ""))
        visible: src !== "" && status === Image.Ready && nc.width >= 160
        source: src; asynchronous: true; fillMode: Image.PreserveAspectCrop; sourceSize.width: 80
        width: visible ? 34 : 0; height: 42; x: parent.width - width - 4; anchors.verticalCenter: parent.verticalCenter
    }
    Column {
        id: col
        visible: !nc.compact
        x: 10; width: parent.width - 14 - thumb.width; anchors.verticalCenter: parent.verticalCenter; spacing: 1
        FText { width: parent.width; elide: Text.ElideRight; wrapMode: Text.Wrap; maximumLineCount: 2; font.pixelSize: 13
                text: nc.occ ? (nc.occ.title || Fq.t("(untitled)")) : ""; font.strikeout: nc.status === "Cancelled" }
        FText { width: parent.width; elide: Text.ElideRight; font.pixelSize: 12; color: nc.clash ? Fq.warn : Fq.sub
                text: nc.occ ? [(nc.clash ? "⚠ " : "") + (nc.occ.allDay ? Fq.t("All day") : Fq.fmtTime(new Date(nc.occ.startTime), "hh:mm")),
                                Nights.fieldOf(nc.occ, "venue"), nc.status].filter(function (x) { return !!x }).join(" · ") : "" }
    }
    opacity: ma.dragging ? 0.35 : 1
    MouseArea {
        id: ma
        anchors.fill: parent; hoverEnabled: true; preventStealing: true
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        property bool dragging: false; property real px: 0; property real py: 0
        onPressed: function (m) { px = m.x; py = m.y; dragging = false }
        onPositionChanged: function (m) {
            if (!pressed) return
            if (!dragging && (Math.abs(m.x - px) + Math.abs(m.y - py)) < 8) return
            var proxy = nc.app.dragProxyItem
            if (!dragging) { dragging = true; proxy.dragEv = nc.occ; proxy.visible = true }
            var gp = mapToItem(nc.app, m.x, m.y)
            proxy.x = gp.x - proxy.width / 2; proxy.y = gp.y - proxy.height / 2
        }
        onReleased: function (m) {
            var proxy = nc.app.dragProxyItem
            if (dragging) { proxy.Drag.drop(); proxy.visible = false; proxy.dragEv = null; dragging = false }
            else { nc.opened(); nc.app.openNight(nc.occ) }
        }
        onCanceled: { var proxy = nc.app.dragProxyItem; proxy.visible = false; proxy.dragEv = null; dragging = false }
    }
}
