// Display text in the skin's display face (Fq.display): headings, dates, act names.
// Set `size` (not font.pixelSize): wide faces in the 8-bit skin are scaled to fit.
import QtQuick
import Logos.Controls

LogosText {
    property real size: 24
    textFormat: Text.PlainText
    font.family: Fq.display
    font.pixelSize: Math.round(size * Fq.displayScale)
    font.letterSpacing: Fq.skin === "pixel" ? 0 : 0.6
    color: Fq.text
}
