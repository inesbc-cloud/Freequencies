// Files (#14): contracts, riders, posters, logos. Scala's attachments (Logos Storage, sealed with the
// calendar key: only members can open them), with a members-only / community flag per file.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/files.js" as Files

ColumnLayout {
    id: fs
    property var app
    property var night
    property bool canEdit: false
    signal upload()
    readonly property var files: Files.filesOf(night)
    Layout.fillWidth: true; spacing: 6

    Sec { label: "Files (" + fs.files.length + ")"; action: fs.canEdit && !fs.app.attachBusy ? "+ upload" : ""; onAct: fs.upload() }
    FText { visible: fs.files.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: "Contracts, riders, posters, logos. Stored in Logos Storage, sealed with this calendar's key: only its members can open them." }
    Repeater {
        model: fs.files
        delegate: Rectangle {
            id: fl
            required property var modelData
            readonly property string vis: Files.visibilityOf(fs.night, modelData.storageCid)
            Layout.fillWidth: true; Layout.preferredHeight: flCol.implicitHeight + 14; color: "transparent"; border.width: 1; border.color: Fq.line
            ColumnLayout {
                id: flCol
                x: 10; y: 7; width: parent.width - 20; spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    FText { Layout.fillWidth: true; elide: Text.ElideMiddle; text: fl.modelData.name || "file"; font.pixelSize: 13 }
                    Chip { text: fl.vis === "public" ? "COMMUNITY" : "MEMBERS ONLY"; on: fl.vis === "public"; accent: Fq.signal; enabled_: fs.canEdit
                        onClicked: fs.app.putLatest(fs.night, "file", { cid: fl.modelData.storageCid, visibility: fl.vis === "public" ? "private" : "public" },
                                                    fl.vis === "public" ? "Members only" : "Marked for the community", function (d) { return d.cid === fl.modelData.storageCid }) }
                }
                FText { text: Files.humanSize(fl.modelData.size) + (fl.modelData.mime ? " · " + fl.modelData.mime : ""); color: Fq.faint; font.pixelSize: 12 }
                Row {
                    spacing: 14
                    Link { text: "open"; onClicked: fs.app.openAttachment(fs.night.calendarId, fl.modelData.storageCid, fl.modelData.name) }
                    Link { visible: fs.canEdit && Files.isImage(fl.modelData); text: "use as poster"
                           onClicked: fs.app.putLatest(fs.night, "poster", { cid: fl.modelData.storageCid, name: fl.modelData.name || "poster" }, "Poster set") }
                    Link { visible: fs.canEdit; text: "remove"; tone: Fq.red
                           onClicked: fs.app.editNight(fs.night, function (up) { up.attachments = Files.without(up.attachments, fl.modelData.storageCid) }, "Removed " + (fl.modelData.name || "the file")) }
                }
            }
        }
    }
    FText { visible: fs.app.attachMsg !== "" && fs.app.attachNightId === (fs.night ? fs.night.id : ""); text: fs.app.attachMsg; color: Fq.warn; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.Wrap }
    FText { visible: fs.files.some(function (a) { return Files.visibilityOf(fs.night, a.storageCid) === "public" }); Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 12
        text: "Community files are marked to share; the bytes stay sealed for members until Scala can publish files." }
}
