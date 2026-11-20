// Make a night public (#21): pick the public calendar its copy goes to, or start one.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/publiccopy.js" as Pub
import "../lib/ext.js" as Ext

Win {
    id: pp
    property var app
    property var night
    title: "make_public.exe"
    function publish(calId) {
        app.postItem(night, Ext.item("public", night.id, { calendar: calId }, Pub.publicItemId(night.id)), "Public: attendees will see it", function (ok) { if (ok) pp.close() })
    }
    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: "A copy goes into a public calendar (open to view, not to edit) and is kept in step: time, venue, confirmed artists, guest-list link." }
    Label_ { text: "PUBLIC CALENDARS YOU EDIT" }
    FText { visible: pp.app && pp.app.publicTargets.length === 0; text: "None yet."; color: Fq.faint; font.pixelSize: 12 }
    Repeater { model: pp.app ? pp.app.publicTargets : []
        delegate: FqButton { required property var modelData; Layout.fillWidth: true; text: modelData.name || "(unnamed)"; onClicked: pp.publish(modelData.id) } }
    FqButton { Layout.fillWidth: true; text: "+ New public calendar"; onClicked: pp.app.newPublicCalendar(pp.night, function (id) { if (id) pp.publish(id) }) }
    FqButton { Layout.alignment: Qt.AlignRight; text: "Cancel"; onClicked: pp.close() }
}
