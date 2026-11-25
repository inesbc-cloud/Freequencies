// The skin's backdrop: CRT scanlines (classic), or a kooky 8-bit universe: twinkling stars, a UFO
// beaming up a cow, a waving one-eyed alien, a ringed planet, a rocket and the odd shooting star.
// Sits behind content; quiet enough to read over. Small areas (the header) get a lone UFO.
import QtQuick

Item {
    id: deco
    property real strength: 1.0              // 0..1: how present the decoration is
    readonly property bool pixel: Fq.skin === "pixel"
    readonly property bool big: height > 220
    clip: true

    // classic: scanlines
    Repeater {
        model: Fq.skin === "classic" ? Math.ceil(deco.height / 4) : 0
        delegate: Rectangle { required property int index; y: index * 4 + 3; width: deco.width; height: 1; color: Fq.lime; opacity: 0.05 * deco.strength }
    }

    // ── 8-bit universe ──
    property int tw: 0                        // twinkle phase
    Timer { running: deco.pixel && deco.visible; interval: 650; repeat: true; onTriggered: deco.tw = (deco.tw + 1) % 60 }
    Repeater {
        model: deco.pixel ? Math.min(220, Math.round(deco.width * deco.height / 5200)) : 0
        delegate: Rectangle {
            required property int index
            readonly property real r1: ((index * 9301 + 49297) % 233280) / 233280
            readonly property real r2: ((index * 4271 + 1013) % 7919) / 7919
            readonly property bool twinkles: index % 3 === 0
            x: Math.floor(r1 * deco.width / 3) * 3; y: Math.floor(r2 * deco.height / 3) * 3
            width: index % 11 === 0 ? 4 : 2; height: width
            color: index % 7 === 0 ? Fq.acid : index % 5 === 0 ? Fq.lime : Fq.text
            opacity: (twinkles && (index + deco.tw) % 4 === 0 ? 0.05 : 0.25 + (index % 4) * 0.15) * deco.strength
        }
    }

    // sprites (8-bit palette)
    readonly property var ufoFrames: [[
        "......ccc......",
        ".....cwwwc.....",
        "....cwwwwwc....",
        "..mmmmmmmmmmm..",
        ".mmymmmmymmmym.",
        "mmmmmmmmmmmmmmm",
        "..mmmmmmmmmmm..",
        "....m.....m...."], [
        "......ccc......",
        ".....cwwwc.....",
        "....cwwwwwc....",
        "..mmmmmmmmmmm..",
        ".mmmmymmmmymmm.",
        "mmmmmmmmmmmmmmm",
        "..mmmmmmmmmmm..",
        "....m.....m...."]]
    readonly property var ufoColors: ({ c: "#3ef0ff", w: "#c9fbff", m: "#8f6bff", y: "#ffd93f" })

    // a lone UFO drifting across the header
    Loader {
        active: deco.pixel && !deco.big
        anchors.fill: parent
        sourceComponent: Item {
            PixelSprite {
                id: miniUfo
                px: 2; frames: deco.ufoFrames; colors: deco.ufoColors
                opacity: 0.8 * deco.strength
                frame: deco.tw % 2
                y: (parent.height - height) / 2 + bob
                property real bob: 0
                SequentialAnimation on bob { loops: Animation.Infinite
                    NumberAnimation { from: -5; to: 5; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 5; to: -5; duration: 1400; easing.type: Easing.InOutSine } }
                NumberAnimation on x { loops: Animation.Infinite; from: -40; to: deco.width + 40; duration: 32000 }
            }
        }
    }

    // the full scene on big pages (Home)
    Loader {
        active: deco.pixel && deco.big
        anchors.fill: parent
        sourceComponent: Item {
            id: scene
            opacity: Math.min(1, 0.6 * deco.strength + 0.3)

            // ringed planet, low in the middle (the scene lives in the usually-empty bottom of Home)
            PixelSprite {
                px: 5; x: scene.width * 0.36; y: scene.height - height - 150 + fl
                property real fl: 0
                SequentialAnimation on fl { loops: Animation.Infinite
                    NumberAnimation { from: 0; to: 8; duration: 4200; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 8; to: 0; duration: 4200; easing.type: Easing.InOutSine } }
                colors: ({ p: "#ff8a3d", q: "#ffd93f", r: "#3ef0ff" })
                rows: ["......ppppp......",
                       "....pqqpppppp....",
                       "...pqqpppppppp...",
                       "rr.ppppppppppp.rr",
                       "..rrrrrrrrrrrrr..",
                       "...ppprrrrrppp...",
                       "...ppppppppppp...",
                       "....ppppppppp....",
                       "......ppppp......"]
            }

            // UFO beaming up a cow, lower left
            Item {
                id: abduct
                width: 15 * 4; height: 230
                x: scene.width * 0.2; y: scene.height - height - 30
                property real bob: 0
                SequentialAnimation on bob { loops: Animation.Infinite
                    NumberAnimation { from: -6; to: 6; duration: 1600; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 6; to: -6; duration: 1600; easing.type: Easing.InOutSine } }
                // the beam
                Canvas {
                    id: beam
                    y: 30 + abduct.bob; width: parent.width; height: parent.height - y
                    property real flick: 0.35
                    SequentialAnimation on flick { loops: Animation.Infinite
                        NumberAnimation { to: 0.5; duration: 300 } NumberAnimation { to: 0.3; duration: 500 } NumberAnimation { to: 0.45; duration: 200 } }
                    opacity: flick
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                        for (var i = 0; i < height; i += 4) {        // stepped, pixelly cone
                            var w = width * 0.25 + (width * 0.75) * (i / height)
                            ctx.fillStyle = (Math.floor(i / 4) % 2) ? "#3ef0ff" : "#c9fbff"
                            ctx.fillRect((width - w) / 2, i, w, 3)
                        }
                    }
                    onHeightChanged: requestPaint()
                }
                // the cow, rising, spinning gently
                PixelSprite {
                    id: cow
                    px: 4; x: (parent.width - width) / 2
                    colors: ({ w: "#f4f4ff", k: "#0b0b2e", p: "#ff9bf0", h: "#ffd93f" })
                    rows: ["k........h.h",
                           "k........www",
                           "wwwkkwwwwwkw",
                           "wkkkwwwkkwww",
                           "wwwwwkkkwppp",
                           "wwwwwwwwww..",
                           "w.w....w.w..",
                           "k.k....k.k.."]
                    property real rise: 0
                    y: abduct.height - height - rise * (abduct.height - height - 40)
                    rotation: Math.sin(rise * 9) * 14
                    opacity: rise > 0.92 ? (1 - rise) * 12 : 1
                    NumberAnimation on rise { loops: Animation.Infinite; from: 0; to: 1; duration: 9000; easing.type: Easing.InQuad }
                }
                PixelSprite {
                    px: 4; y: abduct.bob; frames: deco.ufoFrames; colors: deco.ufoColors
                    frame: deco.tw % 2
                }
            }

            // a second UFO wandering across the top
            PixelSprite {
                px: 2; frames: deco.ufoFrames; colors: deco.ufoColors; frame: (deco.tw + 1) % 2
                y: 18 + Math.sin(x / 70) * 10
                NumberAnimation on x { loops: Animation.Infinite; from: scene.width + 40; to: -60; duration: 45000 }
            }

            // one-eyed alien waving, bottom left (blinks now and then)
            PixelSprite {
                px: 4; x: 40; y: scene.height - height - 26
                colors: ({ g: "#5cff7a", y: "#ffd93f", w: "#f4f4ff", k: "#0b0b2e" })
                frame: deco.tw % 8 === 7 ? 2 : deco.tw % 2
                frames: [[
                    "...y...y...",
                    "....g.g....",
                    "...ggggg...",
                    "g.ggwwwgg.g",
                    "g.gwwkwwg.g",
                    ".gggwwwggg.",
                    "...ggggg...",
                    "...g...g...",
                    "..gg...gg.."], [
                    "...y...y...",
                    "....g.g....",
                    "...ggggg...",
                    "..ggwwwgg..",
                    "..gwwkwwg..",
                    ".gggwwwggg.",
                    "g..ggggg..g",
                    "...g...g...",
                    "..gg...gg.."], [
                    "...y...y...",
                    "....g.g....",
                    "...ggggg...",
                    "..ggggggg..",
                    "..gkkkkkg..",
                    ".ggggggggg.",
                    "g..ggggg..g",
                    "...g...g...",
                    "..gg...gg.."]]
            }

            // rocket, bobbing near the planet with a flickering flame
            PixelSprite {
                px: 3; x: scene.width * 0.5; y: scene.height - 190 + fl; rotation: 18
                property real fl: 0
                SequentialAnimation on fl { loops: Animation.Infinite
                    NumberAnimation { from: 0; to: -14; duration: 2600; easing.type: Easing.InOutSine }
                    NumberAnimation { from: -14; to: 0; duration: 2600; easing.type: Easing.InOutSine } }
                colors: ({ r: "#ff5c5c", w: "#f4f4ff", b: "#3ef0ff", y: "#ffd93f", o: "#ff8a3d" })
                frame: deco.tw % 2
                frames: [[
                    "...r...", "..rrr..", "..www..", ".wwbww.", ".wbbbw.", ".wwbww.", ".wwwww.",
                    ".wwwww.", "rwwwwwr", "rr.w.rr", "..yoy..", "...y...", "......."], [
                    "...r...", "..rrr..", "..www..", ".wwbww.", ".wbbbw.", ".wwbww.", ".wwwww.",
                    ".wwwww.", "rwwwwwr", "rr.w.rr", "..oyo..", "..yoy..", "...o..."]]
            }

            // shooting star every few seconds
            Rectangle {
                id: shoot
                property real sx: 0; property real sy: 0; property real t: 0
                x: sx + t * 260; y: sy + t * 95
                width: 46; height: 3; rotation: 20
                opacity: t <= 0 || t >= 1 ? 0 : t < 0.2 ? t * 4.5 : (1 - t) * 1.1
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: "#f4f4ff" } }
                SequentialAnimation { running: true; loops: Animation.Infinite
                    PauseAnimation { duration: 5500 }
                    ScriptAction { script: { shoot.sx = scene.width * (0.2 + Math.random() * 0.5); shoot.sy = 20 + Math.random() * scene.height * 0.3 } }
                    NumberAnimation { target: shoot; property: "t"; from: 0; to: 1; duration: 750 }
                }
            }
        }
    }
}
