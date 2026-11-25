// Freequencies button: square, ruled, uppercase; lime when primary. Same API as LogosButton
// (text, enabled, onClicked), so Scala's LogosButton uses swap one for one.
import QtQuick
import QtQuick.Controls

Button {
    id: b
    property bool primary: false
    implicitHeight: 32
    leftPadding: 14; rightPadding: 14; topPadding: 6; bottomPadding: 6
    font.pixelSize: 12; font.letterSpacing: 1.1; font.capitalization: Font.AllUppercase
    hoverEnabled: true
    contentItem: Text {
        text: b.text; font: b.font; elide: Text.ElideRight
        color: b.primary ? Fq.ink : (b.enabled ? Fq.text : Fq.faint)
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        opacity: b.enabled ? 1 : 0.45
        color: b.primary ? (b.hovered ? Fq.acid : Fq.lime) : (b.down ? Fq.surface2 : b.hovered ? Fq.surface : "transparent")
        border.width: b.primary ? 0 : Fq.bw
        border.color: b.hovered || b.activeFocus ? Fq.lime : Fq.line
    }
}
