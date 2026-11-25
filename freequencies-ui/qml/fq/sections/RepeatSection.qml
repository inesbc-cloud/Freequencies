// Repeats and duplicate (#22): residencies and monthly nights in one click; a night copied to next week.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/duplicate.js" as Dup

ColumnLayout {
    id: rs
    property var app
    property var night
    property bool canEdit: false
    Layout.fillWidth: true; spacing: 6
    Sec { label: Fq.t("Repeats") }
    Flow {
        Layout.fillWidth: true; spacing: 6
        Repeater { model: Dup.repeatOpts
            delegate: Chip { required property var modelData; text: Fq.t(modelData.l); on: Dup.repeatLabel(rs.night) === modelData.l; enabled_: rs.canEdit
                onClicked: if (!on) rs.app.editNight(rs.night, function (up) { if (modelData.f) up.recur = { freq: modelData.f, interval: modelData.i }; else delete up.recur },
                                                     modelData.f ? "Now repeats: " + modelData.l.toLowerCase() : "No longer repeats") } }
        FText { visible: Dup.repeatLabel(rs.night) === "" && !!rs.night; text: rs.night ? rs.app.recurLabel(rs.night.recur) : ""; color: Fq.sub; font.pixelSize: 12; height: 26; verticalAlignment: Text.AlignVCenter }
    }
}
