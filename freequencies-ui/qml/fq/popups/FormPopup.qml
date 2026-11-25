// Add a WhisperBox form to the night (#20): pick what it's for; WhisperBox's shared templates.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/forms.js" as Forms

Win {
    id: fp
    property var app
    property var night
    property var occ
    title: "new_form.exe"
    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: Fq.t("A private form in WhisperBox, titled for this event. Share its link; the answers are sealed for you.") }
    Repeater {
        model: Forms.purposes
        delegate: FqButton { required property var modelData; Layout.fillWidth: true; text: modelData.label; enabled: !fp.app || !fp.app.formBusy
            onClicked: fp.app.addForm(fp.night, fp.occ, modelData.id, function (ok) { if (ok) fp.close() }) }
    }
    FqButton { Layout.alignment: Qt.AlignRight; text: Fq.t("Cancel"); onClicked: fp.close() }
}
