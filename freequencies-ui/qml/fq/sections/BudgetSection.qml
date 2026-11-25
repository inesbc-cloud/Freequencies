// Budget (#18): income and costs; the line-up's fees and ticket sales count by themselves.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/money.js" as Money

ColumnLayout {
    id: bs
    property var app
    property var night
    property bool canEdit: false
    signal editLine(var line)               // null = add
    readonly property var mo: Money.moneyOf(night)
    Layout.fillWidth: true; spacing: 0

    Sec { label: Fq.t("Budget"); action: bs.canEdit ? Fq.t("+ line") : ""; onAct: bs.editLine(null); Layout.bottomMargin: 6 }
    Repeater {
        model: Money.linesOf(bs.night)
        delegate: Rectangle {
            id: bl
            required property var modelData
            Layout.fillWidth: true; Layout.preferredHeight: 30; color: blm.containsMouse ? Fq.surface : "transparent"
            MouseArea { id: blm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bs.editLine(bl.modelData) }
            FText { x: 6; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 130; elide: Text.ElideRight; text: bl.modelData.d.label || ""; font.pixelSize: 13 }
            FText { anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13
                text: (bl.modelData.d.dir === "in" ? "+ " : "− ") + Money.money(bl.modelData.d.amount || 0, bl.modelData.d.currency)
                color: bl.modelData.d.dir === "in" ? Fq.lime : Fq.text }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fq.line }
        }
    }
    Repeater {
        model: [{ l: Fq.t("Artist fees (line-up)"), v: bs.mo.fees, dir: "out" }, { l: Fq.t("Ticket sales"), v: bs.mo.tickets, dir: "in" }].filter(function (x) { return x.v > 0 })
        delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true; Layout.preferredHeight: 30; color: "transparent"
            FText { x: 6; anchors.verticalCenter: parent.verticalCenter; text: Fq.t(modelData.l); color: Fq.sub; font.pixelSize: 13; font.italic: true }
            FText { anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13
                text: (modelData.dir === "in" ? "+ " : "− ") + Money.money(modelData.v, bs.mo.cur); color: modelData.dir === "in" ? Fq.lime : Fq.text }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Fq.line }
        }
    }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 6
        Repeater {
            model: [{ l: Fq.t("In"), v: bs.mo.income }, { l: Fq.t("Out"), v: bs.mo.costs }, { l: Fq.t("Result"), v: bs.mo.profit }]
            delegate: Rectangle {
                required property var modelData
                readonly property bool result: modelData.l === "Result"
                Layout.fillWidth: true; Layout.preferredHeight: 52; color: "transparent"; border.width: 1
                border.color: result ? (modelData.v >= 0 ? Fq.lime : Fq.red) : Fq.line
                Column { x: 8; anchors.verticalCenter: parent.verticalCenter; spacing: -3
                    FText { text: Fq.t(modelData.l).toUpperCase(); color: Fq.faint; font.pixelSize: 12; font.letterSpacing: 1.2 }
                    DText { text: Money.money(modelData.v, bs.mo.cur); size: 22; color: parent.parent.result ? (modelData.v >= 0 ? Fq.lime : Fq.red) : Fq.text } }
            }
        }
    }
}
