// A tiny pixel-art sprite for the 8-bit skin. `rows` is a list of strings, one character per
// pixel; `colors` maps each character to a colour ("." and space are see-through). `frames` holds
// more row-sets to flip between (`frame` picks one), for blinks and wobbles.
import QtQuick

Canvas {
    id: sp
    property var rows: []
    property var frames: []
    property int frame: 0
    property var colors: ({})
    property int px: 3
    readonly property var cur: frames.length ? frames[frame % frames.length] : rows
    width: (cur.length ? cur[0].length : 0) * px
    height: cur.length * px
    renderTarget: Canvas.Image
    onCurChanged: requestPaint()
    onColorsChanged: requestPaint()
    onPxChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        for (var y = 0; y < cur.length; y++) {
            var r = cur[y]
            for (var x = 0; x < r.length; x++) {
                var c = colors[r[x]]
                if (!c) continue
                ctx.fillStyle = c
                ctx.fillRect(x * px, y * px, px, px)
            }
        }
    }
}
