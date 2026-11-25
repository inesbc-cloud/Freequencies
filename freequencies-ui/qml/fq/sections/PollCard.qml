// One poll: the question, each option with its votes, tap to vote (tap again to change).
import QtQuick
import QtQuick.Layouts
import ".."
import "../lib/network.js" as Network

Rectangle {
    id: pc
    property var app
    property var host                          // the event (or network anchor) the poll lives on
    property var poll                          // { id, author, d: { q, options, closes } }
    signal edit()
    readonly property string me: app.meOn(host)
    readonly property var t: Network.tally(host, poll, me, app.nowTick)
    Layout.fillWidth: true; implicitHeight: pcc.implicitHeight + 20
    color: Fq.mantle; border.width: Fq.bw; border.color: Fq.line
    ColumnLayout {
        id: pcc
        x: 12; y: 10; width: parent.width - 24; spacing: 5
        RowLayout { Layout.fillWidth: true
            FText { Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 14; font.bold: true; textFormat: Text.PlainText; text: pc.poll.d.q }
            Badge { visible: pc.t.closed; text: Fq.t("closed"); tone: Fq.faint }
            Link { visible: pc.poll.author === pc.me; text: Fq.t("edit"); tone: Fq.faint; onClicked: pc.edit() } }
        Repeater {
            model: pc.poll.d.options
            delegate: Item {
                required property var modelData
                required property int index
                Layout.fillWidth: true; implicitHeight: 28
                Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: pc.t.mine === index ? Fq.lime : Fq.line }
                Rectangle { height: parent.height; width: pc.t.total ? parent.width * pc.t.counts[index] / pc.t.total : 0; color: Fq.lime; opacity: 0.22 }
                FText { x: 10; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13; textFormat: Text.PlainText
                    text: (pc.t.mine === index ? "✓ " : "") + modelData; font.bold: pc.t.leaders.indexOf(index) >= 0 }
                FText { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 12; color: Fq.sub; text: String(pc.t.counts[index]) }
                MouseArea { anchors.fill: parent; enabled: !pc.t.closed; cursorShape: Qt.PointingHandCursor; onClicked: pc.app.vote(pc.host, pc.poll.id, index) }
            }
        }
        FText { color: Fq.faint; font.pixelSize: 11
            text: Fq.t("%1 votes", [pc.t.total]) + (pc.poll.d.closes ? " · " + Fq.t("closes %1", [pc.poll.d.closes]) : "") }
    }
}
