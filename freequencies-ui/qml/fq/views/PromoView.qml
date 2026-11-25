// Promo studio: posts and stories for a night, filled in from its data. Photos and logos stay on
// your computer; nothing is uploaded. "Plan the campaign" dates every post in the social planner.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import ".."
import "../.."
import "../lib/promo.js" as Promo
import "../lib/lineup.js" as Lineup
import "../lib/nights.js" as Nights
import "../lib/details.js" as Details
import "../lib/checklist.js" as Checklist

Rectangle {
    id: ps
    objectName: "promoView"
    property var app
    color: Fq.ground

    property string nightId: ""
    property string tpl: "announce"
    property string size: "feed"
    property string lang: Fq.lang          // words on the images: follows the app, switchable here
    property string face: "display"
    property bool whiteText: true
    property bool band: false
    property string ticket: "onsale"
    property string artist: ""
    property var photos: ({})            // artist name (or "") → file url, this session only
    Settings { id: saved; category: "freequencies-promo"; property string logo: ""; property string logoText: "" }

    readonly property double now: app.nowTick
    readonly property var nights: app.freqNights.filter(function (n) { return n.startTime > now - 7 * 86400000 })
                                    .sort(function (a, b) { return a.startTime - b.startTime })
    readonly property var night: (nightId ? app.eventById(nightId) : null) || (nights.length ? nights[0] : null)
    readonly property var lineup: night ? Lineup.lineupOf(night).filter(function (b) { return b.status !== "cancelled" })
                                          .map(function (b) { return { name: app.kithName(b), set: b.set } }) : []
    readonly property string curArtist: artist !== "" ? artist : (lineup.length ? lineup[0].name : "")
    readonly property var det: night ? Details.detailsOf(night) : ({})
    readonly property var filled: Promo.fill(tpl, {
        title: titleIn.text !== "" ? titleIn.text : (night ? night.title : ""), venue: night ? Nights.fieldOf(night, "venue") : "",
        start: night ? night.startTime : undefined, end: night ? night.endTime : undefined, lineup: lineup,
        artist: curArtist, extra: extraIn.text, ticket: ticket, price: priceIn.text !== "" ? priceIn.text : Details.priceLabel(det), lang: lang, now: now })
    readonly property string photoKey: tpl === "artist" ? curArtist : ""

    function save(path) {
        canvas.grabToImage(function (res) {
            var ok = res.saveToFile(path)
            app.notify(ok ? Fq.t("Saved ") + path.split("/").pop() : Fq.t("Couldn't save the image there."), !ok)
        }, Qt.size(canvas.width, canvas.height))
    }
    // all artist cards into one folder, one after another (each needs a frame to draw)
    property var batch: []
    property string batchDir: ""
    Timer {
        id: batchTimer; interval: 350; repeat: false
        onTriggered: {
            if (!ps.batch.length) { ps.artist = ""; ps.app.notify(Fq.t("Artist cards saved in ") + ps.batchDir.split("/").pop()); return }
            var name = ps.batch[0]
            if (ps.artist !== name) { ps.artist = name; batchTimer.restart(); return }
            canvas.grabToImage(function (res) {
                res.saveToFile(ps.batchDir + "/" + Promo.fileName("artist", ps.night ? ps.night.title : "", name, ps.size))
                ps.batch = ps.batch.slice(1); batchTimer.restart()
            }, Qt.size(canvas.width, canvas.height))
        }
    }
    function urlPath(u) { return decodeURIComponent(String(u).replace(/^file:\/\//, "")) }

    RowLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 24

        // ── preview ──
        Item {
            id: stage
            Layout.fillWidth: true; Layout.fillHeight: true
            readonly property real k: Math.min(width / canvas.width, height / canvas.height)
            Item {
                width: canvas.width * stage.k; height: canvas.height * stage.k; anchors.centerIn: parent
                PromoCanvas {
                    id: canvas
                    objectName: "promoCanvas"
                    transformOrigin: Item.TopLeft; scale: stage.k
                    width: Promo.SIZES[ps.size].w; height: Promo.SIZES[ps.size].h
                    tpl: ps.tpl; f: ps.filled; whiteText: ps.whiteText; band: ps.band; face: ps.face
                    photo: ps.photos[ps.photoKey] || ""
                    logo: saved.logo; logoText: saved.logoText
                }
            }
            FText { visible: !ps.night; anchors.centerIn: parent; text: Fq.t("Add an event first (+ Event), then make its posts here."); color: Fq.sub; font.pixelSize: 14 }
        }

        // ── controls ──
        Rectangle {
            Layout.preferredWidth: 440; Layout.fillHeight: true; color: Fq.mantle; border.width: 1; border.color: Fq.line
            Flickable {
                anchors.fill: parent; anchors.margins: 16; clip: true
                contentWidth: width; contentHeight: ctl.implicitHeight + 10
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {}
                ColumnLayout {
                    id: ctl
                    width: parent.width - 8; spacing: 8
                    DText { text: Fq.t("PROMO STUDIO"); font.pixelSize: 32; color: Fq.lime }

                    Label_ { text: Fq.t("EVENT") }
                    Flow { Layout.fillWidth: true; spacing: 6
                        Repeater { model: ps.nights.slice(0, 10)
                            delegate: Chip { required property int index; readonly property var n: ps.nights[index]
                                text: Fq.fmtDate(new Date(n.startTime), "dd.MM") + " " + (n.title || "").slice(0, 22); on: ps.night && ps.night.id === n.id
                                onClicked: { ps.nightId = n.id; ps.artist = ""; titleIn.text = "" } } } }

                    Label_ { text: Fq.t("TEMPLATE") }
                    Flow { Layout.fillWidth: true; spacing: 6
                        Repeater { model: Promo.TEMPLATE_ORDER
                            delegate: Chip { required property var modelData; text: Fq.t(Promo.TEMPLATES[modelData].label); on: ps.tpl === modelData; onClicked: ps.tpl = modelData } } }
                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.faint; font.pixelSize: 11; text: Fq.t(Promo.TEMPLATES[ps.tpl].blurb) }

                    ColumnLayout {
                        visible: ps.tpl === "artist"; Layout.fillWidth: true; spacing: 6
                        Label_ { text: Fq.t("ARTIST") }
                        Flow { Layout.fillWidth: true; spacing: 6
                            Repeater { model: ps.lineup
                                delegate: Chip { required property var modelData; text: modelData.name; on: ps.curArtist === modelData.name; onClicked: ps.artist = modelData.name } } }
                        Field { Layout.fillWidth: true; placeholderText: Fq.t("Or type an artist name"); onTextEdited: ps.artist = text }
                    }

                    Rectangle {   // photo: stays on this computer
                        Layout.fillWidth: true; Layout.preferredHeight: 74; color: "transparent"; border.width: 1; border.color: Fq.sub
                        Column { anchors.centerIn: parent; spacing: 2
                            FText { anchors.horizontalCenter: parent.horizontalCenter; text: ps.photos[ps.photoKey] ? Fq.t("Change photo") : (ps.tpl === "artist" ? Fq.t("Choose a photo of ") + (ps.curArtist || Fq.t("the artist")) : Fq.t("Choose photo")); font.pixelSize: 14; font.bold: true }
                            FText { anchors.horizontalCenter: parent.horizontalCenter; text: Fq.t("It stays on your computer."); color: Fq.sub; font.pixelSize: 11 } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: photoDialog.open() }
                    }
                    Link { visible: !!ps.photos[ps.photoKey]; text: Fq.t("remove photo"); tone: Fq.red
                        onClicked: { var p = {}; for (var k in ps.photos) p[k] = ps.photos[k]; delete p[ps.photoKey]; ps.photos = p } }

                    Label_ { text: Fq.t("YOUR LOGO (KEPT FOR NEXT TIME)") }
                    RowLayout { Layout.fillWidth: true; spacing: 8
                        FqButton { text: saved.logo ? Fq.t("Change logo") : Fq.t("Upload logo"); onClicked: logoDialog.open() }
                        Link { visible: saved.logo !== ""; text: Fq.t("remove"); tone: Fq.red; onClicked: saved.logo = "" }
                        Field { Layout.fillWidth: true; visible: saved.logo === ""; placeholderText: Fq.t("or a name, e.g. FREEQUENCIES"); text: saved.logoText; onTextEdited: saved.logoText = text } }

                    Flow { Layout.fillWidth: true; spacing: 6
                        Chip { text: Fq.t("White text"); on: ps.whiteText; onClicked: ps.whiteText = true }
                        Chip { text: Fq.t("Black text"); on: !ps.whiteText; onClicked: ps.whiteText = false }
                        Chip { text: Fq.t("Solid band"); on: ps.band; accent: Fq.signal; onClicked: ps.band = !ps.band } }
                    Flow { Layout.fillWidth: true; spacing: 6
                        Repeater { model: Promo.SIZE_ORDER
                            delegate: Chip { required property var modelData; text: Fq.t(Promo.SIZES[modelData].label); on: ps.size === modelData; onClicked: ps.size = modelData } } }
                    Flow { Layout.fillWidth: true; spacing: 6
                        Chip { text: Fq.t("Bebas"); on: ps.face === "display"; onClicked: ps.face = "display" }
                        Chip { text: Fq.t("Grotesk"); on: ps.face === "grotesk"; onClicked: ps.face = "grotesk" }
                        Chip { text: Fq.t("Mono"); on: ps.face === "mono"; onClicked: ps.face = "mono" }
                        Item { width: 10; height: 1 }
                        Chip { text: Fq.t("EN"); on: ps.lang === "en"; onClicked: ps.lang = "en" }
                        Chip { text: Fq.t("PT"); on: ps.lang === "pt"; onClicked: ps.lang = "pt" } }

                    Label_ { text: Fq.t("NAME OF THE EVENT") }
                    Field { id: titleIn; Layout.fillWidth: true; placeholderText: ps.night ? ps.night.title : "" }
                    ColumnLayout {
                        visible: ps.tpl === "tickets"; Layout.fillWidth: true; spacing: 6
                        Flow { Layout.fillWidth: true; spacing: 6
                            Chip { text: Fq.t("On sale"); on: ps.ticket === "onsale"; onClicked: ps.ticket = "onsale" }
                            Chip { text: Fq.t("Last tickets"); on: ps.ticket === "last"; onClicked: ps.ticket = "last" }
                            Chip { text: Fq.t("Sold out"); on: ps.ticket === "soldout"; onClicked: ps.ticket = "soldout" }
                            Chip { text: Fq.t("Free entry"); on: ps.ticket === "free"; onClicked: ps.ticket = "free" } }
                        Field { id: priceIn; Layout.fillWidth: true; placeholderText: Details.priceLabel(ps.det) || Fq.t("Price, e.g. 8 EUR at the door") }
                    }
                    Label_ { text: Fq.t("EXTRA LINE (OPTIONAL)") }
                    Field { id: extraIn; Layout.fillWidth: true; placeholderText: ps.tpl === "thanks" ? Fq.t("e.g. see you in January") : Fq.t("e.g. live from the studio") }

                    FqButton { objectName: "promoSave"; Layout.fillWidth: true; Layout.topMargin: 6; text: Fq.t("Download PNG"); primary: true; enabled: !!ps.night && !batchTimer.running
                        onClicked: { saveDialog.currentFile = "file://" + StandardPaths.writableLocation(StandardPaths.DownloadLocation).toString().replace(/^file:\/\//, "") + "/" + Promo.fileName(ps.tpl, ps.night.title, ps.curArtist, ps.size); saveDialog.open() } }
                    FqButton { visible: ps.tpl === "artist" && ps.lineup.length > 1; Layout.fillWidth: true; enabled: !batchTimer.running
                        text: batchTimer.running ? Fq.t("Saving ") + ps.batch.length + Fq.t(" left…") : Fq.t("Download all ") + ps.lineup.length + Fq.t(" artist cards"); onClicked: folderDialog.open() }

                    Sec { label: Fq.t("Campaign"); Layout.topMargin: 10 }
                    FText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
                        text: Fq.t("Puts every post in this event's social planner with a date: announce (T-28), line-up (T-14), one artist card each (T-10 to T-3), tickets (T-7), timetable (T-1), countdown (show day), thank you (T+1). They show up on Home when they're due.") }
                    FqButton { Layout.fillWidth: true; text: ps.app.campaignBusy ? Fq.t("Planning…") : Fq.t("Plan the campaign"); enabled: !!ps.night && !ps.app.campaignBusy
                        onClicked: ps.app.planCampaign(ps.night, ps.lineup.map(function (b) { return b.name })) }
                    FText { visible: !!ps.night; Layout.fillWidth: true; color: Fq.faint; font.pixelSize: 11
                        text: ps.night ? Checklist.postsOf(ps.night).length + Fq.t(" posts planned for this event") : "" }
                }
            }
        }
    }

    FileDialog { id: photoDialog; title: Fq.t("Choose a photo"); nameFilters: [Fq.t("Images (*.png *.jpg *.jpeg *.webp *.heic)")]
        onAccepted: { var p = {}; for (var k in ps.photos) p[k] = ps.photos[k]; p[ps.photoKey] = String(selectedFile); ps.photos = p } }
    FileDialog { id: logoDialog; title: Fq.t("Choose your logo (a PNG with a transparent background works best)"); nameFilters: [Fq.t("Images (*.png *.svg *.jpg *.jpeg *.webp)")]
        onAccepted: saved.logo = String(selectedFile) }
    FileDialog { id: saveDialog; title: Fq.t("Save the image"); fileMode: FileDialog.SaveFile; nameFilters: [Fq.t("PNG image (*.png)")]
        onAccepted: { var p = ps.urlPath(selectedFile); if (!/\.png$/i.test(p)) p += ".png"; ps.save(p) } }
    FolderDialog { id: folderDialog; title: Fq.t("Where should the artist cards go?")
        onAccepted: { ps.batchDir = ps.urlPath(selectedFolder); ps.batch = ps.lineup.map(function (b) { return b.name }); ps.artist = ""; batchTimer.restart() } }
}
