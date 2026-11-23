// One promo image at its real size (1080 wide). The studio shows it scaled down and saves it at
// full size with grabToImage. What it says comes from Promo.fill(); this file only lays it out.
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/promo.js" as Promo

Rectangle {
    id: cv
    property string tpl: "announce"
    property var f: ({ kicker: "", big: "", lines: [], rows: [], foot: "" })
    property string photo: ""          // file:// url, or ""
    property string logo: ""           // file:// url, or ""
    property string logoText: ""       // shown when there's no logo image
    property bool whiteText: true
    property bool band: false          // text on a solid band at the top (for busy photos)
    property string face: "display"    // "display" | "grotesk" | "mono"
    readonly property color ink: whiteText ? "#ffffff" : "#111111"
    readonly property color paper: whiteText ? "#2b2b2b" : "#f1efe9"
    readonly property string bigFamily: face === "display" ? Fq.display : face === "mono" ? Fq.body : "Helvetica Neue"
    readonly property string smallFamily: face === "mono" ? Fq.body : "Helvetica Neue"
    readonly property int m: 72
    width: 1080; height: 1350
    color: paper
    clip: true

    Image {
        anchors.fill: parent; visible: cv.photo !== ""; source: cv.photo
        fillMode: Image.PreserveAspectCrop; asynchronous: false; cache: false; smooth: true
    }
    // keep text readable on a photo: a soft shade behind the top and the bottom
    Rectangle {
        visible: cv.photo !== "" && !cv.band; anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(cv.paper.r, cv.paper.g, cv.paper.b, 0.75) }
            GradientStop { position: 0.38; color: Qt.rgba(cv.paper.r, cv.paper.g, cv.paper.b, 0.0) }
            GradientStop { position: 0.72; color: Qt.rgba(cv.paper.r, cv.paper.g, cv.paper.b, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(cv.paper.r, cv.paper.g, cv.paper.b, 0.8) }
        }
    }
    Rectangle { visible: cv.band; width: parent.width; height: top.implicitHeight + cv.m * 1.6; color: cv.paper }

    ColumnLayout {
        id: top
        x: cv.m; y: cv.m; width: cv.width - 2 * cv.m; spacing: 10
        Text { visible: cv.f.kicker !== ""; text: cv.f.kicker; color: cv.ink; font.family: cv.smallFamily; font.pixelSize: 40; font.weight: Font.DemiBold
               font.letterSpacing: 3; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText }
        Text { text: cv.f.big; color: cv.ink; font.family: cv.bigFamily; font.pixelSize: Promo.bigSize(cv.f.big, cv.width - 2 * cv.m) * (cv.face === "display" ? 1.25 : 0.95)
               font.weight: Font.Medium; lineHeight: 0.88; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText; maximumLineCount: 4; elide: Text.ElideRight }
        Repeater {
            model: cv.f.lines || []
            delegate: Text { required property var modelData; text: modelData; color: cv.ink; textFormat: Text.PlainText
                font.family: cv.tpl === "lineup" ? cv.bigFamily : cv.smallFamily; font.pixelSize: cv.tpl === "lineup" ? (cv.face === "display" ? 92 : 64) : 44
                Layout.fillWidth: true; wrapMode: Text.Wrap; lineHeight: 0.95 }
        }
        Repeater {
            model: cv.f.rows || []
            delegate: RowLayout { required property var modelData; Layout.fillWidth: true; spacing: 28
                Text { text: modelData[0]; color: cv.ink; font.family: cv.smallFamily; font.pixelSize: 44; font.weight: Font.DemiBold; Layout.preferredWidth: 150 }
                Text { text: modelData[1]; color: cv.ink; font.family: cv.bigFamily; font.pixelSize: cv.face === "display" ? 84 : 58; Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText } }
        }
    }

    Text {
        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: cv.m
        width: parent.width - 2 * cv.m - 240
        text: cv.f.foot || ""; color: cv.ink; font.family: cv.smallFamily; font.pixelSize: 40; font.weight: Font.Medium
        lineHeight: 1.1; wrapMode: Text.Wrap; textFormat: Text.PlainText
    }
    Item {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: cv.m
        width: 210; height: 210
        Image { anchors.fill: parent; visible: cv.logo !== ""; source: cv.logo; fillMode: Image.PreserveAspectFit; horizontalAlignment: Image.AlignRight; verticalAlignment: Image.AlignBottom; cache: false; smooth: true }
        Text { visible: cv.logo === "" && cv.logoText !== ""; anchors.right: parent.right; anchors.bottom: parent.bottom; width: parent.width
               text: cv.logoText; color: cv.ink; font.family: cv.bigFamily; font.pixelSize: 54; horizontalAlignment: Text.AlignRight; wrapMode: Text.Wrap; textFormat: Text.PlainText }
    }
}
