// Set the poster (#15): one of the night's image files, or an image link; or remove it.
import QtQuick
import QtQuick.Layouts
import ".."
import "../.."
import "../lib/files.js" as Files
import "../lib/poster.js" as Poster

Win {
    id: pp
    property var app
    property var night
    title: "poster.exe"
    readonly property var images: Files.filesOf(night).filter(Files.isImage)
    function openFor() { var p = Poster.posterOf(night); link.text = p && p.url ? p.url : ""; open() }
    Label_ { text: Fq.t("FROM THE EVENT'S FILES") }
    FText { visible: pp.images.length === 0; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Fq.sub; font.pixelSize: 12
        text: Fq.t("No image files on this event yet. Upload the poster under Files, or paste a link below.") }
    Flow { Layout.fillWidth: true; spacing: 6
        Repeater { model: pp.images
            delegate: Chip { required property var modelData; text: modelData.name || "image"; on: (Poster.posterOf(pp.night) || {}).cid === modelData.storageCid
                onClicked: { pp.app.putLatest(pp.night, "poster", { cid: modelData.storageCid, name: modelData.name || "poster" }, "Poster set"); pp.close() } } } }
    Label_ { text: Fq.t("OR AN IMAGE LINK"); Layout.topMargin: 6 }
    Field { id: link; Layout.fillWidth: true; placeholderText: "https://…/poster.png" }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 8
        FqButton { visible: !!Poster.posterOf(pp.night); text: Fq.t("Remove"); onClicked: { pp.app.putLatest(pp.night, "poster", {}, Fq.t("Poster removed")); pp.close() } }
        Item { Layout.fillWidth: true }
        FqButton { text: Fq.t("Cancel"); onClicked: pp.close() }
        FqButton { text: Fq.t("Use link"); primary: true; enabled: Poster.isLink(link.text.trim()) || /^[\w.-]+\.[a-z]{2,}\//i.test(link.text.trim())
            onClicked: { var u = link.text.trim(); if (!Poster.isLink(u)) u = "https://" + u; pp.app.putLatest(pp.night, "poster", { url: u }, "Poster set"); pp.close() } }
    }
}
