// Resources: the Funding library, the Legal toolkit (legal form, papers for an event, your rights,
// help now, inspections log) and Lessons learnt shared by other collectives.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../.."
import "../popups"
import "../lib/legal.js" as Legal
import "../lib/legal-content.js" as LC
import "../lib/network.js" as Network
import "../lib/ext.js" as Ext

Rectangle {
    id: rs
    objectName: "resourcesView"
    property var app
    color: Fq.ground
    property string tab: "legal"             // funding | legal | lessons
    property string part: "form"             // form | papers | rights | help | log
    property var answers: ({})
    property string query: ""
    readonly property string lang: Fq.lang
    readonly property var rec: Legal.recommendForm(answers)
    readonly property var log: Legal.inspectionsOf(app.freqNights)
    readonly property var pats: Legal.patterns(log)
    readonly property var lessons: app.networkAnchor ? Network.search(Ext.itemsOf(app.networkAnchor, "lesson"), query) : []
    readonly property var shared: app.networkAnchor ? Ext.itemsOf(app.networkAnchor, "inspect-pattern") : []
    function t(x) { return Legal.txt(x, rs.lang) }
    function setA(k, v) { var a = {}; for (var x in answers) a[x] = answers[x]; a[k] = v; answers = a }
    property alias dlgInspection: inspectionPopup

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 12
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            DText { text: Fq.t("RESOURCES"); size: 40; color: Fq.lime }
            Item { Layout.fillWidth: true }
            Chip { text: Fq.t("Legal toolkit"); on: rs.tab === "legal"; onClicked: rs.tab = "legal" }
            Chip { text: Fq.t("Funding"); on: rs.tab === "funding"; onClicked: rs.tab = "funding" }
            Chip { text: Fq.t("Lessons learnt"); on: rs.tab === "lessons"; onClicked: rs.tab = "lessons" }
        }

        // ── funding library ──
        FundingView { visible: rs.tab === "funding"; app: rs.app; Layout.fillWidth: true; Layout.fillHeight: true }

        // ── legal toolkit ──
        ColumnLayout {
            visible: rs.tab === "legal"; Layout.fillWidth: true; Layout.fillHeight: true; spacing: 10
            Rectangle {   // the review badge
                Layout.fillWidth: true; Layout.preferredHeight: rb.implicitHeight + 14; color: "transparent"; border.width: Fq.bw; border.color: LC.REVIEWED ? Fq.line : Fq.warn
                FText { id: rb; x: 10; y: 7; width: parent.width - 20; wrapMode: Text.Wrap; font.pixelSize: 12; color: LC.REVIEWED ? Fq.sub : Fq.warn
                    text: (LC.REVIEWED ? "" : Fq.t("DRAFT, UNDER LEGAL REVIEW. ")) + Fq.t("Legal information, not legal advice: for your case, talk to a lawyer. Last checked %1.", [LC.LAST_CHECKED]) }
            }
            Flow { Layout.fillWidth: true; spacing: 6
                Repeater { model: [{ k: "form", l: "Your legal form" }, { k: "papers", l: "Papers for an event" }, { k: "rights", l: "Your rights during an inspection" },
                                   { k: "help", l: "Help now" }, { k: "log", l: "Inspections log" }]
                    delegate: Chip { required property var modelData; text: Fq.t(modelData.l); on: rs.part === modelData.k; accent: modelData.k === "help" ? Fq.red : Fq.lime; onClicked: rs.part = modelData.k } } }

            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; contentWidth: width; contentHeight: lc.implicitHeight + 30
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {}
                ColumnLayout {
                    id: lc
                    width: parent.width - 12; spacing: 10

                    // your legal form: five questions → a recommendation
                    ColumnLayout {
                        visible: rs.part === "form"; Layout.fillWidth: true; spacing: 8
                        Repeater {
                            model: [{ k: "money", q: "How much money goes through your events in a year?", o: [["none", "Almost none"], ["some", "Some (bar, small fees)"], ["lots", "A lot (tickets, artist fees, grants)"]] },
                                    { k: "funding", q: "Do you want to apply for public funding (DGArtes, Câmara, Gulbenkian…)?", o: [[true, "Yes"], [false, "No"]] },
                                    { k: "contracts", q: "Do you sign contracts or rent spaces in your group's name?", o: [[true, "Yes"], [false, "No"]] },
                                    { k: "profit", q: "Do you want to make a profit and share it?", o: [[true, "Yes"], [false, "No, it all goes back into the project"]] },
                                    { k: "people", q: "How many people organise with you?", o: [["few", "A few friends"], ["many", "A group that changes over time"]] }]
                            delegate: ColumnLayout { id: qd; required property var modelData; Layout.fillWidth: true; spacing: 4
                                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 14; text: Fq.t(qd.modelData.q) }
                                Flow { Layout.fillWidth: true; spacing: 6
                                    Repeater { model: qd.modelData.o
                                        delegate: Chip { required property var modelData
                                            text: Fq.t(modelData[1]); on: rs.answers[qd.modelData.k] === modelData[0]; onClicked: rs.setA(qd.modelData.k, modelData[0]) } } } }
                        }
                        Rectangle {
                            readonly property var f: LC.FORMS[rs.rec.form === "association-later" ? "association" : rs.rec.form]
                            visible: Object.keys(rs.answers).length >= 3 && !!f
                            Layout.fillWidth: true; Layout.preferredHeight: fr.implicitHeight + 28; color: Fq.mantle; border.width: Fq.bw; border.color: Fq.lime
                            ColumnLayout { id: fr; x: 14; y: 14; width: parent.width - 28; spacing: 6
                                FText { font.pixelSize: 12; color: Fq.faint; text: Fq.t("WHAT FITS YOU") }
                                DText { Layout.fillWidth: true; wrapMode: Text.Wrap; size: 30; text: parent.parent.f ? rs.t(parent.parent.f.title).toUpperCase() : "" }
                                FText { visible: rs.rec.form === "association-later"; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.warn; font.pixelSize: 13
                                    text: Fq.t("Not urgent yet: staying informal is fine for now, but plan an association before money, contracts or funding grow.") }
                                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13; textFormat: Text.PlainText; text: parent.parent.f ? rs.t(parent.parent.f.body) : "" }
                                Repeater { model: parent.parent.f ? (parent.parent.f.sources || []) : []
                                    delegate: Link { required property var modelData; text: "↗ " + modelData; onClicked: Qt.openUrlExternally(modelData) } }
                            }
                        }
                        Sec { label: Fq.t("All the options") }
                        Repeater { model: Object.keys(LC.FORMS)
                            delegate: ColumnLayout { required property var modelData; readonly property var f: LC.FORMS[modelData]; Layout.fillWidth: true; spacing: 3
                                FText { font.pixelSize: 14; font.bold: true; text: rs.t(f.title) }
                                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText; text: rs.t(f.body) } } }
                    }

                    // papers for an event
                    ColumnLayout {
                        visible: rs.part === "papers"; Layout.fillWidth: true; spacing: 8
                        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
                            text: Fq.t("What an event in Lisbon may need. Production's plans include a Licences table to tick these off per event.") }
                        Repeater { model: LC.PAPERS
                            delegate: Rectangle { id: pp; required property var modelData
                                Layout.fillWidth: true; Layout.preferredHeight: ppc.implicitHeight + 22; color: Fq.mantle; border.width: Fq.bw; border.color: Fq.line
                                ColumnLayout { id: ppc; x: 14; y: 11; width: parent.width - 28; spacing: 4
                                    RowLayout { Layout.fillWidth: true
                                        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 15; font.bold: true; text: rs.t(pp.modelData.title) }
                                        Badge { visible: pp.modelData.uncertain === true; text: Fq.t("to confirm"); tone: Fq.warn } }
                                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13; textFormat: Text.PlainText; text: rs.t(pp.modelData.what) }
                                    GridLayout { Layout.fillWidth: true; columns: 2; columnSpacing: 12; rowSpacing: 2
                                        Repeater { model: [["Who", pp.modelData.who], ["How long", pp.modelData.time], ["Cost", pp.modelData.cost], ["Without it", pp.modelData.without]]
                                            delegate: RowLayout { required property var modelData; visible: !!modelData[1]; Layout.fillWidth: true; Layout.columnSpan: 2; spacing: 8
                                                FText { Layout.preferredWidth: 90; color: Fq.faint; font.pixelSize: 12; text: Fq.t(modelData[0]) }
                                                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 12; textFormat: Text.PlainText; text: rs.t(modelData[1]) } } } }
                                    Flow { Layout.fillWidth: true; spacing: 12
                                        Repeater { model: pp.modelData.sources || []
                                            delegate: Link { required property var modelData; text: "↗ " + modelData.replace(/^https?:\/\//, "").slice(0, 60); onClicked: Qt.openUrlExternally(modelData) } } }
                                }
                            }
                        }
                    }

                    // your rights during an inspection
                    ColumnLayout {
                        visible: rs.part === "rights"; Layout.fillWidth: true; spacing: 8
                        RowLayout { Layout.fillWidth: true
                            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13; text: Fq.t("Stay calm, be polite, keep it short. These are your rights and theirs.") }
                            FqButton { primary: true; text: Fq.t("Copy the door sheet"); onClicked: rs.app.copyText(rs.t(LC.DOOR_SHEET)) } }
                        Repeater { model: LC.RIGHTS
                            delegate: ColumnLayout { required property var modelData; Layout.fillWidth: true; spacing: 3
                                RowLayout { Layout.fillWidth: true
                                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 14; font.bold: true; text: rs.t(modelData.title) }
                                    Badge { visible: modelData.uncertain === true; text: Fq.t("to confirm"); tone: Fq.warn } }
                                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13; textFormat: Text.PlainText; text: rs.t(modelData.body) }
                                FText { visible: !!modelData.basis; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 11; textFormat: Text.PlainText; text: modelData.basis || "" }
                                Flow { Layout.fillWidth: true; spacing: 12
                                    Repeater { model: modelData.sources || []
                                        delegate: Link { required property var modelData; text: "↗ " + modelData.replace(/^https?:\/\//, "").slice(0, 60); onClicked: Qt.openUrlExternally(modelData) } } } } }
                    }

                    // help now
                    ColumnLayout {
                        visible: rs.part === "help"; Layout.fillWidth: true; spacing: 8
                        Repeater { model: LC.HELP
                            delegate: Rectangle { required property var modelData
                                Layout.fillWidth: true; Layout.preferredHeight: hc.implicitHeight + 18; color: Fq.mantle; border.width: Fq.bw; border.color: modelData.urgent ? Fq.red : Fq.line
                                RowLayout { id: hc; x: 14; y: 9; width: parent.width - 28; spacing: 14
                                    DText { text: modelData.number; size: 30; color: modelData.urgent ? Fq.red : Fq.lime; Layout.preferredWidth: 170 }
                                    ColumnLayout { Layout.fillWidth: true; spacing: 1
                                        FText { font.pixelSize: 14; font.bold: true; text: modelData.name }
                                        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; text: rs.t(modelData.what) } }
                                    Link { visible: !!modelData.url; text: "↗"; onClicked: Qt.openUrlExternally(modelData.url) } } } }
                        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 12
                            text: Fq.t("Each event can have its own on-call contact and lawyer: add them in the event's Details. The red HELP button (bottom right) opens this list from anywhere.") }
                    }

                    // inspections log
                    ColumnLayout {
                        visible: rs.part === "log"; Layout.fillWidth: true; spacing: 8
                        RowLayout { Layout.fillWidth: true
                            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
                                text: Fq.t("After an inspection, note who came and what they checked. Private to your collective; no names of officers or guests. Over time you learn what inspectors actually look for.") }
                            FqButton { primary: true; text: Fq.t("+ Inspection"); onClicked: inspectionPopup.openFor(null, null) } }
                        Sec { visible: rs.pats.length > 0; label: Fq.t("What they checked (%1 visits)", [rs.log.length]) }
                        Repeater { model: rs.pats
                            delegate: RowLayout { required property var modelData; Layout.fillWidth: true; spacing: 10
                                FText { Layout.preferredWidth: 160; font.pixelSize: 13; text: Fq.t(modelData.check) }
                                Rectangle { Layout.preferredWidth: Math.max(4, (lc.width - 260) * modelData.n / modelData.of); Layout.preferredHeight: 12; color: Fq.warn }
                                FText { font.pixelSize: 12; color: Fq.sub; text: modelData.n + " / " + modelData.of } } }
                        Repeater { model: rs.log
                            delegate: Rectangle { required property var modelData
                                Layout.fillWidth: true; Layout.preferredHeight: ic.implicitHeight + 16; color: Fq.mantle; border.width: Fq.bw; border.color: Fq.line
                                ColumnLayout { id: ic; x: 12; y: 8; width: parent.width - 24; spacing: 2
                                    FText { font.pixelSize: 13; font.bold: true; textFormat: Text.PlainText
                                        text: Fq.fmtDate(new Date(modelData.at), "d MMM yyyy") + " · " + Fq.t(modelData.d.body) + " · " + Fq.t(modelData.d.outcome) + " · " + (modelData.ev.title || "") }
                                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText
                                        text: (modelData.d.checked || []).map(function (c) { return Fq.t(c) }).join(", ") + (modelData.d.note ? " — " + modelData.d.note : "") } } } }
                        Sec { visible: rs.shared.length > 0; label: Fq.t("Shared by other collectives (anonymous)") }
                        Repeater { model: rs.shared
                            delegate: FText { required property var modelData; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText
                                text: modelData.d.month + (modelData.d.area ? " · " + modelData.d.area : "") + " · " + Fq.t(modelData.d.body) + " · " + (modelData.d.checked || []).map(function (c) { return Fq.t(c) }).join(", ") + " · " + Fq.t(modelData.d.outcome) } }
                    }
                }
            }
        }

        // ── lessons learnt ──
        ColumnLayout {
            visible: rs.tab === "lessons"; Layout.fillWidth: true; Layout.fillHeight: true; spacing: 8
            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
                text: Fq.t("What worked and what to change, shared by collectives from their debriefs (Production → Debrief → share with Lisboa).") }
            Field { Layout.fillWidth: true; placeholderText: Fq.t("Search lessons: money, door, sound…"); onTextChanged: rs.query = text }
            FText { visible: !rs.app.networkAnchor; color: Fq.sub; font.pixelSize: 13; text: Fq.t("Lessons are shared through the Network: start it in the Network tab.") }
            FText { visible: !!rs.app.networkAnchor && rs.lessons.length === 0; color: Fq.sub; font.pixelSize: 13; text: Fq.t("No lessons shared yet.") }
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
                model: rs.lessons.length
                delegate: Rectangle { required property int index; readonly property var l: rs.lessons[index]
                    width: ListView.view.width; height: lcol.implicitHeight + 18; color: Fq.mantle; border.width: Fq.bw; border.color: Fq.line
                    ColumnLayout { id: lcol; x: 12; y: 9; width: parent.width - 24; spacing: 3
                        FText { font.pixelSize: 14; font.bold: true; textFormat: Text.PlainText; text: (parent.parent.l.d.topic || Fq.t("Lesson")) + (parent.parent.l.d.format ? " · " + parent.parent.l.d.format : "") }
                        FText { visible: !!parent.parent.l.d.worked; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13; textFormat: Text.PlainText; text: "✓ " + (parent.parent.l.d.worked || "") }
                        FText { visible: !!parent.parent.l.d.change; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.warn; font.pixelSize: 13; textFormat: Text.PlainText; text: "→ " + (parent.parent.l.d.change || "") } } }
            }
        }
    }
    InspectionPopup { id: inspectionPopup; app: rs.app }
}
