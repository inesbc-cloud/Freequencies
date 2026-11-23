// The poster (#15): shown at the top of the panel, on week/board cards and in the timeline.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/poster.js" as Poster

ColumnLayout {
    id: ps
    property var app
    property var night
    property bool canEdit: false
    signal change()
    Layout.fillWidth: true; spacing: 6
    Sec { label: "Poster"; action: ps.canEdit ? (Poster.posterOf(ps.night) ? "change" : "+ set") : ""; onAct: ps.change() }
    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: Poster.posterOf(ps.night) ? (ps.app.posterSrc(ps.night) ? "Shows on the calendar, the timeline and at the top of this panel." : "Fetching it from Logos Storage…")
              : "Pick an image file attached to the event, or paste an image link." }
}
