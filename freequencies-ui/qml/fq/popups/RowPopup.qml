// Add or change one row of a production table. The fields follow the table's columns.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/production.js" as Production

Win {
    id: rp
    objectName: "rowPopup"
    property var app
    property var night
    property string table: ""
    property var row: null
    property var def: null
    property var vals: ({})
    title: (row ? "" : "new_") + (def ? def.t.toLowerCase().replace(/[^a-z0-9]+/g, "_") : "row") + ".exe"
    width: Math.min(560, (parent ? parent.width : 560) - 40)

    function openFor(n, t, r) {
        night = n; table = t; row = r
        def = Production.tableDef(Production.planOf(n), t)
        var v = {}, c = r ? r.cells : {}
        var cols = def ? def.cols : []
        for (var i = 0; i < cols.length; i++) {
            var k = cols[i].k
            v[k] = c[k] !== undefined ? c[k] : (cols[i].type === "check" ? false : cols[i].type === "select" && cols[i].opts ? cols[i].opts[0] : "")
        }
        vals = v
        open()
    }
    function setVal(k, x) { var v = {}; for (var key in vals) v[key] = vals[key]; v[k] = x; vals = v }
    function save() { app.saveRow(night, table, row, vals, function (ok) { if (ok) rp.close() }) }

    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(body.implicitHeight, (rp.parent ? rp.parent.height : 800) - 170)
        contentWidth: availableWidth; clip: true
        ColumnLayout {
            id: body
            width: parent.width; spacing: 7
            Repeater {
                model: rp.def ? rp.def.cols : []
                delegate: ColumnLayout {
                    id: fd
                    required property var modelData
                    Layout.fillWidth: true; spacing: 4
                    Label_ { text: (fd.modelData.type === "tminus" ? Fq.t("DAYS BEFORE THE SHOW (−2 = TWO DAYS AFTER)") : Fq.t(fd.modelData.l).toUpperCase()) }
                    Field {
                        visible: ["select", "check"].indexOf(fd.modelData.type) < 0; Layout.fillWidth: true
                        text: rp.vals[fd.modelData.k] === undefined ? "" : String(rp.vals[fd.modelData.k])
                        placeholderText: fd.modelData.type === "date" ? "2026-12-17" : fd.modelData.type === "time" ? "23:00" : fd.modelData.type === "money" ? "0" : ""
                        onTextEdited: rp.setVal(fd.modelData.k, text)
                        onAccepted: rp.save()
                    }
                    Flow {
                        visible: fd.modelData.type === "select"; Layout.fillWidth: true; spacing: 6
                        Repeater { model: fd.modelData.opts || []
                            delegate: Chip { required property var modelData; text: Fq.t(modelData); on: rp.vals[fd.modelData.k] === modelData; onClicked: rp.setVal(fd.modelData.k, modelData) } }
                    }
                    Chip { visible: fd.modelData.type === "check"; text: rp.vals[fd.modelData.k] === true ? Fq.t("Yes") : Fq.t("No"); on: rp.vals[fd.modelData.k] === true
                        onClicked: rp.setVal(fd.modelData.k, !(rp.vals[fd.modelData.k] === true)) }
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        FqButton { visible: !!rp.row; text: Fq.t("Remove"); onClicked: rp.app.deleteRow(rp.night, rp.row, function (ok) { if (ok) rp.close() }) }
        Item { Layout.fillWidth: true }
        FqButton { text: Fq.t("Cancel"); onClicked: rp.close() }
        FqButton { text: rp.row ? Fq.t("Save") : "Add"; primary: true; enabled: !(rp.app && rp.app.extBusy); onClicked: rp.save() }
    }
}
