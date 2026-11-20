// Styled text input (Freequencies: dark field, lime focus) — a plain QtQuick.Controls TextField themed with design-system
// tokens (a separate file, not an inline component, so it works on every Qt runtime
// the Basecamp host might bundle).
import QtQuick
import QtQuick.Controls
import Logos.Theme
import "fq"

TextField {
    implicitWidth: 120   // don't let the default (large) TextField width force the containing layout wide
    color: Fq.text
    placeholderTextColor: Fq.faint
    selectionColor: Fq.lime
    selectedTextColor: Fq.ink
    font.pixelSize: 14
    selectByMouse: true
    background: Rectangle {
        color: Fq.mantle
        border.width: 1
        border.color: parent.activeFocus ? Fq.lime : Fq.line
    }
}
