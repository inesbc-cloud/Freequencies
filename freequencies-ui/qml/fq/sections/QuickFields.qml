// Status, venue and type, one click each (#8). Saved venues come back as chips.
import QtQuick
import QtQuick.Layouts
import ".."
import "../.."   // Field.qml
import "../lib/nights.js" as Nights
import "../lib/colour.js" as Colour

ColumnLayout {
    id: qf
    property var app
    property var night
    property bool canEdit: false
    Layout.fillWidth: true; spacing: 6

    Sec { label: Fq.t("Status") }
    Flow {
        Layout.fillWidth: true; spacing: 6
        Repeater { model: Nights.statuses
            delegate: Chip { required property var modelData; text: Fq.t(modelData); accent: Colour.statusColor(modelData, qf.app.fqPalette)
                on: Nights.fieldOf(qf.night, "status") === modelData; enabled_: qf.canEdit
                onClicked: if (!on) qf.app.setNightField(qf.night, "status", modelData) } }
    }
    Sec { label: Fq.t("Venue"); action: Nights.fieldOf(qf.night, "venue") ? Fq.t("map ↗") : ""
          onAct: Qt.openUrlExternally("https://www.openstreetmap.org/search?query=" + encodeURIComponent(Nights.fieldOf(qf.night, "venue") + ", Lisboa")) }
    RowLayout {
        Layout.fillWidth: true; spacing: 6
        Field { id: venueIn; Layout.fillWidth: true; enabled: qf.canEdit; text: Nights.fieldOf(qf.night, "venue"); placeholderText: Fq.t("Where it happens")
                onAccepted: qf.app.setNightField(qf.night, "venue", text.trim()) }
        FqButton { text: Fq.t("Save"); enabled: qf.canEdit && venueIn.text.trim() !== Nights.fieldOf(qf.night, "venue"); onClicked: qf.app.setNightField(qf.night, "venue", venueIn.text.trim()) }
    }
    Flow {
        Layout.fillWidth: true; spacing: 6; visible: qf.canEdit
        Repeater { model: qf.app.venuesInUse.filter(function (v) { return v.toLowerCase() !== Nights.fieldOf(qf.night, "venue").toLowerCase() }).slice(0, 6)
            delegate: Chip { required property var modelData; text: modelData; onClicked: qf.app.setNightField(qf.night, "venue", modelData) } }
    }
    Sec { label: Fq.t("Type") }
    Flow {
        Layout.fillWidth: true; spacing: 6
        Repeater { model: Nights.types
            delegate: Chip { required property var modelData; text: Fq.t(modelData); accent: Colour.typeColor(modelData, qf.app.fqPalette)
                on: Nights.fieldOf(qf.night, "type") === modelData; enabled_: qf.canEdit
                onClicked: if (!on) qf.app.setNightField(qf.night, "type", modelData) } }
    }
}
