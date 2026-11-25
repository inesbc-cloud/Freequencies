// HELP: one tap from anywhere. Emergency numbers, today's event on-call contact and lawyer, and
// the one-page door sheet of your rights.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/legal.js" as Legal
import "../lib/legal-content.js" as LC
import "../lib/details.js" as Details

Win {
    id: hp
    objectName: "helpPopup"
    property var app
    title: "help.exe"
    width: Math.min(520, (parent ? parent.width : 520) - 40)
    // the event on now or tonight (its on-call contact and lawyer, from Details)
    readonly property var tonight: {
        if (!app) return null
        var now = app.nowTick, best = null
        app.freqNights.forEach(function (e) { if (e.startTime - 12 * 3600000 <= now && now <= (e.endTime || e.startTime) + 6 * 3600000) { if (!best || e.startTime > best.startTime) best = e } })
        return best
    }
    readonly property var det: tonight ? Details.detailsOf(tonight) : ({})
    function t(x) { return Legal.txt(x, Fq.lang) }

    FText { visible: !!hp.tonight; Layout.fillWidth: true; font.pixelSize: 13; color: Fq.sub; textFormat: Text.PlainText; text: hp.tonight ? Fq.t("Tonight: %1", [hp.tonight.title || ""]) : "" }
    Repeater {
        model: [hp.det.onCall ? { name: Fq.t("On call tonight"), number: hp.det.onCall } : null, hp.det.lawyer ? { name: Fq.t("Lawyer"), number: hp.det.lawyer } : null].filter(function (x) { return !!x })
        delegate: RowLayout { required property var modelData; Layout.fillWidth: true; spacing: 12
            DText { text: modelData.number; size: 26; color: Fq.lime }
            FText { font.pixelSize: 13; text: modelData.name } }
    }
    Repeater {
        model: LC.HELP.filter(function (h) { return h.urgent || h.top })
        delegate: RowLayout { required property var modelData; Layout.fillWidth: true; spacing: 12
            DText { text: modelData.number; size: 26; color: modelData.urgent ? Fq.red : Fq.lime; Layout.preferredWidth: 160 }
            ColumnLayout { Layout.fillWidth: true; spacing: 0
                FText { font.pixelSize: 13; font.bold: true; text: modelData.name }
                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 11; text: hp.t(modelData.what) } } }
    }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        FqButton { text: Fq.t("Your rights"); onClicked: { hp.close(); hp.app.openResources("legal", "rights") } }
        FqButton { text: Fq.t("Copy the door sheet"); onClicked: hp.app.copyText(hp.t(LC.DOOR_SHEET)) }
        Item { Layout.fillWidth: true }
        FqButton { text: Fq.t("Close"); primary: true; onClicked: hp.close() }
    }
}
