// A public listing (an event announced on Luma, RA or Shotgun): what, when, where, and a link to it.
// Read-only: it belongs to its organiser on that platform.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/listings.js" as Listings

Win {
    id: lp
    property var app
    property var ev: null
    readonly property string src: ev ? (ev.source || "") : ""
    readonly property string link: ev ? Listings.linkOf(ev) : ""
    title: "public_listing.exe"
    width: Math.min(520, (parent ? parent.width : 520) - 40)
    function openFor(occ) { ev = occ; open() }

    Badge { text: lp.src ? Fq.t("via ") + lp.src : Fq.t("public listing"); tone: Fq.pink }
    DText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 34; text: lp.ev ? (lp.ev.title || "").toUpperCase() : "" }
    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 14
        text: lp.ev ? Fq.fmtDateTime(new Date(lp.ev.startTime), "dddd d MMMM · hh:mm") + (lp.ev.endTime > lp.ev.startTime ? "–" + Fq.fmtTime(new Date(lp.ev.endTime), "hh:mm") : "") : "" }
    FText { visible: !!lp.ev && Listings.venueOf(lp.ev) !== ""; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 13; textFormat: Text.PlainText
        text: lp.ev ? (lp.ev.location || "") : "" }
    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 12; textFormat: Text.PlainText; maximumLineCount: 6; elide: Text.ElideRight
        text: lp.ev ? (lp.ev.description || "").replace(/^Get up-to-date information at: \S+\s*/, "").replace(/\n+/g, " ").slice(0, 420) : "" }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 11; text: Fq.t("Announced publicly; check clashes before you book the same night.") }
        FqButton { text: Fq.t("Close"); onClicked: lp.close() }
        FqButton { visible: lp.link !== ""; text: Fq.t("Open on ") + (lp.src || Fq.t("the web")) + " ↗"; primary: true; onClicked: Qt.openUrlExternally(lp.link) }
    }
}
