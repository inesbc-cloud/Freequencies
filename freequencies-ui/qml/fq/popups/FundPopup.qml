// Add or change an entry in the funding library: a winning application (with documents) or a
// link to a funder / open call. Documents upload to Logos Storage, sealed with the library's key.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import ".."
import "../.."
import "../lib/funding.js" as Funding
import "../lib/ext.js" as Ext

Win {
    id: fp
    objectName: "fundPopup"
    property var app
    property string kind: "fund-app"       // "fund-app" | "fund-link"
    property string id_: ""
    property string area: ""
    property bool rolling: false
    property var docs: []                  // documents already on the entry
    readonly property var allDocs: docs.concat(app ? app.fundUploaded : [])
    title: (id_ ? "" : "new_") + (kind === "fund-app" ? "winning_application" : "funding_link") + ".exe"
    width: Math.min(560, (parent ? parent.width : 560) - 40)

    function openFor(k, it) {
        kind = k; id_ = it ? it.id : ""
        var d = it ? it.d : {}
        app.fundUploaded = []
        area = d.area || ""; rolling = d.rolling === true
        docs = Array.isArray(d.docs) ? d.docs.slice() : []
        titleIn.text = d.title || d.name || ""
        funderIn.text = d.funder || ""; yearIn.text = d.year ? String(d.year) : ""
        amountIn.text = k === "fund-app" ? (typeof d.amount === "number" ? String(d.amount) : "") : (d.amount || "")
        curIn.text = d.currency || "EUR"; applicantIn.text = d.applicant || ""
        urlIn.text = d.url || ""; deadlineIn.text = d.deadline || ""; notesIn.text = d.notes || ""
        open(); titleIn.forceActiveFocus()
    }
    function removeDoc(cid) {
        docs = docs.filter(function (x) { return x.cid !== cid })
        app.fundUploaded = app.fundUploaded.filter(function (x) { return x.cid !== cid })
    }
    function save() {
        var r = kind === "fund-app"
            ? Funding.appData({ title: titleIn.text, funder: funderIn.text, year: yearIn.text, amount: amountIn.text, currency: curIn.text,
                                area: area, applicant: applicantIn.text, notes: notesIn.text, url: urlIn.text, docs: allDocs })
            : Funding.linkData({ name: titleIn.text, url: urlIn.text, deadline: deadlineIn.text, amount: amountIn.text, area: area,
                                 rolling: rolling, notes: notesIn.text })
        if (r.error) { app.notify(r.error, true); return }
        app.postFunding(Ext.item(kind, "", r.data, id_ || (kind + ":" + Ext.rnd())), id_ ? "Updated" : "Added to the library",
                        function (ok) { if (ok) { app.fundUploaded = []; fp.close() } })
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(body.implicitHeight, (fp.parent ? fp.parent.height : 800) - 170)
        contentWidth: availableWidth; clip: true
        ColumnLayout {
            id: body
            width: parent.width; spacing: 7

            Label_ { text: fp.kind === "fund-app" ? "PROJECT THAT WAS FUNDED" : "FUNDER OR CALL" }
            Field { id: titleIn; Layout.fillWidth: true; placeholderText: fp.kind === "fund-app" ? "e.g. Noites Abertas 2025" : "e.g. DGArtes Apoio a Projetos" }

            ColumnLayout {
                visible: fp.kind === "fund-app"; Layout.fillWidth: true; spacing: 7
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: "FUNDED BY" } Field { id: funderIn; Layout.fillWidth: true; placeholderText: "Funder" } }
                    ColumnLayout { spacing: 4; Label_ { text: "YEAR" } Field { id: yearIn; Layout.preferredWidth: 80; placeholderText: "2025" } }
                }
                Label_ { text: "WHO APPLIED (OPTIONAL)" }
                Field { id: applicantIn; Layout.fillWidth: true; placeholderText: "Collective or person" }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout { Layout.fillWidth: true; spacing: 4
                    Label_ { text: fp.kind === "fund-app" ? "AMOUNT AWARDED" : "AMOUNT (OPTIONAL)" }
                    Field { id: amountIn; Layout.fillWidth: true; placeholderText: fp.kind === "fund-app" ? "15000" : "up to 20 000 EUR" } }
                ColumnLayout { visible: fp.kind === "fund-app"; spacing: 4; Label_ { text: "CURRENCY" } Field { id: curIn; Layout.preferredWidth: 70 } }
                ColumnLayout { visible: fp.kind === "fund-link"; spacing: 4; Label_ { text: "DEADLINE" } Field { id: deadlineIn; Layout.preferredWidth: 120; placeholderText: "2027-01-31" } }
            }
            Flow { visible: fp.kind === "fund-link"; Layout.fillWidth: true; spacing: 6
                Chip { text: "Rolling / always open"; on: fp.rolling; onClicked: fp.rolling = !fp.rolling } }

            Label_ { text: "AREA" }
            Flow { Layout.fillWidth: true; spacing: 6
                Repeater { model: Funding.areas
                    delegate: Chip { required property var modelData; text: modelData; on: fp.area === modelData; onClicked: fp.area = on ? "" : modelData } } }

            Label_ { text: fp.kind === "fund-app" ? "LINK (OPTIONAL)" : "LINK" }
            Field { id: urlIn; Layout.fillWidth: true; placeholderText: "https://" }

            ColumnLayout {
                visible: fp.kind === "fund-app"; Layout.fillWidth: true; spacing: 5
                Label_ { text: "DOCUMENTS (" + fp.allDocs.length + ")" }
                Repeater { model: fp.allDocs
                    delegate: RowLayout { required property var modelData; Layout.fillWidth: true; spacing: 8
                        FText { Layout.fillWidth: true; elide: Text.ElideMiddle; font.pixelSize: 13; text: modelData.name }
                        Link { text: "remove"; tone: Fq.red; onClicked: fp.removeDoc(modelData.cid) } } }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    FqButton { text: fp.app && fp.app.attachBusy ? "Uploading…" : "+ Attach document"; enabled: !(fp.app && fp.app.attachBusy); onClicked: docDialog.open() }
                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 11
                        text: "The application, budget, report… Sealed in Logos Storage: only library members can open them." }
                }
                FText { visible: !!fp.app && fp.app.attachMsg !== "" && fp.app.fundingAnchor && fp.app.attachNightId === fp.app.fundingAnchor.id
                    Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.warn; font.pixelSize: 12; text: fp.app ? fp.app.attachMsg : "" }
            }

            Label_ { text: fp.kind === "fund-app" ? "WHAT WORKED / NOTES" : "NOTES" }
            Field { id: notesIn; Layout.fillWidth: true; placeholderText: fp.kind === "fund-app" ? "Tips for the next applicant" : "Who it's for, what they fund" }
        }
    }

    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        FqButton { visible: fp.id_ !== ""; text: "Remove"; onClicked: fp.app.deleteFunding(fp.id_, "Removed", function (ok) { if (ok) fp.close() }) }
        Item { Layout.fillWidth: true }
        FqButton { text: "Cancel"; onClicked: fp.close() }
        FqButton { text: fp.id_ ? "Save" : "Add"; primary: true; enabled: !(fp.app && (fp.app.extBusy || fp.app.attachBusy)); onClicked: fp.save() }
    }
    FileDialog { id: docDialog; title: "Attach a document"; onAccepted: fp.app.uploadToFunding(docDialog.selectedFile) }
}
