// Network: what collectives share with each other in Lisboa — a venue directory, a gear library,
// a crew pool and quick polls. One place, four tabs, one search box.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../.."
import "../sections"
import "../popups"
import "../lib/network.js" as Network
import "../lib/nights.js" as Nights

Item {
    id: nv
    objectName: "networkView"
    property var app
    property string tab: "venues"            // venues | gear | crew | polls
    property string query: ""
    property string skill: ""
    readonly property var anchor: app.networkAnchor
    readonly property string me: anchor ? app.meOn(anchor) : ""
    readonly property string today: Fq.fmtDate(new Date(app.nowTick), "yyyy-MM-dd").replace(/[^\d-]/g, "")
    readonly property var venues: Network.search(Network.list(anchor, "venue"), query)
    readonly property var gear: Network.search(Network.list(anchor, "gear"), query)
    readonly property var crew: Network.search(Network.list(anchor, "crew"), query).filter(function (c) { return !nv.skill || (c.d.skills || []).indexOf(nv.skill) >= 0 })
    readonly property var polls: anchor ? Network.pollsOf(anchor) : []
    readonly property var usedVenues: app.venuesInUse
    readonly property var missing: Network.missingVenues(usedVenues, Network.list(anchor, "venue"))
    property alias dlgNet: netPopup

    Flickable {
        anchors.fill: parent
        clip: true; contentWidth: width; contentHeight: col.implicitHeight + 40
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        ColumnLayout {
            id: col
            width: parent.width - 12; spacing: 12
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                DText { text: Fq.t("NETWORK"); size: 40; color: Fq.lime }
                Item { Layout.fillWidth: true }
                Repeater { model: [{ k: "venues", l: "Venues" }, { k: "gear", l: "Gear" }, { k: "crew", l: "Crew pool" }, { k: "polls", l: "Polls" }]
                    delegate: Chip { required property var modelData; text: Fq.t(modelData.l); on: nv.tab === modelData.k; onClicked: { nv.tab = modelData.k; nv.query = ""; search.text = "" } } }
            }
            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
                text: Fq.t("Shared between every collective in the Lisboa calendar: venues you know, gear you can lend, people who can work a shift.") }

            // not set up
            Rectangle {
                visible: !nv.anchor; Layout.fillWidth: true; Layout.preferredHeight: su.implicitHeight + 32; color: Fq.mantle; border.width: Fq.bw; border.color: Fq.line
                ColumnLayout { id: su; x: 16; y: 16; width: parent.width - 32; spacing: 8
                    DText { text: nv.app.communityCal ? Fq.t("START THE NETWORK") : Fq.t("FIRST, THE LISBOA CALENDAR"); size: 28 }
                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
                        text: nv.app.communityCal ? Fq.t("One click and everyone in Lisboa can share venues, gear, crew and polls here.")
                                                  : Fq.t("The Network lives in the shared Lisboa calendar. Set it up (or join it with its link) first.") }
                    FqButton { primary: true; text: nv.app.communityCal ? (nv.app.networkBusy ? Fq.t("Setting up…") : Fq.t("Start the network")) : (nv.app.lisboaBusy ? Fq.t("Setting up…") : Fq.t("Set up the Lisboa calendar"))
                        onClicked: nv.app.communityCal ? nv.app.setupNetwork() : nv.app.setupLisboa() } }
            }

            RowLayout {
                visible: !!nv.anchor; Layout.fillWidth: true; spacing: 8
                Field { id: search; Layout.fillWidth: true; placeholderText: nv.tab === "venues" ? Fq.t("Search venues: name, area, gear…") : nv.tab === "gear" ? Fq.t("Search gear…") : nv.tab === "crew" ? Fq.t("Search people…") : Fq.t("Search…")
                    visible: nv.tab !== "polls"; onTextChanged: nv.query = text }
                Item { visible: nv.tab === "polls"; Layout.fillWidth: true }
                FqButton { primary: true; text: nv.tab === "venues" ? Fq.t("+ Venue") : nv.tab === "gear" ? Fq.t("+ Gear") : nv.tab === "crew" ? Fq.t("+ Join the crew pool") : Fq.t("+ Poll")
                    onClicked: netPopup.openFor(nv.tab === "venues" ? "venue" : nv.tab === "polls" ? "poll" : nv.tab, null, null) }
            }

            // ── venues ──
            Flow { visible: !!nv.anchor && nv.tab === "venues" && nv.missing.length > 0; Layout.fillWidth: true; spacing: 6
                FText { text: Fq.t("From your events, not in the directory yet:"); color: Fq.faint; font.pixelSize: 12; height: 26; verticalAlignment: Text.AlignVCenter }
                Repeater { model: nv.missing.slice(0, 8)
                    delegate: Chip { required property var modelData; text: "+ " + modelData; onClicked: netPopup.openFor("venue", null, null, {}, { name: modelData }) } } }
            FText { visible: !!nv.anchor && nv.tab === "venues" && nv.venues.length === 0; color: Fq.sub; font.pixelSize: 13; text: nv.query ? Fq.t("Nothing matches “%1”.", [nv.query]) : Fq.t("No venues yet. Add the ones you know.") }
            GridLayout {
                visible: !!nv.anchor && nv.tab === "venues"; Layout.fillWidth: true; columns: Math.max(1, Math.floor(col.width / 320)); columnSpacing: -1; rowSpacing: -1
                Repeater { model: nv.venues
                    delegate: Rectangle {
                        id: vc
                        required property var modelData
                        readonly property var d: modelData.d
                        Layout.fillWidth: true; Layout.preferredHeight: vcc.implicitHeight + 26; color: Fq.mantle; border.width: Fq.bw; border.color: Fq.line
                        ColumnLayout { id: vcc; x: 14; y: 13; width: parent.width - 28; spacing: 3
                            RowLayout { Layout.fillWidth: true
                                DText { Layout.fillWidth: true; elide: Text.ElideRight; text: (vc.d.name || "").toUpperCase(); size: 26 }
                                Link { visible: vc.modelData.author === nv.me; text: Fq.t("edit"); tone: Fq.faint; onClicked: netPopup.openFor("venue", vc.modelData, null) } }
                            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText
                                text: [vc.d.area || "", vc.d.capacity ? Fq.t("%1 people", [vc.d.capacity]) : "", vc.d.deal || ""].filter(function (x) { return !!x }).join(" · ") }
                            FText { visible: !!vc.d.access; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 12; textFormat: Text.PlainText; text: "♿ " + (vc.d.access || "") }
                            FText { visible: !!vc.d.tech; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 12; textFormat: Text.PlainText; maximumLineCount: 3; elide: Text.ElideRight; text: vc.d.tech || "" }
                            FText { visible: !!vc.d.contact; Layout.fillWidth: true; color: Fq.acid; font.pixelSize: 12; textFormat: Text.PlainText; text: vc.d.contact || "" }
                            RowLayout { spacing: 14
                                Link { text: Fq.t("map ↗"); onClicked: Qt.openUrlExternally("https://www.openstreetmap.org/search?query=" + encodeURIComponent((vc.d.name || "") + ", " + (vc.d.area || "Lisboa"))) }
                                Link { visible: nv.usedVenues.some(function (u) { return u.toLowerCase() === (vc.d.name || "").toLowerCase() }); text: Fq.t("show events")
                                    onClicked: nv.app.showCalendar("timeline") } }
                        }
                    }
                }
            }

            // ── gear ──
            FText { visible: !!nv.anchor && nv.tab === "gear" && nv.gear.length === 0; color: Fq.sub; font.pixelSize: 13; text: nv.query ? Fq.t("Nothing matches “%1”.", [nv.query]) : Fq.t("Nothing to lend yet. Share what your collective can lend.") }
            Repeater {
                model: nv.tab === "gear" && nv.anchor ? nv.gear : []
                delegate: Rectangle {
                    id: gr
                    required property var modelData
                    readonly property var d: modelData.d
                    readonly property bool mine: modelData.author === nv.me
                    readonly property var reqs: Network.borrowsOf(nv.anchor, modelData.id)
                    readonly property bool out: Network.outOn(nv.anchor, modelData.id, nv.today)
                    Layout.fillWidth: true; Layout.preferredHeight: grc.implicitHeight + 22; color: Fq.mantle; border.width: Fq.bw; border.color: Fq.line
                    ColumnLayout { id: grc; x: 14; y: 11; width: parent.width - 28; spacing: 4
                        RowLayout { Layout.fillWidth: true; spacing: 10
                            FText { Layout.fillWidth: true; font.pixelSize: 15; font.bold: true; textFormat: Text.PlainText; text: (gr.d.qty > 1 ? gr.d.qty + " × " : "") + (gr.d.item || "") }
                            Badge { text: gr.out ? Fq.t("out today") : Fq.t("available today"); tone: gr.out ? Fq.warn : Fq.lime }
                            Link { visible: gr.mine; text: Fq.t("edit"); tone: Fq.faint; onClicked: netPopup.openFor("gear", gr.modelData, null) }
                            Link { visible: !gr.mine; text: Fq.t("ask to borrow"); onClicked: netPopup.openFor("borrow", null, null, { gear: gr.modelData.id }) } }
                        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText
                            text: [Fq.t("lent by %1", [gr.d.owner || "—"]), gr.d.contact || "", gr.d.notes || ""].filter(function (x) { return !!x }).join(" · ") }
                        Repeater { model: gr.reqs
                            delegate: RowLayout { required property var modelData; Layout.fillWidth: true; spacing: 8
                                FText { Layout.fillWidth: true; font.pixelSize: 12; textFormat: Text.PlainText
                                    text: modelData.d.who + " · " + modelData.d.from + (modelData.d.to && modelData.d.to !== modelData.d.from ? " → " + modelData.d.to : "") + (modelData.d.note ? " · " + modelData.d.note : "") }
                                Badge { text: Fq.t(modelData.status === "ok" ? "accepted" : modelData.status === "no" ? "declined" : modelData.status === "returned" ? "returned" : "waiting")
                                    tone: modelData.status === "ok" ? Fq.lime : modelData.status === "no" ? Fq.red : Fq.faint }
                                Row { visible: gr.mine; spacing: 10
                                    Link { text: Fq.t("accept"); onClicked: nv.app.postNet("reply", { borrow: modelData.id, status: "ok" }, "", Fq.t("Accepted")) }
                                    Link { text: Fq.t("decline"); tone: Fq.red; onClicked: nv.app.postNet("reply", { borrow: modelData.id, status: "no" }, "", Fq.t("Declined")) }
                                    Link { visible: modelData.status === "ok"; text: Fq.t("returned"); tone: Fq.faint; onClicked: nv.app.postNet("reply", { borrow: modelData.id, status: "returned" }, "", Fq.t("Marked as returned")) } } } }
                    }
                }
            }

            // ── crew pool ──
            Flow { visible: !!nv.anchor && nv.tab === "crew"; Layout.fillWidth: true; spacing: 6
                Chip { text: Fq.t("Everyone"); on: nv.skill === ""; onClicked: nv.skill = "" }
                Repeater { model: Network.SKILLS
                    delegate: Chip { required property var modelData; text: Fq.t(modelData); on: nv.skill === modelData; onClicked: nv.skill = (nv.skill === modelData ? "" : modelData) } } }
            FText { visible: !!nv.anchor && nv.tab === "crew" && nv.crew.length === 0; color: Fq.sub; font.pixelSize: 13; text: Fq.t("Nobody here yet. People add themselves: share this tab with your crew.") }
            GridLayout {
                visible: !!nv.anchor && nv.tab === "crew"; Layout.fillWidth: true; columns: Math.max(1, Math.floor(col.width / 300)); columnSpacing: -1; rowSpacing: -1
                Repeater { model: nv.crew
                    delegate: Rectangle {
                        id: cc
                        required property var modelData
                        readonly property var d: modelData.d
                        Layout.fillWidth: true; Layout.preferredHeight: ccc.implicitHeight + 22; color: Fq.mantle; border.width: Fq.bw; border.color: Fq.line
                        ColumnLayout { id: ccc; x: 14; y: 11; width: parent.width - 28; spacing: 4
                            RowLayout { Layout.fillWidth: true
                                FText { Layout.fillWidth: true; font.pixelSize: 15; font.bold: true; textFormat: Text.PlainText; text: cc.d.name || "" }
                                Link { visible: cc.modelData.author === nv.me; text: Fq.t("edit"); tone: Fq.faint; onClicked: netPopup.openFor("crew", cc.modelData, null) } }
                            Flow { Layout.fillWidth: true; spacing: 4
                                Repeater { model: cc.d.skills || []
                                    delegate: Badge { required property var modelData; text: Fq.t(modelData); tone: Fq.acid } } }
                            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText
                                text: [cc.d.when || "", cc.d.contact || "", cc.d.notes || ""].filter(function (x) { return !!x }).join(" · ") }
                        }
                    }
                }
            }

            // ── polls ──
            FText { visible: !!nv.anchor && nv.tab === "polls" && nv.polls.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
                text: Fq.t("Ask the whole scene: a date for a joint event, a cause for a benefit, a new venue to try. Polls on a single event live in its panel.") }
            Repeater { model: nv.tab === "polls" && nv.anchor ? nv.polls : []
                delegate: PollCard { required property var modelData; app: nv.app; host: nv.anchor; poll: modelData; onEdit: netPopup.openFor("poll", modelData, null) } }
        }
    }
    NetPopup { id: netPopup; app: nv.app }
}
