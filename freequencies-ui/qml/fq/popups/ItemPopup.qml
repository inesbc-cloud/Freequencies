// Add or change a checklist item: a task (#16), gear (#17), a budget line (#18) or a social post (#19).
import QtQuick
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/checklist.js" as Checklist
import "../lib/money.js" as Money
import "../lib/ext.js" as Ext

Win {
    id: ip
    property var app
    property var night
    property string kind: "task"
    property string id_: ""
    property string cat: "other"
    property bool done: false
    property string dir: "out"             // budget lines (#18)
    readonly property var labels: ({ task: "task", gear: "gear", budget: "budget_line", post: "social_post" })
    title: (id_ ? "" : "new_") + (labels[kind] || "item") + ".exe"
    // The date and time fields read and write local time.
    function pad(n) { return (n < 10 ? "0" : "") + n }
    function whenOf() {
        var dm = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateIn.text.trim()), tm = /^(\d{1,2}):(\d{2})$/.exec(timeIn.text.trim() || "12:00")
        if (!dateIn.text.trim()) return null
        if (!dm || !tm) return undefined
        return new Date(+dm[1], +dm[2] - 1, +dm[3], +tm[1], +tm[2]).getTime()
    }
    function openFor(k, it) {
        kind = k; id_ = it ? it.id : ""
        var d = it ? it.d : {}
        textIn.text = d.text || d.item || d.label || ""
        cat = d.cat || "other"; done = d.done === true
        var w = Ext.num(d.due) !== null ? d.due : Ext.num(d.when), dd = w !== null ? new Date(w) : null
        dateIn.text = dd ? dd.getFullYear() + "-" + pad(dd.getMonth() + 1) + "-" + pad(dd.getDate()) : ""
        timeIn.text = dd ? pad(dd.getHours()) + ":" + pad(dd.getMinutes()) : "12:00"
        extraOpen(d)
        open(); textIn.forceActiveFocus()
    }
    function extraOpen(d) {
        dir = d.dir === "in" ? "in" : "out"
        amountIn.text = Ext.num(d.amount) !== null ? String(d.amount) : ""; curIn.text = d.currency || "EUR"
    }
    function extraData() { return ({ cat: cat, done: done }) }
    function save() {
        var w = whenOf()
        if (w === undefined) { app.notify("Use a date like 2026-11-24 and a time like 18:00.", true); return }
        var r = kind === "budget" ? Money.parse(textIn.text, amountIn.text, curIn.text, dir) : Checklist.parse(kind, textIn.text, w, extraData())
        if (r.error) { app.notify(r.error, true); return }
        app.postItem(night, Ext.item(kind, night.id, r.data, id_ || (kind + ":" + Ext.rnd())), id_ ? "Updated" : "Added", function (ok) { if (ok) ip.close() })
    }

    Label_ { text: ip.kind === "gear" ? "ITEM" : ip.kind === "post" ? "POST" : ip.kind === "budget" ? "WHAT" : "TASK" }
    Field { id: textIn; Layout.fillWidth: true; onAccepted: ip.save() }
    ColumnLayout {
        visible: ip.kind === "task"; Layout.fillWidth: true; spacing: 7
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: "DEADLINE" } Field { id: dateIn; Layout.fillWidth: true; placeholderText: "2026-11-24" } }
            ColumnLayout { spacing: 4; Label_ { text: "AT" } Field { id: timeIn; Layout.preferredWidth: 90 } }
        }
        Label_ { text: "KIND" }
        Flow { Layout.fillWidth: true; spacing: 6
            Repeater { model: Checklist.taskCats; delegate: Chip { required property var modelData; text: modelData; on: ip.cat === modelData; onClicked: ip.cat = modelData } } }
    }
    ColumnLayout {
        visible: ip.kind === "budget"; Layout.fillWidth: true; spacing: 7
        Flow { Layout.fillWidth: true; spacing: 6
            Chip { text: "Cost (out)"; on: ip.dir === "out"; onClicked: ip.dir = "out" }
            Chip { text: "Income (in)"; on: ip.dir === "in"; onClicked: ip.dir = "in" } }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: "AMOUNT" } Field { id: amountIn; Layout.fillWidth: true; placeholderText: "250" } }
            ColumnLayout { spacing: 4; Label_ { text: "CURRENCY" } Field { id: curIn; Layout.preferredWidth: 90 } }
        }
    }
    Flow { visible: ip.kind !== "budget"; Layout.fillWidth: true; spacing: 6
        Chip { text: "Done"; on: ip.done; onClicked: ip.done = !ip.done } }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        FqButton { visible: ip.id_ !== ""; text: "Remove"; onClicked: ip.app.deleteItem(ip.night, ip.id_, "Removed", function (ok) { if (ok) ip.close() }) }
        Item { Layout.fillWidth: true }
        FqButton { text: "Cancel"; onClicked: ip.close() }
        FqButton { text: ip.id_ ? "Save" : "Add"; primary: true; enabled: !ip.app || !ip.app.extBusy; onClicked: ip.save() }
    }
}
