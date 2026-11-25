// Co-promotion: partners and their shares; after the event, who paid what, who holds the money,
// and the fewest transfers to settle. One record per event (ext kind "copro", newest wins).
import QtQuick
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/deal.js" as Deal
import "../lib/money.js" as Money
import "../lib/ext.js" as Ext

ColumnLayout {
    id: cs
    property var app
    property var night
    property bool canEdit: false
    readonly property var c: Ext.latestData(night, "copro") || ({ partners: [], moves: [], settled: false })
    readonly property var s: Deal.settle(c)
    property string moveKind: "paid"
    property string moveWho: ""
    property bool expanded: false
    readonly property bool active: c.partners.length > 0 || expanded
    Layout.fillWidth: true; spacing: 6
    function m(n) { return Money.money(n, "EUR") }
    function save(next, msg) { cs.app.putLatest(cs.night, "copro", next, msg || Fq.t("Saved")) }
    function copy() { return JSON.parse(JSON.stringify(c)) }

    Link { visible: !cs.active && cs.canEdit; Layout.topMargin: 6; text: Fq.t("Organising with partners? + co-promotion"); onClicked: cs.expanded = true }
    Sec { visible: cs.active; label: Fq.t("Co-promotion") }
    FText { visible: cs.active && cs.c.partners.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: Fq.t("Organising with other collectives or the venue? Add each partner and their share of the result. After the event, note who paid costs and who holds the money, and Freequencies works out who owes whom.") }

    // partners
    Repeater {
        model: cs.c.partners
        delegate: RowLayout {
            required property var modelData
            required property int index
            Layout.fillWidth: true; spacing: 8
            FText { Layout.fillWidth: true; font.pixelSize: 13; textFormat: Text.PlainText; text: modelData.name }
            FText { font.pixelSize: 13; color: Fq.sub; text: (modelData.share || 0) + "%" }
            Link { visible: cs.canEdit; text: Fq.t("remove"); tone: Fq.red; onClicked: { var n = cs.copy(); n.partners.splice(index, 1); cs.save(n) } }
        }
    }
    RowLayout {
        visible: cs.canEdit && cs.active; Layout.fillWidth: true; spacing: 6
        Field { id: pName; Layout.fillWidth: true; placeholderText: Fq.t("Partner (collective, venue…)") }
        Field { id: pShare; Layout.preferredWidth: 70; placeholderText: "50" }
        FqButton { text: Fq.t("+ partner"); onClicked: {
            var nm = pName.text.trim(), sh = Number(pShare.text.replace(",", "."))
            if (!nm || !(isFinite(sh) && sh >= 0 && sh <= 100)) { cs.app.notify(Fq.t("A name and a share between 0 and 100."), true); return }
            var n = cs.copy(); n.partners = (n.partners || []).concat([{ name: nm, share: sh }]); cs.save(n); pName.text = ""; pShare.text = "" } }
    }
    FText { visible: cs.c.partners.length > 0 && !cs.s.sharesOk; color: Fq.warn; font.pixelSize: 12
        text: Fq.t("Shares add up to %1%, not 100%.", [Math.round(cs.s.totalShare * 100) / 100]) }

    // money moves
    ColumnLayout {
        visible: cs.c.partners.length > 0; Layout.fillWidth: true; spacing: 4; Layout.topMargin: 6
        Label_ { text: Fq.t("WHO PAID OR HOLDS WHAT") }
        Repeater {
            model: cs.c.moves || []
            delegate: RowLayout { required property var modelData; required property int index; Layout.fillWidth: true; spacing: 8
                FText { Layout.fillWidth: true; font.pixelSize: 12; textFormat: Text.PlainText; elide: Text.ElideRight
                    text: modelData.who + " · " + (modelData.kind === "took" ? Fq.t("holds") : Fq.t("paid")) + (modelData.label ? " · " + modelData.label : "") }
                FText { font.pixelSize: 12; text: cs.m(Number(modelData.amount) || 0) }
                Link { visible: cs.canEdit; text: "×"; tone: Fq.red; onClicked: { var n = cs.copy(); n.moves.splice(index, 1); cs.save(n) } } }
        }
        Flow { visible: cs.canEdit; Layout.fillWidth: true; spacing: 6
            Repeater { model: cs.c.partners
                delegate: Chip { required property var modelData; text: modelData.name; on: cs.moveWho === modelData.name; onClicked: cs.moveWho = modelData.name } }
            Item { width: 8; height: 1 }
            Chip { text: Fq.t("paid a cost"); on: cs.moveKind === "paid"; onClicked: cs.moveKind = "paid" }
            Chip { text: Fq.t("holds income"); on: cs.moveKind === "took"; onClicked: cs.moveKind = "took" } }
        RowLayout { visible: cs.canEdit; Layout.fillWidth: true; spacing: 6
            Field { id: mLabel; Layout.fillWidth: true; placeholderText: Fq.t("What (sound, door cash…)") }
            Field { id: mAmount; Layout.preferredWidth: 90; placeholderText: "0" }
            FqButton { text: Fq.t("+ add"); onClicked: {
                var a = Number(mAmount.text.replace(",", "."))
                if (!cs.moveWho || !(isFinite(a) && a > 0)) { cs.app.notify(Fq.t("Pick the partner and an amount."), true); return }
                var n = cs.copy(); n.moves = (n.moves || []).concat([{ who: cs.moveWho, kind: cs.moveKind, label: mLabel.text.trim(), amount: a }]); cs.save(n); mLabel.text = ""; mAmount.text = "" } } }
    }

    // the settlement
    ColumnLayout {
        visible: (cs.c.moves || []).length > 0 && cs.s.sharesOk; Layout.fillWidth: true; spacing: 3; Layout.topMargin: 6
        Label_ { text: Fq.t("SETTLEMENT") }
        FText { font.pixelSize: 13; text: Fq.t("Income %1 − costs %2 = %3", [cs.m(cs.s.income), cs.m(cs.s.costs), cs.m(cs.s.result)]) }
        Repeater { model: cs.s.transfers
            delegate: FText { required property var modelData; font.pixelSize: 14; font.bold: true; color: cs.c.settled ? Fq.faint : Fq.lime; textFormat: Text.PlainText
                text: Fq.t("%1 pays %2 to %3", [modelData.from, cs.m(modelData.amount), modelData.to]) } }
        FText { visible: cs.s.transfers.length === 0; font.pixelSize: 13; color: Fq.sub; text: Fq.t("Nobody owes anything.") }
        RowLayout { spacing: 12
            Chip { enabled_: cs.canEdit; text: cs.c.settled ? Fq.t("Settled ✓") : Fq.t("Mark as settled"); on: cs.c.settled === true
                onClicked: { var n = cs.copy(); n.settled = !(cs.c.settled === true); cs.save(n, n.settled ? Fq.t("Settled") : Fq.t("Saved")) } }
            Link { text: Fq.t("copy the sheet"); onClicked: cs.app.copyText(cs.s.transfers.map(function (t) { return Fq.t("%1 pays %2 to %3", [t.from, cs.m(t.amount), t.to]) }).join("\n")) } }
    }
}
