// Freequencies design tokens (the site + posters): one place for colours and fonts,
// shared by the view and every file in fq/. Scala's own colour names in FreequenciesView.qml
// (cBase, cBlue, …) point here, so Scala's code keeps working unchanged.
pragma Singleton
import QtQuick

QtObject {
    // ground and surfaces: a terminal, ruled in dark green
    readonly property color ground:   "#050805"
    readonly property color mantle:   "#0a110a"
    readonly property color surface:  "#111c11"
    readonly property color surface2: "#1a2c1d"
    readonly property color line:     "#223a26"
    readonly property color ink:      "#050805"   // text on lime / acid
    // text: body grey a shade lighter than the site's, for legibility
    readonly property color text:     "#d6efd6"
    readonly property color sub:      "#a3c4a3"
    readonly property color faint:    "#6f8f6f"
    // accents
    readonly property color lime:     "#6ef600"   // primary
    readonly property color acid:     "#7bf686"   // poster green
    readonly property color signal:   "#4aa8ff"   // the (( )) signal blue
    readonly property color bracket:  "#2f6bff"
    readonly property color warn:     "#ffc531"
    readonly property color red:      "#ff5a4a"
    readonly property color pink:     "#ff6ad5"
    // status colours (Hold / Confirmed / Cancelled), ADR 0001 §4
    readonly property color hold:     signal
    readonly property color confirmed: lime
    readonly property color cancelled: red
    // categorical swatch: calendars, venues, types
    readonly property var swatch: ["#6ef600", "#4aa8ff", "#ff6ad5", "#ffc531", "#3fe0d0", "#b98cff", "#ff8a3d", "#7bf686"]

    // fonts (#4): Bebas Neue for display (bundled, OFL); FT88 Serif for everything else
    // (Velvetyne, OFL: drop it in qml/fonts/FT88-Serif.otf, see the README there; monospace until then)
    property FontLoader bebasLoader: FontLoader { source: "../fonts/BebasNeue-Regular.ttf" }
    property FontLoader ft88Loader: FontLoader { source: "../fonts/FT88-Serif.otf" }
    readonly property string display: bebasLoader.status === FontLoader.Ready ? bebasLoader.font.family : "Impact"
    readonly property string body: ft88Loader.status === FontLoader.Ready ? ft88Loader.font.family : "monospace"
}
