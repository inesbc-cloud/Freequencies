// Public / private (#21, ADR 0008): a copy of the night in a public calendar, kept in step. Attendees
// see the time, venue, confirmed artists and the guest-list link. Nothing else.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/publiccopy.js" as Pub

ColumnLayout {
    id: pu
    property var app
    property var night
    property bool canEdit: false
    signal makePublic()
    readonly property var link: Pub.publicLinkOf(night)
    readonly property var pcal: link ? app.calById(link.calendar) : null
    readonly property var cal: night ? app.calById(night.calendarId) : null
    Layout.fillWidth: true; spacing: 6

    Sec { label: Fq.t("Public / private") }
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: pc.implicitHeight + 16; color: "transparent"; border.width: 1; border.color: pu.link ? Fq.lime : Fq.line
        ColumnLayout {
            id: pc
            x: 10; width: parent.width - 20; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13
                text: !pu.link ? Fq.t("PRIVATE · only this calendar's members see it.") : pu.pcal ? Fq.t("PUBLIC in “") + pu.pcal.name + "”" : Fq.t("PUBLIC in a calendar not on this computer") }
            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
                text: !pu.link ? Fq.t("Fees, crew, budget, tasks, notes and files always stay private.")
                    : pu.app.putMissing ? "The public copy can't be updated from here: update the ‘scala’ package to 0.12.4 or newer."
                    : pu.app.mirrorBlocked[pu.night ? pu.night.id : ""] ? "You can't update the public copy: ask an editor of the public calendar to open Freequencies."
                    : "Attendees see the time, venue, confirmed artists and the guest-list link. Nothing else." }
            Flow {
                Layout.fillWidth: true; spacing: 14
                Link { visible: !pu.link && pu.canEdit; text: Fq.t("make public →"); onClicked: pu.makePublic() }
                Link { visible: !!pu.pcal && pu.app.isEditorOf(pu.pcal); text: Fq.t("copy link for attendees"); onClicked: pu.app.copyInvite(pu.pcal.id, "viewer") }
                Link { visible: !!pu.link && ((!!pu.cal && pu.link.author === pu.cal.authorAddr) || pu.app.isEditorOf(pu.cal)); text: Fq.t("make private"); tone: Fq.red
                       onClicked: pu.app.deleteItem(pu.night, pu.link.id, "No longer public: its copy now says Cancelled") }
            }
        }
    }
}
