import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Desktop audio visualizer — one full-screen surface per monitor, instantiated
// by Variants in shell.qml. Sits on the Bottom layer: above the awww wallpaper
// image, below every app window and the Top-layer bar. Fed by a dedicated cava
// instance (~/.config/cava/raw.conf) in raw stdout mode; bars are colored from
// the matugen palette (Colors.qml), so they retheme with the wallpaper.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    // Fill the whole screen, reserve no space.
    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell:visualizer"
    color: "transparent"

    // Click-through: empty input region so the wallpaper never eats pointer
    // events meant for the desktop/windows.
    mask: Region {}

    Colors { id: c }

    // Tunables.
    readonly property int barCount: 60
    readonly property real barSpacing: 3
    readonly property real maxBarHeight: root.height / 3
    readonly property real barWidth:
        (barField.width - barSpacing * (barCount - 1)) / barCount

    // Latest cava frame: array of ints 0..100.
    property var values: []

    Process {
        id: cavaProc
        running: true
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/raw.conf"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const parts = data.split(";")
                const arr = []
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i].length === 0) continue
                    arr.push(parseInt(parts[i]) || 0)
                }
                root.values = arr
            }
        }
        // Survive cava hiccups: restart shortly after an unexpected exit.
        onExited: restartTimer.start()
    }
    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: cavaProc.running = true
    }

    // Bars rise from the bottom edge across the full width.
    Item {
        id: barField
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: root.maxBarHeight

        Repeater {
            model: root.values
            // Bar "slot": clips to the live height, animating from the bottom.
            Item {
                required property int index
                required property var modelData
                width: root.barWidth
                x: index * (root.barWidth + root.barSpacing)
                anchors.bottom: parent.bottom
                height: Math.max(2, (modelData / 100) * root.maxBarHeight)
                clip: true
                opacity: 0.6
                Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                // Full-height gradient anchored to the bottom of the field, so a
                // given screen height is always the same palette color; the slot
                // above reveals only the slice up to this bar's current height.
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: root.maxBarHeight   // fixed: gradient doesn't scale with the bar
                    radius: 0                   // squared bars
                    gradient: Gradient {
                        // Fallback to primary if tertiary is momentarily undefined
                        // (one-reload window when matugen adds a new color property).
                        GradientStop { position: 0.0; color: c.tertiary ? c.tertiary : c.primary } // very tips: orange accent
                        GradientStop { position: 0.12; color: c.fg }         // bright crest
                        GradientStop { position: 0.5; color: c.primary }     // blue body
                        GradientStop { position: 1.0; color: c.surfaceHigh } // bottom (quiet)
                    }
                }
            }
        }
    }
}
