// The quick new-night form: name, date, venue, times and line-up. Everything else is optional,
// behind "More details" (kind of event, expected audience, tickets, age, accessibility, link,
// status, notes). Scala's full editor (repeats, reminders, custom fields) is one click away.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/nights.js" as Nights
import "../lib/details.js" as Details

Win {
    id: nn
    objectName: "newNightPopup"
    property var app
    property var cals: []
    property string calId: ""
    property bool more: false
    property string kind: ""
    property string audience: ""
    property bool free: false
    property string age: ""
    property string status: "Hold"
    title: "new_event.exe"
    width: Math.min(560, (parent ? parent.width : 560) - 40)

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function openFor(writable, day) {
        cals = writable
        var pre = writable[0].id
        if (app.lastCalId) for (var i = 0; i < writable.length; i++) if (writable[i].id === app.lastCalId) pre = app.lastCalId
        calId = pre
        var d = day ? new Date(day) : new Date()
        titleIn.text = ""; dateIn.text = d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
        startIn.text = "22:00"; endIn.text = "04:00"; venueIn.text = ""; lineupIn.text = ""
        more = false; kind = ""; audience = ""; free = false; age = ""; status = "Hold"
        priceIn.text = ""; curIn.text = "EUR"; accessIn.text = ""; linkIn.text = ""; notesIn.text = ""
        open(); titleIn.forceActiveFocus()
    }
    function form() {
        return { title: titleIn.text, date: dateIn.text, start: startIn.text, end: endIn.text, venue: venueIn.text, lineup: lineupIn.text,
                 kind: kind, audience: audience, free: free, price: free ? "" : priceIn.text, currency: curIn.text, age: age,
                 access: accessIn.text, link: linkIn.text, status: status, notes: notesIn.text }
    }
    function save() { app.createQuickNight(calId, form(), function (ok) { if (ok) nn.close() }) }

    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(body.implicitHeight, (nn.parent ? nn.parent.height : 800) - 170)
        contentWidth: availableWidth; clip: true
        ColumnLayout {
            id: body
            width: parent.width; spacing: 7

            Label_ { visible: nn.cals.length > 1; text: Fq.t("CALENDAR") }
            Flow { visible: nn.cals.length > 1; Layout.fillWidth: true; spacing: 6
                Repeater { model: nn.cals
                    delegate: Chip { required property var modelData; text: modelData.name || "calendar"; on: nn.calId === modelData.id; onClicked: nn.calId = modelData.id } } }

            Label_ { text: Fq.t("NAME") }
            Field { id: titleIn; objectName: "nnTitle"; Layout.fillWidth: true; placeholderText: Fq.t("What's the event called?"); onAccepted: nn.save() }

            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: Fq.t("DATE") } Field { id: dateIn; Layout.fillWidth: true; placeholderText: "2026-11-28" } }
                ColumnLayout { spacing: 4; Label_ { text: Fq.t("STARTS") } Field { id: startIn; Layout.preferredWidth: 80; placeholderText: "22:00" } }
                ColumnLayout { spacing: 4; Label_ { text: Fq.t("ENDS") } Field { id: endIn; Layout.preferredWidth: 80; placeholderText: "04:00" } }
            }

            Label_ { text: Fq.t("VENUE") }
            Field { id: venueIn; Layout.fillWidth: true; placeholderText: Fq.t("Where it happens") }
            Flow { Layout.fillWidth: true; spacing: 6; visible: nn.app && nn.app.venuesInUse.length > 0
                Repeater { model: nn.app ? nn.app.venuesInUse.slice(0, 8) : []
                    delegate: Chip { required property var modelData; text: modelData; on: venueIn.text.trim().toLowerCase() === modelData.toLowerCase(); onClicked: venueIn.text = modelData } } }

            Label_ { text: Fq.t("LINE-UP") }
            Field { id: lineupIn; Layout.fillWidth: true; placeholderText: Fq.t("Names, separated by commas (optional)") }
            FText { readonly property var names: Details.parseLineup(lineupIn.text)
                visible: names.length > 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 12
                text: names.length + (names.length === 1 ? Fq.t(" artist") : Fq.t(" artists")) + Fq.t(", added as asked. Set fees and times in the event panel.") }

            Link { text: nn.more ? Fq.t("− fewer details") : Fq.t("+ more details (kind, audience, tickets, access…)"); tone: Fq.acid; Layout.topMargin: 4; onClicked: nn.more = !nn.more }

            ColumnLayout {
                visible: nn.more; Layout.fillWidth: true; spacing: 7
                Label_ { text: Fq.t("KIND OF EVENT") }
                Flow { Layout.fillWidth: true; spacing: 6
                    Repeater { model: Nights.types
                        delegate: Chip { required property var modelData; text: Fq.t(modelData); on: nn.kind === modelData; onClicked: nn.kind = on ? "" : modelData } } }
                Label_ { text: Fq.t("EXPECTED AUDIENCE") }
                Flow { Layout.fillWidth: true; spacing: 6
                    Repeater { model: Details.audiences
                        delegate: Chip { required property var modelData; text: Fq.t(modelData); on: nn.audience === modelData; onClicked: nn.audience = on ? "" : modelData } } }
                Label_ { text: Fq.t("TICKETS") }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Chip { text: Fq.t("Free"); on: nn.free; onClicked: nn.free = !nn.free }
                    Field { id: priceIn; enabled: !nn.free; Layout.fillWidth: true; placeholderText: Fq.t("Price, e.g. 8") }
                    Field { id: curIn; enabled: !nn.free; Layout.preferredWidth: 70 }
                }
                Label_ { text: Fq.t("AGE") }
                Flow { Layout.fillWidth: true; spacing: 6
                    Repeater { model: Details.ages
                        delegate: Chip { required property var modelData; text: Fq.t(modelData); on: nn.age === modelData; onClicked: nn.age = on ? "" : modelData } } }
                Label_ { text: Fq.t("ACCESSIBILITY") }
                Field { id: accessIn; Layout.fillWidth: true; placeholderText: Fq.t("Step-free entry, quiet room, gender-neutral toilets…") }
                Label_ { text: Fq.t("LINK (TICKETS OR EVENT PAGE)") }
                Field { id: linkIn; Layout.fillWidth: true; placeholderText: "https://" }
                Label_ { text: Fq.t("STATUS") }
                Flow { Layout.fillWidth: true; spacing: 6
                    Repeater { model: Nights.statuses
                        delegate: Chip { required property var modelData; text: Fq.t(modelData); on: nn.status === modelData; onClicked: nn.status = modelData } } }
                Label_ { text: Fq.t("NOTES") }
                Field { id: notesIn; Layout.fillWidth: true; placeholderText: Fq.t("Anything the team should know") }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        Link { text: Fq.t("full editor"); tone: Fq.faint; onClicked: { nn.close(); nn.app.openNewEvent() } }
        Item { Layout.fillWidth: true }
        FqButton { text: Fq.t("Cancel"); onClicked: nn.close() }
        FqButton { objectName: "nnAdd"; text: nn.app && nn.app.quickBusy ? Fq.t("Adding…") : Fq.t("Add event"); primary: true; enabled: !(nn.app && nn.app.quickBusy); onClicked: nn.save() }
    }
}
