// Filters for every view (#24): status (several), type, tag, venue. Scala's search box in the right
// pane finds artists, crew and tags too.
import QtQuick
import "lib/nights.js" as Nights
import "lib/colour.js" as Colour
import "lib/filters.js" as Filters

Flow {
    id: fb
    property var app
    spacing: 6
    readonly property var f: app.nightFilter
    FText { text: Fq.t("STATUS"); color: Fq.faint; font.pixelSize: 12; font.letterSpacing: 1.2; height: 24; verticalAlignment: Text.AlignVCenter }
    Repeater { model: Nights.statuses
        delegate: Chip { required property var modelData; height: 24; text: Fq.t(modelData); accent: Colour.statusColor(modelData, fb.app.fqPalette)
            on: !!fb.f.status[modelData]; onClicked: fb.app.nightFilter = Filters.withStatus(fb.f, modelData) } }
    Item { width: 8; height: 24 }
    FText { text: Fq.t("TYPE"); color: Fq.faint; font.pixelSize: 12; font.letterSpacing: 1.2; height: 24; verticalAlignment: Text.AlignVCenter }
    Repeater { model: Nights.types
        delegate: Chip { required property var modelData; height: 24; text: Fq.t(modelData); on: fb.f.type === modelData; onClicked: fb.app.nightFilter = Filters.with_(fb.f, "type", modelData) } }
    Item { width: 8; height: 24; visible: fb.app.allTags.length > 0 }
    FText { visible: fb.app.allTags.length > 0; text: Fq.t("TAG"); color: Fq.faint; font.pixelSize: 12; font.letterSpacing: 1.2; height: 24; verticalAlignment: Text.AlignVCenter }
    Repeater { model: fb.app.allTags.slice(0, 8)
        delegate: Chip { required property var modelData; height: 24; text: "#" + modelData; accent: Fq.signal; on: fb.f.tag === modelData; onClicked: fb.app.nightFilter = Filters.with_(fb.f, "tag", modelData) } }
    Chip { visible: fb.f.venue !== ""; height: 24; text: "@ " + fb.f.venue + "  ✕"; on: true; accent: Fq.acid; onClicked: fb.app.nightFilter = Filters.with_(fb.f, "venue", fb.f.venue) }
    Link { visible: !Filters.isEmpty(fb.f); text: Fq.t("clear filters"); height: 24; verticalAlignment: Text.AlignVCenter; onClicked: fb.app.nightFilter = Filters.empty() }
}
