// Reports: numbers with a clear owner. Events (how each one went), a collective's year (with the
// numbers funders ask for, ready to copy into an application), and the city's pulse.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../popups"
import "../lib/reports.js" as Reports
import "../lib/money.js" as Money
import "../lib/nights.js" as Nights

Rectangle {
    id: rv
    objectName: "reportsView"
    property var app
    color: Fq.ground
    property string mode: "year"             // "events" | "year" | "city"
    property string calId: ""
    property int year: new Date().getFullYear()
    readonly property double now: app.nowTick
    readonly property var cal: (calId ? app.calById(calId) : null) || app.freqCals[0] || null
    readonly property var calEvents: cal ? app.expandEvents(app.events.filter(function (e) { return e.calendarId === rv.cal.id }),
                                               new Date(rv.year, 0, 1).getTime(), new Date(rv.year + 1, 0, 1).getTime())
                                              .map(function (o) { var mm = app.eventById(o.seriesId || o.id) || o; var c = {}; for (var k in mm) c[k] = mm[k]; c.startTime = o.startTime; return c }) : []
    readonly property var yr: Reports.yearReport(calEvents, new Date(year, 0, 1).getTime(), new Date(year + 1, 0, 1).getTime())
    readonly property var past: app.freqNights.filter(function (e) { return e.startTime < rv.now && e.startTime > rv.now - 365 * 86400000 })
                                              .sort(function (a, b) { return b.startTime - a.startTime }).slice(0, 30)
    readonly property var pulse: Reports.cityPulse((app.communityCal ? app.events.filter(function (e) { return e.calendarId === app.communityCal.id }) : app.freqNights).concat(app.listingEvents), now, 8)
    function m(n) { return Money.money(n, rv.yr.cur) }

    Flickable {
        anchors.fill: parent; anchors.margins: 20
        clip: true; contentWidth: width; contentHeight: col.implicitHeight + 40
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        ColumnLayout {
            id: col
            width: parent.width - 12; spacing: 14
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                DText { text: Fq.t("REPORTS"); size: 40; color: Fq.lime }
                Item { Layout.fillWidth: true }
                Chip { text: Fq.t("Year"); on: rv.mode === "year"; onClicked: rv.mode = "year" }
                Chip { text: Fq.t("Events"); on: rv.mode === "events"; onClicked: rv.mode = "events" }
                Chip { text: Fq.t("Lisbon"); on: rv.mode === "city"; onClicked: rv.mode = "city" }
                FqButton { text: Fq.t("Deal calculator"); onClicked: dealPopup.openFor(null) }
            }

            // ── a collective's year ──
            ColumnLayout {
                visible: rv.mode === "year"; Layout.fillWidth: true; spacing: 10
                Flow { Layout.fillWidth: true; spacing: 6
                    Repeater { model: rv.app.freqCals
                        delegate: Chip { required property var modelData; text: modelData.name || "—"; on: rv.cal && rv.cal.id === modelData.id; onClicked: rv.calId = modelData.id } }
                    Item { width: 12; height: 1 }
                    Repeater { model: [new Date().getFullYear() - 1, new Date().getFullYear()]
                        delegate: Chip { required property var modelData; text: String(modelData); on: rv.year === modelData; onClicked: rv.year = modelData } } }
                FText { Layout.fillWidth: true; color: Fq.sub; font.pixelSize: 13
                    text: Fq.t("Counting: %1 · %2 · confirmed and on-hold events (cancelled ones apart).", [rv.cal ? rv.cal.name : "—", rv.year]) }
                GridLayout {
                    Layout.fillWidth: true; columns: Math.max(2, Math.min(4, Math.floor(col.width / 230))); columnSpacing: -1; rowSpacing: -1
                    Repeater {
                        model: [{ n: rv.yr.events, l: Fq.t("events") }, { n: rv.yr.audience, l: Fq.t("people through the door") },
                                { n: rv.m(rv.yr.profit), l: Fq.t("result (income − costs)") }, { n: rv.yr.artists, l: Fq.t("artists programmed") }]
                        delegate: Rectangle { required property var modelData
                            Layout.fillWidth: true; Layout.preferredHeight: 84; color: Fq.mantle; border.width: Fq.bw; border.color: Fq.line
                            Column { x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: -2
                                DText { text: String(modelData.n); size: 36 }
                                FText { text: modelData.l; color: Fq.sub; font.pixelSize: 12 } } }
                    }
                }
                Sec { label: Fq.t("For funders") }
                GridLayout {
                    Layout.fillWidth: true; columns: 2; columnSpacing: 24; rowSpacing: 4
                    Repeater {
                        model: [[Fq.t("Lisbon-based artists"), rv.yr.local], [Fq.t("Women and non-binary artists"), rv.yr.wnb], [Fq.t("First-time performers"), rv.yr.first],
                                [Fq.t("Artists paid a fee"), rv.yr.paidArtists], [Fq.t("Free events"), rv.yr.free], [Fq.t("Events with accessibility measures"), rv.yr.accessible],
                                [Fq.t("Venues"), rv.yr.venues], [Fq.t("Crew"), rv.yr.crew]]
                        delegate: RowLayout { required property var modelData; Layout.fillWidth: true
                            FText { Layout.fillWidth: true; font.pixelSize: 13; text: modelData[0] }
                            FText { font.pixelSize: 13; font.bold: true; text: String(modelData[1]) } }
                    }
                }
                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 11
                    text: Fq.t("Artist numbers come from the optional tick-boxes in each booking (Lisbon-based, woman or non-binary, first time on stage).") }
                RowLayout { spacing: 10
                    FqButton { primary: true; text: Fq.t("Copy for an application")
                        onClicked: rv.app.copyText(Reports.applicationText(rv.yr, rv.cal ? rv.cal.name : "", String(rv.year), Fq.t)) }
                    Link { text: Fq.t("open the funding library →"); onClicked: rv.app.section = "resources" } }
            }

            // ── events, one by one ──
            ColumnLayout {
                visible: rv.mode === "events"; Layout.fillWidth: true; spacing: 6
                FText { Layout.fillWidth: true; color: Fq.sub; font.pixelSize: 13; text: Fq.t("The last year's events, newest first. Tap one to open it.") }
                FText { visible: rv.past.length === 0; color: Fq.sub; font.pixelSize: 13; text: Fq.t("No past events yet.") }
                Repeater {
                    model: rv.past.length
                    delegate: Rectangle {
                        id: er
                        required property int index
                        readonly property var e: rv.past[index]
                        readonly property var r: Reports.eventResult(e)
                        Layout.fillWidth: true; Layout.preferredHeight: erc.implicitHeight + 14
                        color: erMA.containsMouse ? Fq.surface : Fq.mantle; border.width: Fq.bw; border.color: Fq.line
                        MouseArea { id: erMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rv.app.openOccurrence(er.e) }
                        RowLayout {
                            id: erc
                            x: 14; y: 7; width: parent.width - 28; spacing: 14
                            DText { text: Fq.fmtDate(new Date(er.e.startTime), "dd.MM"); size: 26 }
                            FText { Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 14; textFormat: Text.PlainText; text: er.e.title || "" }
                            FText { font.pixelSize: 13; color: Fq.sub; text: er.r.attendance ? Fq.t("%1 people", [er.r.attendance]) : "" }
                            FText { font.pixelSize: 13; font.bold: true; color: er.r.profit < 0 ? Fq.red : Fq.lime; text: er.r.hasMoney ? rv.m(er.r.profit) : "—" }
                        }
                    }
                }
            }

            // ── the city ──
            ColumnLayout {
                visible: rv.mode === "city"; Layout.fillWidth: true; spacing: 8
                FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13
                    text: Fq.t("The next eight weekends in Lisbon, from the Lisboa calendar and public listings. Pick a quiet one, avoid the crowded nights.") }
                Repeater {
                    model: rv.pulse.weekends
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true; spacing: 12
                        FText { Layout.preferredWidth: 120; font.pixelSize: 13; text: Fq.fmtDate(new Date(modelData.start), "d MMM") + " – " + Fq.fmtDate(new Date(modelData.end - 1), "d MMM") }
                        Rectangle { Layout.preferredWidth: Math.max(4, (col.width - 420) * modelData.count / rv.pulse.max); Layout.preferredHeight: 14
                            color: modelData.count === 0 ? Fq.line : modelData.count >= rv.pulse.max * 0.8 ? Fq.pink : Fq.lime }
                        FText { Layout.fillWidth: true; elide: Text.ElideRight; color: Fq.sub; font.pixelSize: 12
                            text: modelData.count ? Fq.t("%1 events", [modelData.count]) + " · " + modelData.titles.join(", ") : Fq.t("nothing announced yet") }
                    }
                }
                FText { visible: rv.pulse.crowded.length > 0; Layout.topMargin: 6; color: Fq.warn; font.pixelSize: 13
                    text: Fq.t("Crowded nights (3+ events): %1", [rv.pulse.crowded.map(function (c) { return Fq.fmtDate(new Date(c.day), "ddd d MMM") + " (" + c.n + ")" }).join(", ")]) }
            }
        }
    }
    DealPopup { id: dealPopup; app: rv.app }
}
