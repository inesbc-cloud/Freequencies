// Log an inspection after it happened: who came, what they checked, what happened. Saved on the
// event (private to the collective). Optionally shared with Lisboa as an anonymous pattern.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/legal.js" as Legal
import "../lib/ext.js" as Ext

Win {
    id: ip
    objectName: "inspectionPopup"
    property var app
    property var night: null
    property string who: ""
    property var checked: []
    property string outcome: "Nothing"
    property bool share: false
    readonly property var events: app ? app.freqNights.filter(function (e) { return e.startTime < app.nowTick + 86400000 }).sort(function (a, b) { return b.startTime - a.startTime }).slice(0, 12) : []
    title: "inspection_log.exe"
    width: Math.min(580, (parent ? parent.width : 580) - 40)
    function openFor(n) { night = n || (events.length ? events[0] : null); who = ""; checked = []; outcome = "Nothing"; share = false; noteIn.text = ""; areaIn.text = ""; open() }
    function toggle(c) { var a = checked.slice(), i = a.indexOf(c); if (i >= 0) a.splice(i, 1); else a.push(c); checked = a }
    function save() {
        if (!night) { app.notify(Fq.t("Pick the event it happened at."), true); return }
        var r = Legal.cleanInspection({ body: who, checked: checked, outcome: outcome, note: noteIn.text, area: areaIn.text, share: share })
        if (r.error) { app.notify(Fq.t(r.error), true); return }
        app.logInspection(night, r.data, function (ok) { if (ok) ip.close() })
    }
    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(body_.implicitHeight, (ip.parent ? ip.parent.height : 800) - 170)
        contentWidth: availableWidth; clip: true
        ColumnLayout {
            id: body_
            width: parent.width; spacing: 7
            Label_ { text: Fq.t("AT WHICH EVENT") }
            Flow { Layout.fillWidth: true; spacing: 6
                Repeater { model: ip.events
                    delegate: Chip { required property var modelData; text: Fq.fmtDate(new Date(modelData.startTime), "dd.MM") + " " + (modelData.title || "").slice(0, 22); on: ip.night && ip.night.id === modelData.id; onClicked: ip.night = modelData } } }
            Label_ { text: Fq.t("WHO CAME") }
            Flow { Layout.fillWidth: true; spacing: 6
                Repeater { model: Legal.BODIES
                    delegate: Chip { required property var modelData; text: Fq.t(modelData); on: ip.who === modelData; onClicked: ip.who = modelData } } }
            Label_ { text: Fq.t("WHAT THEY CHECKED") }
            Flow { Layout.fillWidth: true; spacing: 6
                Repeater { model: Legal.CHECKS
                    delegate: Chip { required property var modelData; text: Fq.t(modelData); on: ip.checked.indexOf(modelData) >= 0; onClicked: ip.toggle(modelData) } } }
            Label_ { text: Fq.t("WHAT HAPPENED") }
            Flow { Layout.fillWidth: true; spacing: 6
                Repeater { model: Legal.OUTCOMES
                    delegate: Chip { required property var modelData; text: Fq.t(modelData); on: ip.outcome === modelData; onClicked: ip.outcome = modelData } } }
            Label_ { text: Fq.t("WHAT WOULD HAVE HELPED (NO NAMES)") }
            Field { id: noteIn; Layout.fillWidth: true; placeholderText: Fq.t("e.g. having the noise licence printed at the door") }
            Label_ { text: Fq.t("NEIGHBOURHOOD (OPTIONAL)") }
            Field { id: areaIn; Layout.fillWidth: true; placeholderText: "Cais do Sodré" }
            Chip { text: Fq.t("Share anonymously with Lisboa (month, area, who, what they checked, outcome)"); on: ip.share; onClicked: ip.share = !ip.share }
        }
    }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        Item { Layout.fillWidth: true }
        FqButton { text: Fq.t("Cancel"); onClicked: ip.close() }
        FqButton { text: Fq.t("Save"); primary: true; enabled: !(ip.app && ip.app.extBusy); onClicked: ip.save() }
    }
}
