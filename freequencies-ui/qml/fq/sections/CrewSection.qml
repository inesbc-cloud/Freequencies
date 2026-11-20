// Crew (#11, ADR 0007): roles, call times, people from Kith, open slots, one-tap "I'm here".
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/crew.js" as Crew
import "../lib/lineup.js" as Lineup
import "../lib/ext.js" as Ext

ColumnLayout {
    id: cs
    property var app
    property var night
    property bool canEdit: false
    signal editCrew(var slot)              // null = add
    readonly property var crew: Crew.crewOf(night)
    readonly property var cal: night ? app.calById(night.calendarId) : null
    readonly property string sum: Crew.summaryLabel(Crew.summary(crew))
    Layout.fillWidth: true; spacing: 6

    function canUndo(c) { return !!c.checkedIn && ((!!cs.cal && c.checkedIn.author === cs.cal.authorAddr) || cs.app.isEditorOf(cs.cal)) }
    function toggleCheckin(c) {
        if (!c.name) return
        if (c.checkedIn) cs.app.deleteItem(cs.night, c.checkedIn.id, "Check-in undone")
        else cs.app.postItem(cs.night, Ext.item("checkin", cs.night.id, { crew: c.id, at: Date.now() }, Crew.checkinId(c.id)), c.name + " is here")
    }

    Sec { label: "Crew" + (cs.sum ? " (" + cs.sum + ")" : ""); action: "+ crew"; onAct: cs.editCrew(null) }
    FText { visible: cs.crew.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: "No crew yet. Add people, or a role with no name as an open slot." }
    Repeater {
        model: cs.crew
        delegate: Rectangle {
            id: cr
            required property var modelData
            readonly property bool canToggle: !!modelData.name && modelData.status !== "cancelled" && (!modelData.checkedIn || cs.canUndo(modelData))
            Layout.fillWidth: true; Layout.preferredHeight: crCol.implicitHeight + 12
            color: crMA.containsMouse ? Fq.surface : "transparent"; border.width: 1; border.color: Fq.line
            MouseArea { id: crMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cs.editCrew(cr.modelData) }
            Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; color: cr.modelData.name ? cs.app.bookingColor(cr.modelData.status) : Fq.faint }
            Column {
                id: crCol
                x: 24; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 32 - (here.visible ? here.width + 8 : 0); spacing: 1
                FText { width: parent.width; elide: Text.ElideRight; font.pixelSize: 13
                    color: cr.modelData.status === "cancelled" || !cr.modelData.name ? Fq.sub : Fq.text
                    font.strikeout: cr.modelData.status === "cancelled"; font.italic: !cr.modelData.name
                    text: (cr.modelData.role ? cr.modelData.role.toUpperCase() + "  " : "") + (cr.modelData.name ? cs.app.kithName(cr.modelData) : "open slot") }
                FText { width: parent.width; elide: Text.ElideRight; color: Fq.sub; font.pixelSize: 12; visible: text !== ""
                    text: [cr.modelData.call ? "call " + cr.modelData.call : "", cr.modelData.name ? Lineup.cap(cr.modelData.status) : "",
                           cr.modelData.checkedIn ? "here since " + Qt.formatTime(new Date(cr.modelData.checkedIn.at), "hh:mm") : ""].filter(function (x) { return !!x }).join(" · ") }
            }
            Chip {
                id: here
                visible: (!!cr.modelData.name && cr.modelData.status !== "cancelled") || !!cr.modelData.checkedIn
                anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                text: cr.modelData.checkedIn ? "HERE ✓" : "I'M HERE"; on: !!cr.modelData.checkedIn; enabled_: cr.canToggle && !cs.app.extBusy
                onClicked: cs.toggleCheckin(cr.modelData)
            }
        }
    }
}
