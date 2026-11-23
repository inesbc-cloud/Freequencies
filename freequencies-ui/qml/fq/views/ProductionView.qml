// Production: the working plan for each night. Pick a format and the plan builds itself: a timeline
// counted back from show day, team, venue checks, run of show, risks, debrief, plus the night's
// line-up, crew, budget, tickets, posts and gear as modules. Shared with every co-organiser.
// Structure after Louisa Prog's INTERSECT production office.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import ".."
import "../.."
import "../sections"
import "../popups"
import "../lib/production.js" as Production
import "../lib/nights.js" as Nights
import "../lib/checklist.js" as Checklist

Rectangle {
    id: pv
    objectName: "productionView"
    property var app
    color: Fq.ground
    property string mod: ""
    readonly property double now: app.nowTick
    // Freequencies nights: upcoming first (soonest), then the last month's.
    readonly property var nights: {
        var ns = app.freqNights.filter(function (n) { return n.startTime > now - 30 * 86400000 || (n.recur && n.recur.freq) })
        var up = ns.filter(function (n) { return n.startTime >= now - 86400000 }).sort(function (a, b) { return a.startTime - b.startTime })
        var past = ns.filter(function (n) { return n.startTime < now - 86400000 }).sort(function (a, b) { return b.startTime - a.startTime })
        return up.concat(past)
    }
    readonly property var night: app.prodNight || (nights.length ? nights[0] : null)
    readonly property var cal: night ? app.calById(night.calendarId) : null
    readonly property bool canEdit: Nights.canEdit(night, cal)
    readonly property var plan: Production.planOf(night)
    readonly property var mods: Production.modulesOf(plan)
    readonly property string cur: mods.indexOf(mod) >= 0 ? mod : (mods.length ? mods[0] : "")
    readonly property var curDef: plan && cur ? Production.moduleDef(plan, cur) : null
    property bool adding: false

    RowLayout {
        anchors.fill: parent; spacing: 0

        // ── nights ──
        Rectangle {
            Layout.preferredWidth: 300; Layout.fillHeight: true; color: Fq.mantle
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Fq.line }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 14; spacing: 8
                DText { text: "PRODUCTION"; font.pixelSize: 34; color: Fq.lime }
                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; text: "A working plan for each event, shared with everyone organising it." }
                FText { visible: pv.nights.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13; text: "No events yet. Add one with + Event." }
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    contentWidth: width; contentHeight: nlist.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {}
                    Column {
                    id: nlist
                    width: parent.width; spacing: 4
                    Repeater {
                    model: pv.nights
                    delegate: Rectangle {
                        id: nr
                        required property int index
                        readonly property var modelData: pv.nights[index]   // the real object: modelData's nested arrays aren't JS arrays
                        readonly property var pl: Production.planOf(modelData)
                        readonly property var pg: pl ? Production.progress(modelData, pl) : null
                        readonly property bool sel: pv.night && pv.night.id === modelData.id
                        width: nlist.width; height: nrc.implicitHeight + 14
                        color: sel ? Fq.surface2 : nrMA.containsMouse ? Fq.surface : "transparent"; border.width: 1; border.color: sel ? Fq.lime : Fq.line
                        MouseArea { id: nrMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pv.app.prodNightId = nr.modelData.id }
                        ColumnLayout {
                            id: nrc
                            x: 10; y: 7; width: parent.width - 20; spacing: 2
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                DText { text: Qt.formatDate(new Date(nr.modelData.startTime), "dd.MM"); font.pixelSize: 22; color: nr.modelData.startTime < pv.now ? Fq.faint : Fq.text }
                                FText { Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 13; textFormat: Text.PlainText; text: nr.modelData.title || "(untitled)" }
                            }
                            FText { Layout.fillWidth: true; elide: Text.ElideRight; color: Fq.sub; font.pixelSize: 11
                                text: nr.pl ? Production.FORMATS[nr.pl.format].label + " · " + nr.pg.done + "/" + nr.pg.total + " done" : "no plan yet" }
                            Rectangle { visible: !!nr.pg && nr.pg.total > 0; Layout.fillWidth: true; Layout.preferredHeight: 3; color: Fq.line
                                Rectangle { height: parent.height; width: nr.pg && nr.pg.total ? parent.width * nr.pg.done / nr.pg.total : 0; color: Fq.lime } }
                        }
                    }
                }
                    }
                }
            }
        }

        // ── the plan ──
        Flickable {
            id: flick
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; contentWidth: width; contentHeight: main.implicitHeight + 40
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            ColumnLayout {
                id: main
                x: 22; y: 18; width: flick.width - 44; spacing: 12
                visible: !!pv.night

                // the night
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: -4
                        FText { text: pv.night ? Qt.formatDate(new Date(pv.night.startTime), "dddd d MMMM yyyy").toUpperCase() + "  ·  " + (Nights.fieldOf(pv.night, "venue") || "no venue") : ""
                            color: Fq.sub; font.pixelSize: 12; font.letterSpacing: 1.2 }
                        DText { Layout.fillWidth: true; elide: Text.ElideRight; text: pv.night ? (pv.night.title || "(untitled)").toUpperCase() : ""; font.pixelSize: 40 }
                    }
                    Badge { visible: !!pv.plan; text: pv.plan ? Production.FORMATS[pv.plan.format].label : "" }
                    Link { text: "open in calendar"; onClicked: pv.app.openOccurrence(pv.night) }
                }
                FText { visible: !!pv.night && !pv.canEdit; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.warn; font.pixelSize: 12
                    text: "Read-only: you're a " + Nights.roleOf(pv.cal) + " on this calendar." }

                // no plan yet: pick a format
                ColumnLayout {
                    visible: !!pv.night && !pv.plan; Layout.fillWidth: true; spacing: 10
                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 14
                        text: "What kind of event is it? Pick a format and Freequencies builds the plan: a timeline counted back from the date, the modules it needs, and a starting checklist. Change anything after." }
                    GridLayout {
                        Layout.fillWidth: true; columns: Math.max(1, Math.floor(main.width / 260)); columnSpacing: -1; rowSpacing: -1
                        Repeater {
                            model: Production.FORMAT_ORDER
                            delegate: Rectangle {
                                id: fc
                                required property var modelData
                                readonly property var f: Production.FORMATS[modelData]
                                Layout.fillWidth: true; Layout.preferredHeight: 118
                                color: fcMA.containsMouse && pv.canEdit ? Fq.surface2 : Fq.mantle; border.width: 1; border.color: Fq.line
                                MouseArea { id: fcMA; objectName: "format_" + fc.modelData; anchors.fill: parent; hoverEnabled: true; enabled: pv.canEdit && !pv.app.planBusy
                                    cursorShape: Qt.PointingHandCursor; onClicked: pv.app.createPlan(pv.night, fc.modelData) }
                                ColumnLayout {
                                    id: fcc
                                    x: 14; y: 13; width: parent.width - 28; spacing: 3
                                    DText { text: fc.f.label.toUpperCase(); font.pixelSize: 24 }
                                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; text: fc.f.blurb }
                                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 11
                                        text: fc.f.modules.length + " modules · " + fc.f.milestones.length + " milestones" }
                                }
                            }
                        }
                    }
                    FText { visible: pv.app.planBusy; text: "Building the plan…"; color: Fq.warn; font.pixelSize: 12 }
                }

                // the plan: module tabs
                Flow {
                    visible: !!pv.plan; Layout.fillWidth: true; spacing: 6
                    Repeater { model: pv.mods
                        delegate: Chip { required property var modelData; text: Production.moduleDef(pv.plan, modelData).t; on: pv.cur === modelData; onClicked: pv.mod = modelData } }
                    Chip { visible: pv.canEdit; text: pv.adding ? "− close" : "+ module"; accent: Fq.signal; onClicked: pv.adding = !pv.adding }
                }
                // add / remove modules, custom modules
                Rectangle {
                    visible: !!pv.plan && pv.adding; Layout.fillWidth: true; Layout.preferredHeight: addc.implicitHeight + 24; color: Fq.mantle; border.width: 1; border.color: Fq.line
                    ColumnLayout {
                        id: addc
                        x: 12; y: 12; width: parent.width - 24; spacing: 8
                        Label_ { text: "ADD A MODULE" }
                        Flow { Layout.fillWidth: true; spacing: 6
                            Repeater { model: pv.plan ? Production.missingModules(pv.plan) : []
                                delegate: Chip { required property var modelData; text: "+ " + Production.MODULES[modelData].t
                                    onClicked: { var p = JSON.parse(JSON.stringify(pv.plan)); p.modules.push(modelData); pv.app.setPlan(pv.night, p, "Added " + Production.MODULES[modelData].t); pv.mod = modelData } } } }
                        Label_ { text: "OR BUILD YOUR OWN" }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Field { id: cmName; Layout.preferredWidth: 160; placeholderText: "Name, e.g. Merch" }
                            Field { id: cmCols; Layout.fillWidth: true; placeholderText: "Columns: Item, Qty:num, Price:money, Done:check" }
                            FqButton { text: "Create"; onClicked: {
                                var r = Production.customModule(cmName.text, cmCols.text)
                                if (r.error) { pv.app.notify(r.error, true); return }
                                var p = JSON.parse(JSON.stringify(pv.plan)); p.custom.push(r.module); p.modules.push(r.module.id)
                                pv.app.setPlan(pv.night, p, "Module " + r.module.name + " added"); pv.mod = r.module.id; cmName.text = ""; cmCols.text = ""
                            } }
                        }
                        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 11; text: "Column types: text, long, num, money, date, time, check." }
                        Link { visible: pv.cur !== ""; text: "remove the " + (pv.curDef ? pv.curDef.t : "") + " module from this plan (its rows are kept)"; tone: Fq.red
                            onClicked: { var p = JSON.parse(JSON.stringify(pv.plan)); p.modules = p.modules.filter(function (m) { return m !== pv.cur }); pv.app.setPlan(pv.night, p, "Module removed") } }
                    }
                }

                // the current module
                ColumnLayout {
                    visible: !!pv.curDef; Layout.fillWidth: true; spacing: 18
                    Repeater {
                        model: pv.curDef && pv.curDef.tables ? pv.curDef.tables : []
                        delegate: ProdTable { required property var modelData; app: pv.app; night: pv.night; plan: pv.plan; table: modelData; canEdit: pv.canEdit
                            onEditRow: function (t, r) { rowPopup.openFor(pv.night, t, r) } }
                    }
                    // the night's own sections, as modules
                    LineupSection { visible: pv.curDef && pv.curDef.section === "lineup"; app: pv.app; night: pv.night; canEdit: pv.canEdit; onEditArtist: function (b) { artistPopup.openFor(b) } }
                    CrewSection { visible: pv.curDef && pv.curDef.section === "crew"; app: pv.app; night: pv.night; canEdit: pv.canEdit; onEditCrew: function (c) { crewPopup.openFor(c) } }
                    BudgetSection { visible: pv.curDef && pv.curDef.section === "budget"; app: pv.app; night: pv.night; canEdit: pv.canEdit; onEditLine: function (l) { itemPopup.openFor("budget", l) } }
                    TicketsSection { visible: pv.curDef && pv.curDef.section === "tickets"; app: pv.app; night: pv.night; canEdit: pv.canEdit; onEditTickets: ticketsPopup.openFor() }
                    FilesSection { visible: pv.curDef && pv.curDef.section === "files"; app: pv.app; night: pv.night; canEdit: pv.canEdit; onUpload: fileDialog.open() }
                    ChecklistSection {
                        visible: pv.curDef && pv.curDef.section === "posts"
                        app: pv.app; night: pv.night; canEdit: pv.canEdit
                        kind: "post"; label: "Social posts"; addLabel: "+ post"
                        items: Checklist.postsOf(pv.night)
                        emptyText: "Plan what goes out and when: announcement, line-up reveal, day-of stories, recap."
                        meta: function (it) { return [it.d.channel || "", it.d.when ? Qt.formatDateTime(new Date(it.d.when), "ddd d MMM hh:mm") : "unscheduled"].join(" · ") }
                        tone: function (it) { return Checklist.postDueSoon(it, Date.now()) ? Fq.warn : Fq.sub }
                        onEditItem: function (k, it) { itemPopup.openFor(k, it) }
                    }
                    ChecklistSection {
                        visible: pv.curDef && pv.curDef.section === "gear"
                        app: pv.app; night: pv.night; canEdit: pv.canEdit
                        kind: "gear"; label: "Gear (" + Checklist.packedCount(pv.night) + "/" + Checklist.gearOf(pv.night).length + " packed)"; addLabel: "+ item"
                        items: Checklist.gearOf(pv.night)
                        onEditItem: function (k, it) { itemPopup.openFor(k, it) }
                    }
                }
            }
        }
    }

    RowPopup { id: rowPopup; app: pv.app }
    ArtistPopup { id: artistPopup; app: pv.app; night: pv.night }
    CrewPopup { id: crewPopup; app: pv.app; night: pv.night }
    TicketsPopup { id: ticketsPopup; app: pv.app; night: pv.night }
    ItemPopup { id: itemPopup; app: pv.app; night: pv.night }
    FileDialog { id: fileDialog; title: "Attach a file to this event"; onAccepted: pv.app.uploadToNight(pv.night, fileDialog.selectedFile) }
}
