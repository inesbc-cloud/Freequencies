// Sidebar: Lisboa. Public listings (pink, fetched every hour by this install) and the shared
// community calendar every collective joins.
import QtQuick
import QtQuick.Layouts
import "lib/nights.js" as Nights
import "lib/listings.js" as Listings

ColumnLayout {
    id: lp
    property var app
    spacing: 4
    readonly property var st: app.listingsStatus
    FText { text: ">_ LISBOA"; color: Fq.faint; font.pixelSize: 12; font.letterSpacing: 1.2; Layout.topMargin: 6 }

    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Rectangle {
            width: 12; height: 12
            color: lp.app.calHidden(Listings.LISTINGS_CAL) ? "transparent" : Fq.pink; border.width: 1; border.color: Fq.pink
            MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: lp.app.toggleCalVisible(Listings.LISTINGS_CAL) }
        }
        FText { Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 13; color: Fq.text
            text: "Public listings · Luma (" + lp.app.listingEvents.filter(function (e) { return e.startTime > Date.now() }).length + ")" }
    }
    FText { Layout.fillWidth: true; Layout.leftMargin: 20; wrapMode: Text.Wrap; font.pixelSize: 11
        color: lp.st.error ? Fq.warn : Fq.faint
        text: lp.app.listingsBusy ? "updating…" : lp.st.at ? (lp.st.error ? lp.st.error : "updated " + Qt.formatTime(new Date(lp.st.at), "hh:mm") + ", every hour") : "updates every hour" }
    Link { Layout.leftMargin: 20; text: "update now"; visible: !lp.app.listingsBusy; onClicked: lp.app.fetchListings() }

    // the community calendar
    ColumnLayout {
        visible: !lp.app.communityCal; Layout.fillWidth: true; Layout.topMargin: 4; spacing: 2
        FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
            text: "Lisboa: one calendar for every collective's public events." }
        Link { text: lp.app.lisboaBusy ? "setting up…" : "set up the Lisboa calendar →"; onClicked: lp.app.setupLisboa() }
    }
    Link { visible: !!lp.app.communityCal && Nights.isEditorOf(lp.app.communityCal); Layout.leftMargin: 0; Layout.topMargin: 4
        text: "copy the Lisboa join link"; onClicked: lp.app.copyLisboaLinks() }
}
