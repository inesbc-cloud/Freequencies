// A night's optional details: expected audience, tickets, age, accessibility and a link.
// One "details" item per night (newest wins), written by the quick form or here.
import QtQuick
import QtQuick.Layouts
import ".."
import "../.."   // Field.qml
import "../lib/details.js" as Details

ColumnLayout {
    id: ds
    property var app
    property var night
    property bool canEdit: false
    readonly property var d: Details.detailsOf(night)
    property bool editing: false
    property string audience: ""
    property bool free: false
    property string age: ""
    Layout.fillWidth: true; spacing: 6

    function startEdit() {
        audience = d.audience || ""; free = d.free === true; age = d.age || ""
        priceIn.text = typeof d.price === "number" ? String(d.price) : ""; curIn.text = d.currency || "EUR"
        accessIn.text = d.access || ""; linkIn.text = d.link || ""; onCallIn.text = d.onCall || ""; lawyerIn.text = d.lawyer || ""
        editing = true
    }
    onNightChanged: editing = false

    Sec { label: Fq.t("Details"); action: ds.canEdit && !ds.editing ? Fq.t("edit") : ""; onAct: ds.startEdit() }

    // read view
    ColumnLayout {
        visible: !ds.editing; Layout.fillWidth: true; spacing: 3
        FText { visible: Details.summary(ds.d) === "" && !ds.d.access && !ds.d.link; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
            text: Fq.t("Expected audience, tickets, age policy, accessibility. All optional.") }
        FText { visible: Details.summary(ds.d) !== ""; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13; text: Details.summary(ds.d, Fq.t) }
        FText { visible: !!ds.d.access; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText; text: Fq.t("Access: ") + (ds.d.access || "") }
        Link { visible: !!ds.d.link; text: ds.d.link || ""; onClicked: Qt.openUrlExternally(ds.d.link) }
    }

    // edit view
    ColumnLayout {
        visible: ds.editing; Layout.fillWidth: true; spacing: 6
        Label_ { text: Fq.t("EXPECTED AUDIENCE") }
        Flow { Layout.fillWidth: true; spacing: 6
            Repeater { model: Details.audiences
                delegate: Chip { required property var modelData; text: Fq.t(modelData); on: ds.audience === modelData; onClicked: ds.audience = on ? "" : modelData } } }
        Label_ { text: Fq.t("TICKETS") }
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Chip { text: Fq.t("Free"); on: ds.free; onClicked: ds.free = !ds.free }
            Field { id: priceIn; enabled: !ds.free; Layout.fillWidth: true; placeholderText: Fq.t("Price") }
            Field { id: curIn; enabled: !ds.free; Layout.preferredWidth: 64 }
        }
        Label_ { text: Fq.t("AGE") }
        Flow { Layout.fillWidth: true; spacing: 6
            Repeater { model: Details.ages
                delegate: Chip { required property var modelData; text: Fq.t(modelData); on: ds.age === modelData; onClicked: ds.age = on ? "" : modelData } } }
        Label_ { text: Fq.t("ACCESSIBILITY") }
        Field { id: accessIn; Layout.fillWidth: true; placeholderText: Fq.t("Step-free entry, quiet room…") }
        Label_ { text: Fq.t("LINK") }
        Field { id: linkIn; Layout.fillWidth: true; placeholderText: "https://" }
        Label_ { text: Fq.t("ON CALL TONIGHT (FOR THE HELP BUTTON)") }
        RowLayout { Layout.fillWidth: true; spacing: 6
            Field { id: onCallIn; Layout.fillWidth: true; placeholderText: Fq.t("Name and phone") }
            Field { id: lawyerIn; Layout.fillWidth: true; placeholderText: Fq.t("Lawyer: name and phone") } }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Item { Layout.fillWidth: true }
            FqButton { text: Fq.t("Cancel"); onClicked: ds.editing = false }
            FqButton { text: Fq.t("Save"); primary: true; enabled: !ds.app.extBusy
                onClicked: ds.app.saveDetails(ds.night, { audience: ds.audience, free: ds.free, price: ds.free ? "" : priceIn.text, currency: curIn.text,
                                                          age: ds.age, access: accessIn.text, link: linkIn.text, onCall: onCallIn.text, lawyer: lawyerIn.text }, function (ok) { if (ok) ds.editing = false }) }
        }
    }
}
