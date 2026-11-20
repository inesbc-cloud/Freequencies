// Analytics (#27): the last six months and the next two, across the calendars shown (and filters).
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../lib/analytics.js" as Analytics
import "../lib/money.js" as Money

Flickable {
    id: av
    objectName: "analyticsFlick"
    property var app
    readonly property var s: {
        var d = new Date(app.nowTick), a = new Date(d.getFullYear(), d.getMonth() - 5, 1).getTime(), b = new Date(d.getFullYear(), d.getMonth() + 3, 1).getTime()
        return Analytics.stats(app.expandEvents(app.eventsFiltered(), a, b).filter(function (o) { return o.startTime >= a && o.startTime < b }),
                               function (o) { return app.eventById(o.seriesId) }, app.nowTick, 5, 2)
    }
    clip: true; contentWidth: width; contentHeight: col.implicitHeight + 20
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
        id: col
        width: av.width - 12; spacing: 14
        FText { color: Fq.sub; font.pixelSize: 13; text: "Last six months and the next two, across the calendars shown and the filters set." }
        GridLayout {
            Layout.fillWidth: true; columns: col.width > 900 ? 6 : 3; columnSpacing: -1; rowSpacing: -1
            Repeater {
                model: [{ l: "Nights", v: String(av.s.tot.nights), x: av.s.tot.confirmed + " confirmed · " + av.s.tot.hold + " on hold" },
                        { l: "Attendance", v: String(av.s.tot.attendance), x: "tickets sold, or RSVPs going" },
                        { l: "Revenue", v: Money.money(av.s.tot.revenue), x: "tickets + income lines" },
                        { l: "Result", v: Money.money(av.s.tot.profit), x: "after fees and costs" },
                        { l: "Artists", v: String(av.s.tot.artists), x: "different acts booked" },
                        { l: "Cancelled", v: String(av.s.tot.cancelled), x: "nights called off" }]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 100; color: Fq.mantle; border.width: 1; border.color: Fq.line
                    Column { x: 14; y: 12; width: parent.width - 28; spacing: -2
                        FText { text: modelData.l.toUpperCase(); color: Fq.lime; font.pixelSize: 12; font.letterSpacing: 1.2 }
                        DText { text: modelData.v; font.pixelSize: 38; width: parent.width; elide: Text.ElideRight }
                        FText { text: modelData.x; color: Fq.faint; font.pixelSize: 12; width: parent.width; elide: Text.ElideRight } }
                }
            }
        }
        Repeater {
            model: [{ l: "Nights per month", k: "nights" }, { l: "Attendance per month", k: "attendance" }, { l: "Revenue per month (EUR)", k: "revenue" }]
            delegate: ColumnLayout {
                id: chart
                required property var modelData
                Layout.fillWidth: true; spacing: 6
                FText { text: ">_ " + chart.modelData.l.toUpperCase(); color: Fq.lime; font.pixelSize: 12; font.letterSpacing: 1.2; Layout.topMargin: 6 }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 160; color: "transparent"; border.width: 1; border.color: Fq.line
                    Row {
                        id: bars
                        x: 12; y: 10; width: parent.width - 24; height: parent.height - 20
                        Repeater {
                            model: av.s.months
                            delegate: Item {
                                id: bar
                                required property var modelData
                                readonly property real v: modelData[chart.modelData.k]
                                readonly property bool future: modelData.start > av.app.nowTick
                                width: bars.width / av.s.months.length; height: bars.height
                                FText { anchors.horizontalCenter: parent.horizontalCenter; y: br.y - 18; text: bar.v ? String(Math.round(bar.v)) : ""; color: Fq.sub; font.pixelSize: 12 }
                                Rectangle { id: br; width: parent.width * 0.56; anchors.horizontalCenter: parent.horizontalCenter
                                    height: Math.max(bar.v > 0 ? 2 : 0, (parent.height - 40) * bar.v / Math.max(1, av.s.max[chart.modelData.k])); y: parent.height - 20 - height
                                    color: bar.future ? "transparent" : Fq.lime; border.width: bar.future ? 1 : 0; border.color: Fq.lime }
                                FText { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 16; text: Qt.formatDate(new Date(bar.modelData.start), "MMM").toUpperCase()
                                        color: bar.future ? Fq.faint : Fq.sub; font.pixelSize: 12 }
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 24; Layout.topMargin: 6
            Repeater {
                model: [{ l: "Top tags", xs: av.s.tags, pre: "#" }, { l: "Top venues", xs: av.s.venues, pre: "" }]
                delegate: ColumnLayout {
                    id: top
                    required property var modelData
                    readonly property string pre: modelData.pre
                    Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: 4
                    FText { text: ">_ " + top.modelData.l.toUpperCase(); color: Fq.lime; font.pixelSize: 12; font.letterSpacing: 1.2 }
                    FText { visible: top.modelData.xs.length === 0; text: "—"; color: Fq.faint; font.pixelSize: 12 }
                    Repeater { model: top.modelData.xs
                        delegate: RowLayout { required property var modelData; Layout.fillWidth: true
                            FText { text: top.pre + modelData.label; font.pixelSize: 13; Layout.fillWidth: true }
                            FText { text: modelData.n; color: Fq.sub; font.pixelSize: 13 } } }
                }
            }
        }
    }
}
