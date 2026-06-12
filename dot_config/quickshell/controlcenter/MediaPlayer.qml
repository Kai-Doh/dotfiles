import QtQuick
import Quickshell.Services.Mpris

// Now-playing media card: album art, title/artist, prev · play/pause · next,
// and a seek bar. Native MPRIS (no playerctl). Collapses when nothing plays.
Item {
    id: root
    property var colors

    // Prefer a player that's actually playing, else the first available.
    readonly property var player: {
        var ps = Mpris.players ? Mpris.players.values : null;
        if (!ps || ps.length === 0) return null;
        for (var i = 0; i < ps.length; i++)
            if (ps[i].isPlaying) return ps[i];
        return ps[0];
    }
    readonly property bool has: player !== null
    readonly property string title: has && player.trackTitle ? player.trackTitle : ""
    readonly property string artist: has && player.trackArtist ? player.trackArtist : ""
    readonly property string art: has && player.trackArtUrl ? player.trackArtUrl : ""

    visible: has && title.length > 0
    implicitHeight: visible ? 96 : 0

    // Tick to keep the seek bar moving while playing.
    property int tick: 0
    Timer { interval: 1000; running: root.visible && root.has && root.player.isPlaying; repeat: true; onTriggered: root.tick++ }

    Rectangle {
        anchors.fill: parent
        color: root.colors.surface
        radius: 0

        Row {
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                margins: 8
            }
            height: 72
            spacing: 10

            // Album art (square) with a music-glyph fallback.
            Rectangle {
                width: 72; height: 72
                color: root.colors.surfaceHigh
                radius: 0
                Text {
                    anchors.centerIn: parent
                    visible: albumArt.status !== Image.Ready
                    text: "󰝚"
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 28
                    color: root.colors.primary
                }
                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: root.art
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }

            // Title / artist / controls.
            Column {
                width: parent.width - 72 - 10
                spacing: 2
                Text {
                    width: parent.width
                    text: root.title
                    color: root.colors.fg
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: root.artist.length > 0
                    text: root.artist
                    color: root.colors.outline
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                // Controls spread evenly across the full card width.
                Row {
                    width: parent.width
                    topPadding: 6
                    Item {
                        width: parent.width / 3; height: 30
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: "CaskaydiaMono Nerd Font"; font.pixelSize: 22
                            color: root.has && root.player.canGoPrevious ? root.colors.primary : root.colors.outline
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.has) root.player.previous()
                        }
                    }
                    Item {
                        width: parent.width / 3; height: 30
                        Text {
                            anchors.centerIn: parent
                            text: root.has && root.player.isPlaying ? "󰏤" : "󰐊"
                            font.family: "CaskaydiaMono Nerd Font"; font.pixelSize: 26
                            color: root.colors.primary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.has) root.player.togglePlaying()
                        }
                    }
                    Item {
                        width: parent.width / 3; height: 30
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: "CaskaydiaMono Nerd Font"; font.pixelSize: 22
                            color: root.has && root.player.canGoNext ? root.colors.primary : root.colors.outline
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.has) root.player.next()
                        }
                    }
                }
            }
        }

        // Seek bar (click to seek when supported).
        Rectangle {
            id: track
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8 }
            height: 4
            color: root.colors.surfaceHigh
            radius: 0
            visible: root.has && root.player.lengthSupported && root.player.length > 0

            readonly property real frac: {
                root.tick; // re-evaluate each second
                if (!root.has || !root.player.length) return 0;
                return Math.max(0, Math.min(1, root.player.position / root.player.length));
            }
            Rectangle {
                width: parent.width * parent.frac
                height: parent.height
                color: root.colors.primary
                radius: 0
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                enabled: root.has && root.player.canSeek
                onClicked: function (m) {
                    if (root.has && root.player.length)
                        root.player.position = (m.x / track.width) * root.player.length;
                }
            }
        }
    }
}
