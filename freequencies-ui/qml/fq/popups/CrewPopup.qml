// Add or change a crew slot (#11): a role, a person (from Kith or typed; none = open slot), call time.
import QtQuick
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/crew.js" as Crew
import "../lib/lineup.js" as Lineup
import "../lib/ext.js" as Ext

Win {
    id: cp
    property var app
    property var night
    title: id_ ? "crew.exe" : "new_crew.exe"
    property string id_: ""
    property string contact: ""
    property string book: ""
    property string status: "asked"
    property bool canRemove: false
    property string query: ""
    readonly property var matches: {
        var q = query.trim().toLowerCase(), out = [], ks = app ? app.kithArtists : []
        for (var i = 0; i < ks.length && out.length < 10; i++) if (!q || ks[i].name.toLowerCase().indexOf(q) >= 0) out.push(ks[i])
        return out
    }
    function openFor(c) {
        var cal = app.calById(night.calendarId)
        id_ = c ? c.id : ""; contact = c ? c.contact : ""; book = c ? c.book : ""; status = c ? c.status : "asked"
        canRemove = !!c && ((!!cal && c.author === cal.authorAddr) || app.isEditorOf(cal))
        query = ""; search.text = ""
        nameIn.text = c ? c.name : ""; roleIn.text = c ? c.role : ""; callIn.text = c ? c.call : ""
        open(); app.loadKith()
    }
    function save() {
        var name = nameIn.text.trim(), role = roleIn.text.trim()
        if (!name && !role) { app.notify("Give a role or a name. A role without a name is an open slot.", true); return }
        var data = { name: name, role: role, status: status }
        if (name && contact) { data.contact = contact; data.book = book }
        if (callIn.text.trim()) data.call = callIn.text.trim()
        app.postItem(night, Ext.item("crew", night.id, data, id_), id_ ? "Crew updated" : name ? "Added " + name + " to the crew" : "Open slot added",
                     function (ok) { if (ok) cp.close() })
    }

    Label_ { text: "ROLE" }
    Field { id: roleIn; Layout.fillWidth: true; placeholderText: "Door, Bar, Sound…" }
    Flow { Layout.fillWidth: true; spacing: 6
        Repeater { model: Crew.roles; delegate: Chip { required property var modelData; text: modelData; on: roleIn.text === modelData; onClicked: roleIn.text = modelData } } }
    Label_ { text: "PERSON (EMPTY = OPEN SLOT)" }
    Field { id: search; Layout.fillWidth: true; placeholderText: "Search your Kith books…"; onTextChanged: cp.query = text }
    Flow { Layout.fillWidth: true; spacing: 6
        Repeater { model: cp.matches
            delegate: Chip { required property var modelData; text: modelData.name; on: cp.contact === modelData.id
                onClicked: { cp.contact = modelData.id; cp.book = modelData.bookId; nameIn.text = modelData.name } } } }
    Field { id: nameIn; Layout.fillWidth: true; placeholderText: "Name"; onTextEdited: cp.contact = "" }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        ColumnLayout { spacing: 4; Label_ { text: "CALL" } Field { id: callIn; Layout.preferredWidth: 90; placeholderText: "16:30" } }
        ColumnLayout { Layout.fillWidth: true; spacing: 4; Label_ { text: "STATUS" }
            Flow { Layout.fillWidth: true; spacing: 6
                Repeater { model: Lineup.bookingStatuses
                    delegate: Chip { required property var modelData; text: Lineup.cap(modelData); accent: cp.app ? cp.app.bookingColor(modelData) : Fq.lime
                        on: cp.status === modelData; onClicked: cp.status = modelData } } } }
    }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        FqButton { visible: cp.canRemove; text: "Remove"; onClicked: cp.app.deleteItem(cp.night, cp.id_, "Removed from the crew", function (ok) { if (ok) cp.close() }) }
        Item { Layout.fillWidth: true }
        FqButton { text: "Cancel"; onClicked: cp.close() }
        FqButton { text: cp.id_ ? "Save" : "Add"; primary: true; enabled: !cp.app || !cp.app.extBusy; onClicked: cp.save() }
    }
}
