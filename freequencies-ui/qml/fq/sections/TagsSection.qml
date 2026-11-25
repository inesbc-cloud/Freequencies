// Tags (#12): free tags with suggestions; filters, the timeline and analytics use them.
import QtQuick
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/tags.js" as Tags

ColumnLayout {
    id: ts
    property var app
    property var night
    property bool canEdit: false
    readonly property var tags: Tags.tagsOf(night)
    Layout.fillWidth: true; spacing: 6
    function add(t) { if (Tags.clean(t)) ts.app.putLatest(ts.night, "tags", { tags: Tags.withTag(ts.night, t) }, "Tagged “" + Tags.clean(t) + "”") }

    Sec { label: Fq.t("Tags") }
    Flow {
        Layout.fillWidth: true; spacing: 6
        Repeater { model: ts.tags
            delegate: Chip { required property var modelData; text: "#" + modelData + (ts.canEdit ? "  ✕" : ""); on: true; accent: Fq.signal; enabled_: ts.canEdit
                onClicked: ts.app.putLatest(ts.night, "tags", { tags: Tags.withoutTag(ts.night, modelData) }, "") } }
        Field { visible: ts.canEdit; width: 130; placeholderText: Fq.t("+ tag"); onAccepted: { ts.add(text); text = "" } }
    }
    Flow {
        Layout.fillWidth: true; spacing: 10; visible: ts.canEdit
        Repeater { model: Tags.suggestions(ts.night, ts.app.allTags, 6)
            delegate: Link { required property var modelData; text: "#" + modelData; tone: Fq.faint; onClicked: ts.add(modelData) } }
    }
}
