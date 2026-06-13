import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"

// Transient on-screen toasts (the dunst replacement). Top-right overlay that
// doesn't reserve space. Each toast auto-expires; the notification still lives
// in the control-center list until dismissed there.
PanelWindow {
    id: win
    required property var notifs   // NotifService

    anchors { top: true; right: true }
    margins { top: 8; right: 8 }
    // Width/height include a 16px inset around the cards for the drop shadow.
    implicitWidth: 380 + 32
    implicitHeight: Math.max(1, column.implicitHeight + 32)
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"
    // Don't steal the keyboard from whatever is focused.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    visible: stack.length > 0

    Colors { id: c }

    // Active toasts (newest first). JS array of Notification objects.
    property var stack: []

    function remove(n) {
        win.stack = win.stack.filter(function (x) { return x !== n; });
    }

    Connections {
        target: win.notifs
        function onPopup(n) {
            // newest on top, cap the visible stack
            var s = [n].concat(win.stack.filter(function (x) { return x !== n; }));
            win.stack = s.slice(0, 5);
        }
        // When toasts get suppressed (control center opened), clear them — the
        // notifications are visible in the list there.
        function onSuppressPopupsChanged() { if (win.notifs.suppressPopups) win.stack = []; }
    }

    Column {
        id: column
        anchors { top: parent.top; right: parent.right; left: parent.left; margins: 4 }
        spacing: 8

        Repeater {
            model: win.stack
            delegate: Item {
                id: cell
                required property var modelData
                readonly property int pad: 14
                width: column.width
                implicitHeight: card.implicitHeight + pad * 2

                // Auto-expire: honour the notification's timeout, else 5s.
                Timer {
                    running: true
                    interval: (modelData.expireTimeout && modelData.expireTimeout > 0)
                              ? modelData.expireTimeout : 5000
                    onTriggered: win.remove(modelData)
                }
                // If dismissed elsewhere, drop the toast too.
                Connections {
                    target: modelData
                    function onClosed() { win.remove(modelData); }
                }

                // Drop shadow: a hidden silhouette behind the card.
                Rectangle {
                    id: caster
                    x: cell.pad; y: cell.pad
                    width: card.width; height: card.implicitHeight
                    color: "black"
                    visible: false
                    layer.enabled: true
                }
                ShadowEffect { anchors.fill: caster; source: caster }

                NotificationItem {
                    id: card
                    x: cell.pad; y: cell.pad
                    width: cell.width - cell.pad * 2
                    colors: c
                    notif: modelData
                    timeText: ""
                    // Just dismiss: the notification then emits `closed`, which
                    // the Connections block above catches and removes the toast.
                    onClosed: modelData.dismiss()
                }

                // Gradient frame matching the Hyprland window border.
                GradientBorder {
                    anchors.fill: card
                    z: 100
                    borderWidth: 2
                    radius: 0
                    color1: c.primary
                    color2: c.tertiary
                    color3: c.secondary
                }
            }
        }
    }
}
