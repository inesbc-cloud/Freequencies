// Quick polls on an event ("which poster?", "which date for the next one?"). Anyone on the
// calendar votes; one vote each.
import QtQuick
import QtQuick.Layouts
import ".."
import "../popups"
import "../lib/network.js" as Network

ColumnLayout {
    id: ps
    property var app
    property var night
    property bool canEdit: false
    readonly property var polls: night ? Network.pollsOf(night) : []
    Layout.fillWidth: true; spacing: 6
    Sec { label: Fq.t("Polls") + (ps.polls.length ? " (" + ps.polls.length + ")" : ""); action: Fq.t("+ poll"); onAct: netPopup.openFor("poll", null, ps.night) }
    FText { visible: ps.polls.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: Fq.t("Ask the team: which poster, which date, which bar deal.") }
    Repeater { model: ps.polls
        delegate: PollCard { required property var modelData; app: ps.app; host: ps.night; poll: modelData; onEdit: netPopup.openFor("poll", modelData, ps.night) } }
    NetPopup { id: netPopup; app: ps.app }
}
