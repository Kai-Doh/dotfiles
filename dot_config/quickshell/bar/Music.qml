import QtQuick
import Quickshell.Services.Mpris

// Now-playing via MPRIS (native, no playerctl polling). Shows the title;
// click toggles play/pause; popout has prev / play-pause / next + metadata.
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

    visible: has && title.length > 0
    implicitWidth: visible ? row.implicitWidth + 12 : 0
    implicitHeight: 26

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Text {
            text: root.has && root.player.isPlaying ? "󰏤" : "󰐊"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 14
            color: root.colors.secondary
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.title
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 13
            color: root.colors.secondary
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 220)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (m) {
            if (m.button === Qt.RightButton) pop.open = !pop.open;
            else if (root.has) root.player.togglePlaying();
        }
    }

    BarPopout {
        id: pop
        anchorItem: root
        colors: root.colors
        panelWidth: 280
        panelHeight: 96

        Column {
            anchors.fill: parent
            spacing: 8
            Text {
                width: parent.width
                text: root.title
                color: root.colors.fg
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.artist
                color: root.colors.outline
                font.pixelSize: 12
                elide: Text.ElideRight
                visible: root.artist.length > 0
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24
                Text {
                    text: "󰒮"; font.family: "CaskaydiaMono Nerd Font"; font.pixelSize: 20
                    color: root.has && root.player.canGoPrevious ? root.colors.primary : root.colors.outline
                    MouseArea { anchors.fill: parent; anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.has) root.player.previous() }
                }
                Text {
                    text: root.has && root.player.isPlaying ? "󰏤" : "󰐊"
                    font.family: "CaskaydiaMono Nerd Font"; font.pixelSize: 22; color: root.colors.primary
                    MouseArea { anchors.fill: parent; anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.has) root.player.togglePlaying() }
                }
                Text {
                    text: "󰒭"; font.family: "CaskaydiaMono Nerd Font"; font.pixelSize: 20
                    color: root.has && root.player.canGoNext ? root.colors.primary : root.colors.outline
                    MouseArea { anchors.fill: parent; anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.has) root.player.next() }
                }
            }
        }
    }
}
