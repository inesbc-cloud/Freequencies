// Deal calculator: the artist's deal against ticket price × capacity and the costs. Live table at
// 25/50/75/100% full and the break-even point. Save it on the event, or turn it into budget lines.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/deal.js" as Deal
import "../lib/money.js" as Money
import "../lib/ext.js" as Ext

Win {
    id: dp
    objectName: "dealPopup"
    property var app
    property var night: null                 // null = a quick calculation, not tied to an event
    property string type: "flat"
    property int fillIx: 2                   // the fill used for budget lines (75%)
    property var costRows: [{ label: "", amount: "" }, { label: "", amount: "" }, { label: "", amount: "" }]
    readonly property var parsed: Deal.parse({ type: type, fee: feeIn.text, pct: pctIn.text, price: priceIn.text, capacity: capIn.text, other: otherIn.text, costs: costRows })
    readonly property var d: parsed.data || null
    readonly property var rows: d ? Deal.table(d) : []
    readonly property var be: d ? Deal.breakEven(d) : null
    title: "deal_calculator.exe"
    width: Math.min(620, (parent ? parent.width : 620) - 40)
    function m(n) { return Money.money(n, "EUR") }

    function openFor(n) {
        night = n || null
        var s = n ? (Ext.latestData(n, "deal") || {}) : {}
        type = Deal.TYPES.indexOf(s.type) >= 0 ? s.type : "flat"
        feeIn.text = s.fee ? String(s.fee) : ""; pctIn.text = s.pct ? String(s.pct) : ""
        priceIn.text = s.price ? String(s.price) : ""; capIn.text = s.capacity ? String(s.capacity) : ""; otherIn.text = s.other ? String(s.other) : ""
        var cs = (s.costs || []).map(function (c) { return { label: c.label, amount: String(c.amount) } })
        while (cs.length < 3) cs.push({ label: "", amount: "" })
        costRows = cs
        open()
    }
    function setCost(i, k, v) { var c = costRows.slice(); c[i] = { label: k === "label" ? v : c[i].label, amount: k === "amount" ? v : c[i].amount }; costRows = c }

    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(body.implicitHeight, (dp.parent ? dp.parent.height : 800) - 170)
        contentWidth: availableWidth; clip: true
        ColumnLayout {
            id: body
            width: parent.width; spacing: 7
            Label_ { text: Fq.t("THE DEAL") }
            Flow { Layout.fillWidth: true; spacing: 6
                Repeater { model: Deal.TYPES
                    delegate: Chip { required property var modelData; text: Fq.t(Deal.LABELS[modelData]); on: dp.type === modelData; onClicked: dp.type = modelData } } }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout { visible: dp.type !== "door"; Layout.fillWidth: true; spacing: 4
                    Label_ { text: dp.type === "flat" ? Fq.t("FEE") : Fq.t("GUARANTEE") } Field { id: feeIn; Layout.fillWidth: true; placeholderText: "300" } }
                ColumnLayout { visible: dp.type !== "flat"; Layout.preferredWidth: 110; spacing: 4
                    Label_ { text: dp.type === "door" ? Fq.t("% OF THE DOOR") : Fq.t("% AFTER COSTS") } Field { id: pctIn; Layout.fillWidth: true; placeholderText: "70" } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: Fq.t("TICKET PRICE") } Field { id: priceIn; Layout.fillWidth: true; placeholderText: "10" } }
                ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: Fq.t("CAPACITY") } Field { id: capIn; Layout.fillWidth: true; placeholderText: "200" } }
                ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: Fq.t("OTHER INCOME") } Field { id: otherIn; Layout.fillWidth: true; placeholderText: "0" } }
            }
            Label_ { text: Fq.t("COSTS (VENUE, SOUND, PROMO, STAFF…)") }
            Repeater {
                model: dp.costRows.length
                delegate: RowLayout { required property int index; Layout.fillWidth: true; spacing: 8
                    Field { Layout.fillWidth: true; text: dp.costRows[index].label; placeholderText: Fq.t("What"); onTextEdited: dp.setCost(index, "label", text) }
                    Field { Layout.preferredWidth: 110; text: dp.costRows[index].amount; placeholderText: "0"; onTextEdited: dp.setCost(index, "amount", text) } }
            }
            Link { visible: dp.costRows.length < 8; text: Fq.t("+ cost"); onClicked: dp.costRows = dp.costRows.concat([{ label: "", amount: "" }]) }

            FText { visible: !!dp.parsed.error; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.warn; font.pixelSize: 12; text: Fq.t(dp.parsed.error || "") }
            // the table
            GridLayout {
                visible: !!dp.d; Layout.fillWidth: true; Layout.topMargin: 6; columns: 5; columnSpacing: 12; rowSpacing: 4
                Label_ { text: Fq.t("FULL") } Label_ { text: Fq.t("TICKETS") } Label_ { text: Fq.t("DOOR") } Label_ { text: Fq.t("ARTIST") } Label_ { text: Fq.t("YOU") }
                Repeater {
                    model: dp.rows.length * 5
                    delegate: FText {
                        required property int index
                        readonly property var r: dp.rows[Math.floor(index / 5)]
                        readonly property int c: index % 5
                        font.pixelSize: 13; font.bold: Math.floor(index / 5) === dp.fillIx
                        color: c === 4 ? (r.promoter < 0 ? Fq.red : Fq.lime) : Fq.text
                        text: c === 0 ? Math.round(r.fill * 100) + "%" : c === 1 ? String(r.tickets) : c === 2 ? dp.m(r.door) : c === 3 ? dp.m(r.artist) : dp.m(r.promoter)
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dp.fillIx = Math.floor(index / 5) }
                    }
                }
            }
            FText { visible: !!dp.d; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13
                text: dp.be === null ? Fq.t("At this price and capacity you don't break even.") : Fq.t("You break even at %1 tickets (%2% full).", [dp.be, dp.d && dp.d.capacity ? Math.round(100 * dp.be / dp.d.capacity) : 0]) }
            FText { visible: !!dp.d; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 11
                text: Fq.t("Tap a row to pick the fill used when you add it to the budget.") }
        }
    }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        Item { Layout.fillWidth: true }
        FqButton { text: Fq.t("Close"); onClicked: dp.close() }
        FqButton { visible: !!dp.night; enabled: !!dp.d; text: Fq.t("Add to budget"); onClicked: dp.app.addDealToBudget(dp.night, dp.d, Deal.FILLS[dp.fillIx]) }
        FqButton { visible: !!dp.night; enabled: !!dp.d; primary: true; text: Fq.t("Save on the event"); onClicked: { dp.app.putLatest(dp.night, "deal", dp.d, Fq.t("Deal saved")); dp.close() } }
    }
}
