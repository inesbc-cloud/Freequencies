// Stub of the Logos design system's Theme for the offscreen preview (NOT the real DS: metrics differ).
pragma Singleton
import QtQuick
QtObject {
    property QtObject typography: QtObject { property int weightMedium: Font.Medium; property int weightBold: Font.Bold }
    property QtObject spacing: QtObject { property int small: 8; property int medium: 12; property int large: 18; property int radiusSmall: 6 }
    property QtObject palette: QtObject {
        property color text: "#e6e6e6"; property color textTertiary: "#8a8a8a"; property color background: "#202020"
        property color borderHairline: "#3a3a3a"; property color accent: "#6ef600"
    }
}
