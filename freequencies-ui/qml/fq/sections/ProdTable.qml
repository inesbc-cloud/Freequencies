// One production table (timeline, venue checks, run of show, risks…): rows as cards, tap to edit,
// checkboxes and statuses at a glance. Every co-organiser can edit any row.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/production.js" as Production

ColumnLayout {
    id: pt
    property var app
    property var night
    property var plan
    property string table: ""
    property bool canEdit: false
    signal editRow(string table, var row)      // row null = add
    readonly property var def: Production.tableDef(plan, table)
    readonly property var rows: night && table ? Production.rowsOf(night, table) : []
    readonly property var checkCol: def ? def.cols.filter(function (c) { return c.type === "check" })[0] : null
    Layout.fillWidth: true; spacing: 6

    function cellText(c, v) {
        if (v === undefined || v === null || v === "") return ""
        if (c.type === "check") return ""
        if (c.type === "money") return String(v) + " EUR"
        if (c.type === "tminus") return Production.tLabel(v)
        return String(v)
    }
    function mainCol() { var cs = def ? def.cols.filter(function (c) { return c.type === "long" || c.type === "text" }) : []; return cs.length ? cs[0] : null }

    Sec { label: pt.def ? Fq.t(pt.def.t) + " (" + pt.rows.length + ")" : ""; action: pt.canEdit ? Fq.t("+ row") : ""; onAct: pt.editRow(pt.table, null) }
    FText { visible: !!pt.def && pt.def.lead !== ""; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 12; text: pt.def ? Fq.t(pt.def.lead) : "" }
    FText { visible: pt.rows.length === 0; color: Fq.sub; font.pixelSize: 12; text: Fq.t("Nothing here yet.") }

    Repeater {
        model: pt.rows
        delegate: Rectangle {
            id: rw
            required property var modelData
            readonly property var c: modelData.cells
            readonly property var mc: pt.mainCol()
            readonly property bool done: Production.rowDone(c) === true
            readonly property double due: pt.table === "milestones" ? Production.dueOf(pt.night, c.t) : 0
            readonly property bool late: pt.table === "milestones" && !done && due > 0 && due < pt.app.nowTick
            readonly property int risk: pt.table === "risks" ? Production.riskScore(c) : 0
            Layout.fillWidth: true; Layout.preferredHeight: rc.implicitHeight + 14
            color: rwMA.containsMouse ? Fq.surface : "transparent"; border.width: 1; border.color: Fq.line
            opacity: done ? 0.65 : 1
            MouseArea { id: rwMA; anchors.fill: parent; hoverEnabled: true; cursorShape: pt.canEdit ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (pt.canEdit) pt.editRow(pt.table, rw.modelData) }
            RowLayout {
                id: rc
                x: 10; y: 7; width: parent.width - 20; spacing: 10
                Rectangle {   // the row's checkbox, when it has one
                    visible: !!pt.checkCol; Layout.preferredWidth: 16; Layout.preferredHeight: 16; Layout.alignment: Qt.AlignTop; Layout.topMargin: 2
                    color: rw.c[pt.checkCol ? pt.checkCol.k : ""] === true ? Fq.lime : "transparent"; border.width: 1; border.color: Fq.sub
                    FText { anchors.centerIn: parent; visible: parent.color === Fq.lime; text: "✓"; color: Fq.ink; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; anchors.margins: -4; enabled: pt.canEdit; cursorShape: Qt.PointingHandCursor
                        onClicked: { var n = {}; for (var k in rw.c) n[k] = rw.c[k]; n[pt.checkCol.k] = !(rw.c[pt.checkCol.k] === true); pt.app.saveRow(pt.night, pt.table, rw.modelData, n) } }
                }
                FText {   // milestones: T-label and the real date
                    visible: pt.table === "milestones"; Layout.preferredWidth: 96; Layout.alignment: Qt.AlignTop; font.pixelSize: 12
                    color: rw.late ? Fq.red : Fq.acid
                    text: Fq.t(Production.tLabel(rw.c.t)) + (rw.due ? Fq.t("\n") + Fq.fmtDate(new Date(rw.due), "ddd d MMM") : "")
                }
                FText { visible: pt.table === "ros"; Layout.preferredWidth: 52; Layout.alignment: Qt.AlignTop; font.pixelSize: 14; font.bold: true; color: Fq.acid; text: rw.c.time || "" }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13; textFormat: Text.PlainText; font.strikeout: rw.done && !!pt.checkCol
                        text: rw.mc ? (rw.c[rw.mc.k] || Fq.t("(empty)")) : "" }
                    FText {
                        Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText
                        readonly property string line: pt.def ? pt.def.cols.filter(function (cc) {
                            return cc !== rw.mc && cc.type !== "check" && cc.type !== "tminus" && !(pt.table === "ros" && cc.k === "time") && !(pt.table === "risks" && (cc.k === "l" || cc.k === "i")) && pt.cellText(cc, rw.c[cc.k]) !== ""
                        }).map(function (cc) { return (cc.type === "select" || cc.type === "text" && cc.k === "owner" ? "" : Fq.t(cc.l) + ": ") + (cc.type === "select" ? Fq.t(pt.cellText(cc, rw.c[cc.k])) : pt.cellText(cc, rw.c[cc.k])) }).join("  ·  ") : ""
                        visible: line !== ""; text: line
                    }
                }
                Link { visible: pt.table === "debrief" && !!pt.app.networkAnchor && (!!rw.c.worked || !!rw.c.change); Layout.alignment: Qt.AlignTop
                    text: Fq.t("share with Lisboa"); onClicked: pt.app.shareLesson(pt.night, rw.modelData) }
                Badge { visible: pt.table === "risks" && rw.risk > 0; Layout.alignment: Qt.AlignTop; text: Fq.t("risk ") + rw.risk + " (" + rw.c.l + "×" + rw.c.i + ")"
                    tone: rw.risk >= 6 ? Fq.red : rw.risk >= 3 ? Fq.warn : Fq.faint }
            }
        }
    }
}
