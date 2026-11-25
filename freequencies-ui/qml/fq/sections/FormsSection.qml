// Forms (#20, ADR 0005): WhisperBox forms attached to the night; answers sealed for their creator.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/forms.js" as Forms

ColumnLayout {
    id: fo
    property var app
    property var night
    property bool canEdit: false
    signal addForm()
    signal openAnswers(var form)
    readonly property var forms: Forms.formsOf(night)
    readonly property var cal: night ? app.calById(night.calendarId) : null
    Layout.fillWidth: true; spacing: 6
    onNightChanged: if (fo.forms.length > 0) fo.app.loadWb()

    Sec { label: Fq.t("Forms (") + fo.forms.length + ")"; action: fo.canEdit ? Fq.t("+ form") : ""; onAct: fo.addForm() }
    FText { visible: fo.forms.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: Fq.t("Artist bookings, crew sign-up, guest list or feedback: private forms, answers sealed for you.") }
    Repeater {
        model: fo.forms
        delegate: Rectangle {
            id: fm
            required property var modelData
            readonly property var sm: fo.app.wbSummaries[modelData.formId]
            Layout.fillWidth: true; Layout.preferredHeight: fmc.implicitHeight + 14; color: "transparent"; border.width: 1; border.color: Fq.line
            ColumnLayout {
                id: fmc
                x: 10; y: 7; width: parent.width - 20; spacing: 3
                FText { Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 13; text: Forms.formTitle(fm.modelData, fm.sm, fo.app.wbForms[fm.modelData.formId]) }
                FText { Layout.fillWidth: true; elide: Text.ElideRight; color: Fq.sub; font.pixelSize: 12; text: Forms.formLine(fm.modelData, fm.sm, fo.app.wbState) }
                Row {
                    spacing: 14
                    Link { visible: fm.modelData.uri !== ""; text: Fq.t("copy link"); onClicked: fo.app.copyText(fm.modelData.uri) }
                    Link { visible: !!fm.sm && fm.sm.canRead === true; text: Fq.t("answers"); onClicked: fo.openAnswers(fm.modelData) }
                    Link { visible: (!!fo.cal && fm.modelData.author === fo.cal.authorAddr) || fo.app.isEditorOf(fo.cal); text: Fq.t("remove"); tone: Fq.red
                           onClicked: fo.app.deleteItem(fo.night, fm.modelData.id, "Form removed from this event. It stays in WhisperBox.") }
                }
            }
        }
    }
}
