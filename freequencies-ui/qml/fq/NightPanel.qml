// The night panel (#8): everything about one night in the right pane. The acid-green block at the
// top is the poster's look; below it, one section per file in fq/sections/, each added by its issue.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "lib/nights.js" as Nights
import "lib/checklist.js" as Checklist
import "lib/clashes.js" as Clashes
import "sections"
import "popups"

Rectangle {
    id: panel
    objectName: "nightPanel"
    property var app                                   // FreequenciesView root
    readonly property var occ: app.selectedNight        // the occurrence that was clicked
    readonly property var night: app.selNight           // its master event, fresh from the last refresh
    readonly property var cal: night ? app.calById(night.calendarId) : null
    readonly property bool canEdit: Nights.canEdit(night, cal)
    color: Fq.mantle

    Flickable {
        id: flick
        objectName: "nightPanelFlick"
        anchors.fill: parent; clip: true
        contentWidth: width; contentHeight: col.implicitHeight + 30
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        ColumnLayout {
            id: col
            width: flick.width; spacing: 0

            Rectangle {   // poster block
                Layout.fillWidth: true; Layout.preferredHeight: hdr.implicitHeight + 30; color: Fq.acid
                ColumnLayout {
                    id: hdr
                    x: 16; y: 15; width: parent.width - 32; spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        FText { text: panel.occ ? (panel.occ.endTime < Date.now() ? Fq.t("( past gathering )") : Fq.t("( next gathering )")) : ""; color: Fq.ink; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2 }
                        Item { Layout.fillWidth: true }
                        FText { text: "✕"; color: Fq.ink; font.pixelSize: 16
                            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: panel.app.selectedNight = null } }
                    }
                    DText { text: panel.occ ? Fq.fmtDate(new Date(panel.occ.startTime), "dd.MM") : ""; color: Fq.ink; size: 72; Layout.topMargin: -4 }
                    DText { text: panel.night ? (panel.night.title || Fq.t("(untitled)")).toUpperCase() : ""; color: Fq.ink; size: 32; wrapMode: Text.Wrap; Layout.fillWidth: true; Layout.topMargin: -10 }
                    FText {
                        Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.ink; font.pixelSize: 13
                        text: panel.occ ? Fq.fmtDate(new Date(panel.occ.startTime), "dddd") + "  ·  "
                              + (panel.occ.allDay ? "all day" : Fq.fmtTime(new Date(panel.occ.startTime), "hh'h'mm") + " às " + Fq.fmtTime(new Date(panel.occ.endTime), "hh'h'mm"))
                              + (Nights.fieldOf(panel.night, "venue") ? "  ·  " + Nights.fieldOf(panel.night, "venue") : "") : ""
                    }
                    Flow {
                        Layout.fillWidth: true; Layout.topMargin: 6; spacing: 6
                        Badge { text: Fq.t(Nights.fieldOf(panel.night, "status")) || Fq.t("no status"); tone: Fq.ink }
                        Badge { visible: Nights.fieldOf(panel.night, "type") !== ""; text: Fq.t(Nights.fieldOf(panel.night, "type")); tone: Fq.ink }
                        Badge { visible: !!panel.cal; text: panel.cal ? (panel.cal.name || "") : ""; tone: Fq.ink }
                        Badge { visible: !!panel.night && !!panel.night.recur && !!panel.night.recur.freq; text: "↻ " + (panel.night ? panel.app.recurLabel(panel.night.recur) : ""); tone: Fq.ink }
                    }
                }
            }

            Image {   // the poster (#15)
                readonly property string src: panel.app.posterSrc(panel.night)
                visible: src !== "" && status === Image.Ready
                source: src; asynchronous: true; fillMode: Image.PreserveAspectFit; sourceSize.width: 800
                Layout.fillWidth: true; Layout.preferredHeight: visible ? Math.min(420, col.width * implicitHeight / Math.max(1, implicitWidth)) : 0
            }

            ColumnLayout {
                id: sections
                objectName: "nightSections"
                Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.topMargin: 6; spacing: 6

                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
                    FqButton { text: Fq.t("Edit details"); onClicked: panel.app.openEditEvent(panel.occ) }
                    FqButton { text: panel.app.dupBusy ? Fq.t("Copying…") : Fq.t("Duplicate"); enabled: panel.canEdit && !panel.app.dupBusy; onClicked: panel.app.duplicateNight(panel.night) }
                    Item { Layout.fillWidth: true }
                }
                FText { visible: !!panel.night && !panel.canEdit; Layout.fillWidth: true; Layout.topMargin: 8; wrapMode: Text.Wrap; color: Fq.warn; font.pixelSize: 12
                    text: Fq.t("Read-only: you're a ") + Nights.roleOf(panel.cal) + Fq.t(" on this calendar.") }

                Repeater {   // clash warnings (#25)
                    model: panel.occ ? panel.app.nightClashesOf(panel.occ) : []
                    delegate: FText { required property var modelData; Layout.fillWidth: true; Layout.topMargin: 6; wrapMode: Text.Wrap; color: Fq.warn; font.pixelSize: 12
                        text: Clashes.line(modelData, Fq.fmtDateTime(new Date(modelData.other.startTime), "d MMM hh:mm")) }
                }
                QuickFields { app: panel.app; night: panel.night; canEdit: panel.canEdit }
                DetailsSection { app: panel.app; night: panel.night; canEdit: panel.canEdit }
                ResultsSection { app: panel.app; night: panel.night }
                RepeatSection { app: panel.app; night: panel.night; canEdit: panel.canEdit }
                TagsSection { app: panel.app; night: panel.night; canEdit: panel.canEdit }
                LineupSection { app: panel.app; night: panel.night; canEdit: panel.canEdit; onEditArtist: function (b) { artistPopup.openFor(b) } }
                TicketsSection { app: panel.app; night: panel.night; canEdit: panel.canEdit; onEditTickets: ticketsPopup.openFor() }
                PosterSection { app: panel.app; night: panel.night; canEdit: panel.canEdit; onChange: posterPopup.openFor() }
                FilesSection { app: panel.app; night: panel.night; canEdit: panel.canEdit; onUpload: fileDialog.open() }
                BudgetSection { app: panel.app; night: panel.night; canEdit: panel.canEdit; onEditLine: function (l) { itemPopup.openFor("budget", l) } }
                CrewSection { app: panel.app; night: panel.night; canEdit: panel.canEdit; onEditCrew: function (c) { crewPopup.openFor(c) } }
                ChecklistSection {
                    app: panel.app; night: panel.night; canEdit: panel.canEdit
                    kind: "task"; label: Fq.t("Tasks (") + Checklist.openCount(panel.night) + Fq.t(" open)"); addLabel: Fq.t("+ task")
                    items: Checklist.tasksOf(panel.night)
                    emptyText: Fq.t("Book artists, announce, print posters, pay the deposit… Deadlines turn amber three days before and red when overdue.")
                    meta: function (it) { return [Checklist.overdue(it, Date.now()) ? "OVERDUE" : "", it.d.due ? "due " + Fq.fmtDateTime(new Date(it.d.due), "ddd d MMM hh:mm") : "", it.d.cat || ""].filter(function (x) { return !!x }).join(" · ") }
                    tone: function (it) { return Checklist.overdue(it, Date.now()) ? Fq.red : Checklist.dueSoon(it, Date.now()) ? Fq.warn : Fq.sub }
                    onEditItem: function (k, it) { itemPopup.openFor(k, it) }
                }
                ChecklistSection {
                    id: gear
                    app: panel.app; night: panel.night; canEdit: panel.canEdit
                    kind: "gear"; label: Fq.t("Gear (") + Checklist.packedCount(panel.night) + "/" + Checklist.gearOf(panel.night).length + Fq.t(" packed)"); addLabel: Fq.t("+ item")
                    items: Checklist.gearOf(panel.night)
                    onEditItem: function (k, it) { itemPopup.openFor(k, it) }
                    Flow {
                        Layout.fillWidth: true; spacing: 10; visible: panel.canEdit
                        Repeater { model: Checklist.missingPresets(panel.night, 6)
                            delegate: Link { required property var modelData; text: "+ " + modelData; tone: Fq.faint
                                onClicked: panel.app.postItem(panel.night, { ns: "xyz.freequencies", kind: "gear", target: panel.night.id, data: { item: modelData, done: false } }, "") } }
                    }
                }
                ChecklistSection {
                    app: panel.app; night: panel.night; canEdit: panel.canEdit
                    kind: "post"; label: Fq.t("Social posts"); addLabel: Fq.t("+ post")
                    items: Checklist.postsOf(panel.night)
                    emptyText: Fq.t("Plan what goes out and when: announcement, line-up reveal, day-of stories, recap.")
                    meta: function (it) { return [it.d.channel || "", it.d.when ? Fq.fmtDateTime(new Date(it.d.when), "ddd d MMM hh:mm") : "unscheduled"].join(" · ") }
                    tone: function (it) { return Checklist.postDueSoon(it, Date.now()) ? Fq.warn : Fq.sub }
                    onEditItem: function (k, it) { itemPopup.openFor(k, it) }
                }
                PublicSection { app: panel.app; night: panel.night; canEdit: panel.canEdit; onMakePublic: publicPopup.open() }
                FormsSection { app: panel.app; night: panel.night; canEdit: panel.canEdit; onAddForm: formPopup.open(); onOpenAnswers: function (f) { responsesPopup.openFor(f) } }
                PollsSection { app: panel.app; night: panel.night; canEdit: panel.canEdit }
                NotesSection { app: panel.app; night: panel.night; canEdit: panel.canEdit }
            }
        }
    }

    // dialogs opened by the sections (aliased so the preview can drive them)
    property alias dlgArtist: artistPopup
    ArtistPopup { id: artistPopup; app: panel.app; night: panel.night }
    property alias dlgCrew: crewPopup
    CrewPopup { id: crewPopup; app: panel.app; night: panel.night }
    property alias dlgTickets: ticketsPopup
    TicketsPopup { id: ticketsPopup; app: panel.app; night: panel.night }
    property alias dlgPoster: posterPopup
    PosterPopup { id: posterPopup; app: panel.app; night: panel.night }
    property alias dlgItem: itemPopup
    ItemPopup { id: itemPopup; app: panel.app; night: panel.night }
    property alias dlgForm: formPopup
    FormPopup { id: formPopup; app: panel.app; night: panel.night; occ: panel.occ }
    ResponsesPopup { id: responsesPopup; app: panel.app }
    property alias dlgPublic: publicPopup
    PublicPopup { id: publicPopup; app: panel.app; night: panel.night }
    FileDialog { id: fileDialog; title: Fq.t("Attach a file to this event"); onAccepted: panel.app.uploadToNight(panel.night, fileDialog.selectedFile) }
}
