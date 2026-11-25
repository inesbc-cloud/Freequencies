// How did this event go? Money, audience, break-even and plan vs actual, in one glance.
// Collapses to nothing while there's nothing to show.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/reports.js" as Reports
import "../lib/money.js" as Money

ColumnLayout {
    id: rs
    property var app
    property var night
    readonly property var r: night ? Reports.eventResult(night) : null
    visible: !!r && (r.hasMoney || r.hasAudience)
    Layout.fillWidth: true; spacing: 4
    function m(n) { return Money.money(n, rs.r ? rs.r.cur : "EUR") }

    Sec { label: Fq.t("Results") }
    GridLayout {
        Layout.fillWidth: true; columns: 3; columnSpacing: 10; rowSpacing: 2
        Repeater {
            model: rs.r ? [
                { l: Fq.t("Result"), v: rs.m(rs.r.profit), tone: rs.r.profit < 0 ? Fq.red : Fq.lime },
                { l: Fq.t("Audience"), v: rs.r.attendance + (rs.r.capacity ? " / " + rs.r.capacity : ""), tone: Fq.text },
                { l: Fq.t("Per person"), v: rs.r.costPerHead !== null ? rs.m(rs.r.costPerHead) : "—", tone: Fq.text }
            ] : []
            delegate: Column { required property var modelData; Layout.fillWidth: true
                DText { text: modelData.v; size: 24; color: modelData.tone }
                FText { text: modelData.l; color: Fq.faint; font.pixelSize: 11 } }
        }
    }
    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: rs.r ? [rs.r.breakEven !== null ? Fq.t("Break-even at %1 tickets.", [rs.r.breakEven]) : "",
                      rs.r.vsExpected !== null ? Fq.t("%1% of the audience you expected.", [Math.round(rs.r.vsExpected * 100)]) : "",
                      rs.r.artists ? Fq.t("%1 of %2 artists paid.", [rs.r.artistsPaid, rs.r.artists]) : ""].filter(function (x) { return !!x }).join(" ") : "" }
}
