// Freequencies design tokens (the site + posters): one place for colours and fonts,
// shared by the view and every file in fq/. Scala's own colour names in FreequenciesView.qml
// (cBase, cBlue, …) point here, so Scala's code keeps working unchanged.
pragma Singleton
import QtQuick
import QtCore
import "lib/i18n.js" as I18n

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

    // ── language: English or European Portuguese (lib/i18n.js), switched top right, remembered ──
    property Settings langStore: Settings { category: "freequencies"; property string lang: "en" }
    readonly property string lang: langStore.lang
    function setLang(l) { langStore.lang = (l === "pt" ? "pt" : "en") }
    // t("Save") / t("%1 events", [n]): the text in the chosen language. Bindings that call it
    // re-evaluate when the language changes (it reads `lang`).
    function t(s, args) {
        var out = (lang === "pt" && I18n.PT[s] !== undefined) ? I18n.PT[s] : s
        if (args) for (var i = 0; i < args.length; i++) out = out.split("%" + (i + 1)).join(String(args[i]))
        return out
    }
    // Dates and times with weekday / month names in the chosen language.
    readonly property var loc: Qt.locale(lang === "pt" ? "pt_PT" : "en_GB")
    function fmtDate(d, f) { var x = d instanceof Date ? d : new Date(d); return lang === "pt" ? x.toLocaleDateString(loc, f) : Qt.formatDate(x, f) }
    function fmtDateTime(d, f) { var x = d instanceof Date ? d : new Date(d); return lang === "pt" ? x.toLocaleString(loc, f) : Qt.formatDateTime(x, f) }
    function fmtTime(d, f) { var x = d instanceof Date ? d : new Date(d); return lang === "pt" ? x.toLocaleTimeString(loc, f) : Qt.formatTime(x, f) }
}
