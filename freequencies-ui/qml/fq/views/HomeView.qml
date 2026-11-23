// Home: what needs you today, and what's coming up. The first thing you see.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../lib/home.js" as Home
import "../lib/nights.js" as Nights
import "../lib/production.js" as Production
import "../lib/details.js" as Details
import "../lib/listings.js" as Listings

Rectangle {
    id: hv
    objectName: "homeView"
    property var app
    color: Fq.ground
    readonly property double now: app.nowTick
    readonly property var occs: app.expandEvents(app.freqNights, now - 86400000, now + 60 * 86400000)
    readonly property var items: Home.attention(occs, app.fundingAnchor, now)
    readonly property var soon: Home.upcoming(occs, now, 21)
    readonly property var st: Home.stats(occs, now)
    readonly property var elsewhere: app.listingEvents.filter(function (e) { return e.startTime >= now - 3600000 && e.startTime <= now + 7 * 86400000 }).sort(function (a, b) { return a.startTime - b.startTime }).slice(0, 8)
    function toneColor(t) { return t === "red" ? Fq.red : t === "warn" ? Fq.warn : Fq.signal }

    Flickable {
        anchors.fill: parent; anchors.margins: 20
        clip: true; contentWidth: width; contentHeight: col.implicitHeight + 20
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        ColumnLayout {
            id: col
            width: parent.width - 12; spacing: 16

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                ColumnLayout {
                    spacing: -4
                    FText { text: Qt.formatDate(new Date(hv.now), "dddd d MMMM").toUpperCase(); color: Fq.sub; font.pixelSize: 12; font.letterSpacing: 1.4 }
                    DText { text: hv.items.length ? hv.items.length + (hv.items.length === 1 ? " THING NEEDS YOU" : " THINGS NEED YOU") : "ALL CALM"; font.pixelSize: 44; color: Fq.lime }
                }
                Item { Layout.fillWidth: true }
                FqButton { text: "+ Event"; primary: true; onClicked: hv.app.openQuickNight() }
                FqButton { text: "Production"; onClicked: hv.app.openProduction(null) }
                FqButton { text: "Calendar"; onClicked: hv.app.showCalendar("month") }
            }

            // numbers
            GridLayout {
                Layout.fillWidth: true; columns: Math.max(2, Math.min(4, Math.floor(col.width / 220))); columnSpacing: -1; rowSpacing: -1
                Repeater {
                    model: [{ n: hv.st.next30, l: "events in the next 30 days" }, { n: hv.st.confirmed, l: "confirmed" },
                            { n: hv.st.holds, l: "still on hold" }, { n: hv.app.fundingAnchor ? hv.items.filter(function (x) { return !!x.link }).length : 0, l: "funding calls closing soon" }]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true; Layout.preferredHeight: 84; color: Fq.mantle; border.width: 1; border.color: Fq.line
                        Column { x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: -2
                            DText { text: String(modelData.n); font.pixelSize: 40 }
                            FText { text: modelData.l; color: Fq.sub; font.pixelSize: 12 } }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 16
                // needs attention
                ColumnLayout {
                    Layout.fillWidth: true; Layout.preferredWidth: 3; Layout.alignment: Qt.AlignTop; spacing: 6
                    Sec { label: "Needs attention" }
                    FText { visible: hv.items.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
                        text: "Nothing overdue, no holds about to slip. Plan the next one: + Event, then Production." }
                    Repeater {
                        model: hv.items.slice(0, 24)
                        delegate: Rectangle {
                            id: at
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredHeight: atc.implicitHeight + 16
                            color: atMA.containsMouse ? Fq.surface : Fq.mantle; border.width: 1; border.color: Fq.line
                            Rectangle { width: 4; height: parent.height; color: hv.toneColor(at.modelData.tone) }
                            MouseArea { id: atMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (at.modelData.link) Qt.openUrlExternally(at.modelData.link)
                                    else if (at.modelData.prod) hv.app.openProduction(at.modelData.occ)
                                    else hv.app.openOccurrence(at.modelData.occ)
                                } }
                            ColumnLayout {
                                id: atc
                                x: 16; y: 8; width: parent.width - 28; spacing: 1
                                RowLayout {
                                    Layout.fillWidth: true
                                    FText { Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 14; textFormat: Text.PlainText; text: at.modelData.text }
                                    FText { visible: !!at.modelData.when; color: Fq.faint; font.pixelSize: 12
                                        text: at.modelData.when ? Qt.formatDate(new Date(at.modelData.when), "ddd d MMM") : "" }
                                }
                                FText { visible: at.modelData.sub !== ""; Layout.fillWidth: true; elide: Text.ElideRight; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText; text: at.modelData.sub }
                            }
                        }
                    }
                }
                // coming up
                ColumnLayout {
                    Layout.fillWidth: true; Layout.preferredWidth: 2; Layout.alignment: Qt.AlignTop; spacing: 6
                    Sec { label: "Coming up (3 weeks)" }
                    FText { visible: hv.soon.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13; text: "No events in the next three weeks." }
                    Repeater {
                        model: hv.soon
                        delegate: Rectangle {
                            id: up
                            required property var modelData
                            readonly property var master: hv.app.eventById(modelData.seriesId || modelData.id) || modelData
                            readonly property var plan: Production.planOf(master)
                            readonly property var prog: plan ? Production.progress(master, plan) : null
                            Layout.fillWidth: true; Layout.preferredHeight: upr.implicitHeight + 18
                            color: upMA.containsMouse ? Fq.surface : Fq.mantle; border.width: 1; border.color: Fq.line
                            Rectangle { width: 4; height: parent.height; color: hv.app.evColor(up.modelData) }
                            MouseArea { id: upMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hv.app.openOccurrence(up.modelData) }
                            RowLayout {
                                id: upr
                                x: 16; y: 9; width: parent.width - 28; spacing: 12
                                DText { text: Qt.formatDate(new Date(up.modelData.startTime), "dd.MM"); font.pixelSize: 30; Layout.alignment: Qt.AlignTop }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 1
                                    FText { Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 14; font.bold: true; textFormat: Text.PlainText; text: up.modelData.title || "(untitled)" }
                                    FText { Layout.fillWidth: true; elide: Text.ElideRight; color: Fq.sub; font.pixelSize: 12; textFormat: Text.PlainText
                                        text: [Qt.formatDate(new Date(up.modelData.startTime), "ddd") + " " + Qt.formatTime(new Date(up.modelData.startTime), "hh:mm"),
                                               Nights.fieldOf(up.modelData, "venue"), Nights.fieldOf(up.modelData, "status"), Details.summary(Details.detailsOf(up.master))].filter(function (x) { return !!x }).join(" · ") }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8; Layout.topMargin: 3
                                        Rectangle { visible: !!up.prog && up.prog.total > 0; Layout.preferredWidth: 90; Layout.preferredHeight: 4; color: Fq.line
                                            Rectangle { height: parent.height; width: up.prog && up.prog.total ? parent.width * up.prog.done / up.prog.total : 0; color: Fq.lime } }
                                        Link { text: up.plan ? "production " + up.prog.done + "/" + up.prog.total : "plan it →"; tone: up.plan ? Fq.sub : Fq.acid
                                            onClicked: hv.app.openProduction(up.master) }
                                    }
                                }
                            }
                        }
                    }
                    // elsewhere in Lisbon: public listings this week (pink)
                    Sec { visible: hv.elsewhere.length > 0; label: "Elsewhere in Lisbon (7 days)"; Layout.topMargin: 12 }
                    Repeater {
                        model: hv.elsewhere
                        delegate: Rectangle {
                            id: el
                            required property int index
                            readonly property var e: hv.elsewhere[index]
                            Layout.fillWidth: true; Layout.preferredHeight: elr.implicitHeight + 12
                            color: elMA.containsMouse ? Fq.surface : "transparent"; border.width: 1; border.color: Fq.line
                            Rectangle { width: 4; height: parent.height; color: Fq.pink }
                            MouseArea { id: elMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hv.app.openNight(el.e) }
                            RowLayout {
                                id: elr
                                x: 14; y: 6; width: parent.width - 24; spacing: 10
                                FText { text: Qt.formatDate(new Date(el.e.startTime), "ddd d") + " " + Qt.formatTime(new Date(el.e.startTime), "hh:mm"); color: Fq.pink; font.pixelSize: 12; Layout.preferredWidth: 96 }
                                FText { Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 13; textFormat: Text.PlainText
                                    text: (el.e.title || "") + (Listings.venueOf(el.e) ? "  ·  " + Listings.venueOf(el.e) : "") }
                            }
                        }
                    }
                }
            }
        }
    }
}
