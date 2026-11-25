// Freequencies design tokens (the site + posters): one place for colours and fonts,
// shared by the view and every file in fq/. Scala's own colour names in FreequenciesView.qml
// (cBase, cBlue, …) point here, so Scala's code keeps working unchanged.
pragma Singleton
import QtQuick
import QtCore
import "lib/i18n.js" as I18n

QtObject {
    // ── skins: classic (terminal green), pixel (8-bit universe) ──
    // Every colour below comes from the chosen skin; the switcher sits bottom right, remembered.
    readonly property string skin: langStore.skin === "pixel" ? "pixel" : "classic"
    function setSkin(k) { langStore.skin = k === "pixel" ? k : "classic" }
    readonly property var skins: ["classic", "pixel"]
    readonly property var pal: ({
        classic: { ground: "#050805", mantle: "#0a110a", surface: "#111c11", surface2: "#1a2c1d", line: "#223a26", ink: "#050805",
                   text: "#d6efd6", sub: "#a3c4a3", faint: "#6f8f6f", lime: "#6ef600", acid: "#7bf686", signal: "#4aa8ff", bracket: "#2f6bff",
                   warn: "#ffc531", red: "#ff5a4a", pink: "#ff6ad5",
                   swatch: ["#6ef600", "#4aa8ff", "#ff6ad5", "#ffc531", "#3fe0d0", "#b98cff", "#ff8a3d", "#7bf686"] },
        // deep space, magenta and cyan, a limited 8-bit palette
        pixel:   { ground: "#0b0b2e", mantle: "#121247", surface: "#1a1a63", surface2: "#24248a", line: "#3a3ac8", ink: "#0b0b2e",
                   text: "#f4f4ff", sub: "#c2c2ff", faint: "#8c8cdc", lime: "#ff4fd8", acid: "#3ef0ff", signal: "#3ef0ff", bracket: "#8f6bff",
                   warn: "#ffd93f", red: "#ff5c5c", pink: "#ff9bf0",
                   swatch: ["#ff4fd8", "#3ef0ff", "#ffd93f", "#5cff7a", "#ff8a3d", "#8f6bff", "#ff5c5c", "#f4f4ff"] }
    })
    readonly property var p: pal[skin] || pal.classic
    readonly property color ground:   p.ground
    readonly property color mantle:   p.mantle
    readonly property color surface:  p.surface
    readonly property color surface2: p.surface2
    readonly property color line:     p.line
    readonly property color ink:      p.ink       // text on the primary colour
    readonly property color text:     p.text
    readonly property color sub:      p.sub
    readonly property color faint:    p.faint
    readonly property color lime:     p.lime      // primary
    readonly property color acid:     p.acid
    readonly property color signal:   p.signal
    readonly property color bracket:  p.bracket
    readonly property color warn:     p.warn
    readonly property color red:      p.red
    readonly property color pink:     p.pink
    // status colours (Hold / Confirmed / Cancelled), ADR 0001 §4
    readonly property color hold:     signal
    readonly property color confirmed: lime
    readonly property color cancelled: red
    readonly property var swatch: p.swatch
    readonly property int bw: skin === "pixel" ? 2 : 1     // border width: chunky in 8-bit

    // fonts (#4): Bebas Neue for display (bundled, OFL); FT88 Serif for everything else
    // (Velvetyne, OFL: drop it in qml/fonts/FT88-Serif.otf, see the README there; monospace until then)
    property FontLoader bebasLoader: FontLoader { source: "../fonts/BebasNeue-Regular.ttf" }
    property FontLoader ft88Loader: FontLoader { source: "../fonts/FT88-Serif.otf" }
    property FontLoader pixelLoader: FontLoader { source: "../fonts/PressStart2P-Regular.ttf" }
    readonly property string bebas: bebasLoader.status === FontLoader.Ready ? bebasLoader.font.family : "Impact"
    readonly property string display: skin === "pixel" ? (pixelLoader.status === FontLoader.Ready ? pixelLoader.font.family : "Courier New")
                                    : bebas
    // the pixel font is wide: display text shrinks by this in the 8-bit skin
    readonly property real displayScale: skin === "pixel" ? (pixelLoader.status === FontLoader.Ready ? 0.42 : 0.8) : 1.0
    readonly property string body: skin === "pixel" ? "Menlo" : (ft88Loader.status === FontLoader.Ready ? ft88Loader.font.family : "monospace")

    // ── language: English or European Portuguese (lib/i18n.js), switched top right, remembered ──
    property Settings langStore: Settings { category: "freequencies"; property string lang: "en"; property string skin: "classic" }
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
