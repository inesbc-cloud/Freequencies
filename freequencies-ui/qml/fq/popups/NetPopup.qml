// Add or change a Network entry (venue, gear, crew pool, borrow request) or a poll. The fields come
// from Network.SPECS; a poll can belong to an event (target) or to the network.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/network.js" as Network
import "../lib/ext.js" as Ext

Win {
    id: np
    objectName: "netPopup"
    property var app
    property string kind: "venue"
    property var item: null                   // existing { id, d } or null
    property var target: null                 // an event for polls on it; null = the network anchor
    property var extra: ({})                  // merged into the data (e.g. { gear: id })
    property var vals: ({})
    readonly property var spec: Network.SPECS[kind]
    title: (item ? "" : "new_") + kind + ".exe"
    width: Math.min(560, (parent ? parent.width : 560) - 40)

    function openFor(k, it, tgt, ex, preset) {
        kind = k; item = it || null; target = tgt || null; extra = ex || {}
        var v = {}, d = it ? it.d : (preset || {})
        Network.SPECS[k].fields.forEach(function (c) { var x = d[c.k]; v[c.k] = c.type === "lines" ? (Array.isArray(x) ? x.join("\n") : "") : c.type === "multi" ? (Array.isArray(x) ? x.slice() : []) : (x === undefined ? "" : String(x)) })
        vals = v; open()
    }
    function setVal(k, x) { var v = {}; for (var key in vals) v[key] = vals[key]; v[k] = x; vals = v }
    function toggle(k, opt) { var a = (vals[k] || []).slice(), i = a.indexOf(opt); if (i >= 0) a.splice(i, 1); else a.push(opt); setVal(k, a) }
    function save() {
        var r = Network.clean(kind, vals)
        if (r.error) { app.notify(Fq.t(r.error, [Fq.t(r.arg || "")]), true); return }
        var data = r.data; for (var k in extra) data[k] = extra[k]
        var id = item ? item.id : ""
        if (target) app.postItem(target, Ext.item(kind, target.id, data, id || (kind + ":" + Ext.rnd())), item ? Fq.t("Saved") : Fq.t("Added"), function (ok) { if (ok) np.close() })
        else app.postNet(kind, data, id, item ? Fq.t("Saved") : Fq.t("Shared"), function (ok) { if (ok) np.close() })
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(body.implicitHeight, (np.parent ? np.parent.height : 800) - 170)
        contentWidth: availableWidth; clip: true
        ColumnLayout {
            id: body
            width: parent.width; spacing: 7
            Repeater {
                model: np.spec ? np.spec.fields : []
                delegate: ColumnLayout {
                    id: fd
                    required property var modelData
                    Layout.fillWidth: true; spacing: 4
                    Label_ { text: Fq.t(fd.modelData.l).toUpperCase() }
                    Field { visible: ["multi", "lines", "long"].indexOf(fd.modelData.type) < 0; Layout.fillWidth: true
                        text: np.vals[fd.modelData.k] || ""; placeholderText: fd.modelData.type === "date" ? "2026-12-17" : ""
                        onTextEdited: np.setVal(fd.modelData.k, text); onAccepted: np.save() }
                    TextArea {
                        visible: fd.modelData.type === "lines" || fd.modelData.type === "long"; Layout.fillWidth: true; Layout.preferredHeight: 70
                        text: np.vals[fd.modelData.k] || ""; wrapMode: TextEdit.Wrap; color: Fq.text; font.family: Fq.body; font.pixelSize: 13
                        placeholderText: fd.modelData.type === "lines" ? Fq.t("Friday 5\nSaturday 6") : ""
                        background: Rectangle { color: Fq.mantle; border.width: 1; border.color: parent.activeFocus ? Fq.lime : Fq.line }
                        onTextChanged: if (activeFocus) np.setVal(fd.modelData.k, text)
                    }
                    Flow { visible: fd.modelData.type === "multi"; Layout.fillWidth: true; spacing: 6
                        Repeater { model: fd.modelData.opts || []
                            delegate: Chip { required property var modelData; text: Fq.t(modelData); on: (np.vals[fd.modelData.k] || []).indexOf(modelData) >= 0; onClicked: np.toggle(fd.modelData.k, modelData) } } }
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        FqButton { visible: !!np.item; text: Fq.t("Remove")
            onClicked: { if (np.target) np.app.deleteItem(np.target, np.item.id, Fq.t("Removed"), function (ok) { if (ok) np.close() }); else np.app.deleteNet(np.item.id, function (ok) { if (ok) np.close() }) } }
        Item { Layout.fillWidth: true }
        FqButton { text: Fq.t("Cancel"); onClicked: np.close() }
        FqButton { text: np.item ? Fq.t("Save") : Fq.t("Add"); primary: true; enabled: !(np.app && np.app.extBusy); onClicked: np.save() }
    }
}
