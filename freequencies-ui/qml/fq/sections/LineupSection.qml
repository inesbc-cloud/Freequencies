// The line-up (#10, ADR 0004): artists from Kith, with status, set time and fee.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/lineup.js" as Lineup

ColumnLayout {
    id: ls
    property var app
    property var night
    property bool canEdit: false
    signal editArtist(var booking)         // null = add
    readonly property var lineup: Lineup.lineupOf(night)
    Layout.fillWidth: true; spacing: 6

    Sec { label: Fq.t("Line-up (") + ls.lineup.length + ")"; action: Fq.t("+ artist"); onAct: ls.editArtist(null) }
    FText { visible: ls.lineup.length === 0; text: Fq.t("No artists yet."); color: Fq.sub; font.pixelSize: 12 }
    Repeater {
        model: ls.lineup
        delegate: Rectangle {
            id: bk
            required property var modelData
            required property int index
            Layout.fillWidth: true; Layout.preferredHeight: bkCol.implicitHeight + 12
            color: bkMA.containsMouse ? Fq.surface : "transparent"; border.width: 1; border.color: Fq.line
            MouseArea { id: bkMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ls.editArtist(bk.modelData) }
            Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; color: ls.app.bookingColor(bk.modelData.status) }
            Column {
                id: bkCol
                x: 24; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 32; spacing: -2
                Row {
                    spacing: 6
                    FText { visible: bk.index % 2 === 0; text: "(("; color: Fq.bracket; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    DText { text: ls.app.kithName(bk.modelData).toUpperCase(); size: 24; color: bk.modelData.status === "cancelled" ? Fq.sub : Fq.text
                            font.strikeout: bk.modelData.status === "cancelled" }
                    FText { visible: bk.index % 2 === 1; text: "))"; color: Fq.bracket; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
                FText { width: parent.width; elide: Text.ElideRight; color: Fq.sub; font.pixelSize: 12
                    text: [bk.modelData.set, Fq.t(Lineup.cap(bk.modelData.status)), Lineup.feeLabel(bk.modelData), bk.modelData.contact ? "" : Fq.t("not in Kith")].filter(function (x) { return !!x }).join(" · ") }
            }
        }
    }
    FText { visible: Lineup.feesTotal(ls.lineup) !== ""; text: Fq.t("Fees: ") + Lineup.feesTotal(ls.lineup); color: Fq.sub; font.pixelSize: 12 }
}
