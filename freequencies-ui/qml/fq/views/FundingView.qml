// Funding: a shared library of winning applications (with their documents) and links to funders
// and open calls. Lives in its own "Funding library" calendar so the whole collective sees it.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../.."   // Field.qml
import "../popups"
import "../lib/funding.js" as Funding

Flickable {
    id: fv
    objectName: "fundingFlick"
    property var app
    property string tab: "apps"            // "apps" | "links"
    property string query: ""
    readonly property var cal: app.fundingCal
    readonly property var anchor: app.fundingAnchor
    readonly property string me: cal ? (cal.authorAddr || "") : ""
    readonly property var apps: Funding.appsOf(anchor).filter(function (x) { return Funding.matches(x, fv.query) })
    readonly property var links: Funding.linksOf(anchor, app.nowTick).filter(function (x) { return Funding.matches(x, fv.query) })
    clip: true; contentWidth: width; contentHeight: col.implicitHeight + 20
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}

    ColumnLayout {
        id: col
        width: fv.width - 12; spacing: 12

        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
            text: Fq.t("Applications that won, so the next one is easier to write, and the funders and open calls worth knowing. Shared with everyone in the library.") }

        // ── not set up yet ──
        ColumnLayout {
            visible: !fv.anchor; Layout.fillWidth: true; spacing: 10
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: setupCol.implicitHeight + 32; color: Fq.mantle; border.width: 1; border.color: Fq.line
                ColumnLayout {
                    id: setupCol
                    x: 16; y: 16; width: parent.width - 32; spacing: 8
                    DText { text: Fq.t("NO FUNDING LIBRARY YET"); size: 28 }
                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
                        text: Fq.t("Start one for your collective. It's a shared calendar of its own: invite people to it and they can read and add applications and links. Documents are sealed in Logos Storage, so only members can open them.") }
                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 12
                        text: Fq.t("Someone already started one? Ask them for an invite link and join it with \"Join calendar\" in the sidebar.") }
                    RowLayout { spacing: 8
                        FqButton { objectName: "fundSetup"; text: fv.app.fundingBusy ? Fq.t("Setting up…") : Fq.t("Start a funding library"); primary: true; enabled: !fv.app.fundingBusy; onClicked: fv.app.setupFunding() } }
                }
            }
        }

        // ── the library ──
        ColumnLayout {
            visible: !!fv.anchor; Layout.fillWidth: true; spacing: 10
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Chip { text: Fq.t("Winning applications (") + Funding.appsOf(fv.anchor).length + ")"; on: fv.tab === "apps"; onClicked: fv.tab = "apps" }
                Chip { text: Fq.t("Funding links (") + Funding.linksOf(fv.anchor, fv.app.nowTick).length + ")"; on: fv.tab === "links"; onClicked: fv.tab = "links" }
                Item { Layout.fillWidth: true }
                Link { text: Fq.t("invite people"); onClicked: fv.app.openShare(fv.cal) }
                FqButton { text: fv.tab === "apps" ? Fq.t("+ Application") : Fq.t("+ Link"); primary: true; onClicked: fundPopup.openFor(fv.tab === "apps" ? "fund-app" : "fund-link", null) }
            }
            Field { Layout.fillWidth: true; placeholderText: Fq.t("Search: funder, project, area, year…"); onTextChanged: fv.query = text }

            // winning applications
            FText { visible: fv.tab === "apps" && fv.apps.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 14
                text: fv.query ? Fq.t("Nothing matches “") + fv.query + "”." : Fq.t("No applications yet. Add one that won: the documents, who funded it, and what worked.") }
            Repeater {
                model: fv.tab === "apps" ? fv.apps : []
                delegate: Rectangle {
                    id: ac
                    required property var modelData
                    readonly property var d: modelData.d
                    Layout.fillWidth: true; Layout.preferredHeight: acc.implicitHeight + 28; color: Fq.mantle; border.width: 1; border.color: Fq.line
                    Rectangle { width: 4; height: parent.height; color: Fq.lime }
                    ColumnLayout {
                        id: acc
                        x: 18; y: 14; width: parent.width - 32; spacing: 4
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            DText { Layout.fillWidth: true; elide: Text.ElideRight; size: 26; text: (ac.d.title || "").toUpperCase() }
                            Badge { visible: !!ac.d.year; text: ac.d.year ? String(ac.d.year) : "" }
                        }
                        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13; textFormat: Text.PlainText
                            text: [ac.d.funder, Funding.amountLabel(ac.d), ac.d.area, ac.d.applicant ? Fq.t("by ") + ac.d.applicant : ""].filter(function (x) { return !!x }).join("  ·  ") }
                        FText { visible: !!ac.d.notes; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText; text: ac.d.notes || "" }
                        Flow {
                            Layout.fillWidth: true; Layout.topMargin: 4; spacing: 14
                            Repeater { model: ac.d.docs || []
                                delegate: Link { required property var modelData
                                    readonly property bool ok: Funding.docAvailable(fv.anchor, modelData.cid)
                                    text: "↓ " + modelData.name + (ok ? "" : Fq.t(" (removed)")); tone: ok ? Fq.acid : Fq.faint
                                    onClicked: if (ok) fv.app.openAttachment(fv.anchor.calendarId, modelData.cid, modelData.name) } }
                            Link { visible: !!ac.d.url; text: Fq.t("link ↗"); onClicked: Qt.openUrlExternally(ac.d.url) }
                            Link { visible: ac.modelData.author === fv.me; text: Fq.t("edit"); tone: Fq.faint; onClicked: fundPopup.openFor("fund-app", ac.modelData) }
                        }
                    }
                }
            }

            // funding links
            FText { visible: fv.tab === "links" && fv.links.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 14
                text: fv.query ? Fq.t("Nothing matches “") + fv.query + "”." : Fq.t("No links yet. Add funders and open calls, with their deadlines.") }
            Repeater {
                model: fv.tab === "links" ? fv.links : []
                delegate: Rectangle {
                    id: lc
                    required property var modelData
                    readonly property var d: modelData.d
                    readonly property string st: Funding.deadlineState(d, fv.app.nowTick)
                    readonly property var nLeft: Funding.daysLeft(d, fv.app.nowTick)
                    Layout.fillWidth: true; Layout.preferredHeight: lcc.implicitHeight + 24; color: Fq.mantle; border.width: 1; border.color: Fq.line
                    opacity: lc.st === "closed" ? 0.6 : 1
                    Rectangle { width: 4; height: parent.height; color: lc.st === "soon" ? Fq.warn : lc.st === "closed" ? Fq.faint : Fq.signal }
                    ColumnLayout {
                        id: lcc
                        x: 18; y: 12; width: parent.width - 32; spacing: 3
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            FText { Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 15; font.bold: true; textFormat: Text.PlainText; text: lc.d.name || "" }
                            Badge {
                                visible: lc.st !== ""
                                tone: lc.st === "soon" ? Fq.warn : lc.st === "closed" ? Fq.faint : Fq.signal
                                text: lc.st === "closed" ? Fq.t("closed")
                                    : lc.d.deadline ? (lc.nLeft <= 1 ? "closes today" : "closes in " + lc.nLeft + " days")
                                    : "rolling"
                            }
                        }
                        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText
                            text: [lc.d.deadline ? Fq.t("Deadline ") + Fq.fmtDate(new Date(lc.d.deadline + Fq.t("T12:00:00")), "d MMM yyyy") : "", lc.d.amount || "", lc.d.area || ""].filter(function (x) { return !!x }).join("  ·  ") }
                        FText { visible: !!lc.d.notes; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText; text: lc.d.notes || "" }
                        Flow {
                            Layout.fillWidth: true; Layout.topMargin: 3; spacing: 14
                            Link { text: Fq.t("open ↗"); onClicked: Qt.openUrlExternally(lc.d.url) }
                            Link { visible: lc.modelData.author === fv.me; text: Fq.t("edit"); tone: Fq.faint; onClicked: fundPopup.openFor("fund-link", lc.modelData) }
                        }
                    }
                }
            }
        }
    }

    property alias dlgFund: fundPopup
    FundPopup { id: fundPopup; app: fv.app }
}
