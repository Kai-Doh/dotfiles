import QtQuick
import Quickshell.Services.Pipewire

// Audio output via Pipewire. Scroll over the icon to change volume, click to
// open a slider popout with a mute toggle. Replaces waybar's external hyprwat.
Item {
    id: root
    property var colors

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    readonly property bool ready: sink && sink.audio
    readonly property real vol: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property int pct: Math.round(vol * 100)

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 26

    function setVol(v) { if (ready) sink.audio.volume = Math.max(0, Math.min(1.5, v)); }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted; }

    readonly property var icons: ["󰕿", "󰖀", "󰕾"]
    function icon() {
        if (muted || pct === 0) return "󰝟";
        return icons[Math.min(2, Math.floor(pct / 34))];
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Text {
            text: root.icon()
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 15
            color: root.muted ? root.colors.outline : root.colors.primary
        }
        Text {
            text: root.pct + "%"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 13
            color: root.colors.fg
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (m) {
            if (m.button === Qt.RightButton) root.toggleMute();
            else pop.open = !pop.open;
        }
        onWheel: function (w) {
            root.setVol(root.vol + (w.angleDelta.y > 0 ? 0.05 : -0.05));
        }
    }

    BarPopout {
        id: pop
        anchorItem: root
        colors: root.colors
        panelWidth: 240
        panelHeight: 78

        Column {
            anchors.fill: parent
            spacing: 10
            Row {
                width: parent.width
                Text {
                    text: "Volume"
                    color: root.colors.fg
                    font.pixelSize: 13
                    width: parent.width - muteBtn.width
                }
                Text {
                    id: muteBtn
                    text: root.muted ? "󰝟 muted" : "󰕾 " + root.pct + "%"
                    font.family: "CaskaydiaMono Nerd Font"
                    color: root.muted ? root.colors.outline : root.colors.primary
                    font.pixelSize: 13
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleMute()
                    }
                }
            }
            BarSlider {
                width: parent.width
                colors: root.colors
                value: root.vol
                onMoved: function (v) { root.setVol(v); }
            }
        }
    }
}
