import QtQuick
import Quickshell.Services.UPower

// Battery via UPower. Icon reflects charge level / charging state; tooltip-ish
// percentage shown inline. Turns red when low and not charging.
Item {
    id: root
    property var colors

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev && dev.isLaptopBattery
    // UPower percentage may be 0–1 or 0–100 depending on version; normalise.
    readonly property int pct: dev ? Math.round(dev.percentage <= 1 ? dev.percentage * 100 : dev.percentage) : 0
    readonly property bool charging: dev && (dev.state === UPowerDeviceState.Charging
                                             || dev.state === UPowerDeviceState.FullyCharged)
    readonly property bool low: pct <= 15 && !charging

    visible: present
    implicitWidth: present ? row.implicitWidth + 12 : 0
    implicitHeight: 26

    readonly property var levelIcons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    function levelIcon() {
        var i = Math.min(10, Math.max(0, Math.round(pct / 10)));
        return levelIcons[i];
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Text {
            text: root.charging ? "󰂄" : root.levelIcon()
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 15
            color: root.low ? root.colors.error : root.colors.primary
        }
        Text {
            text: root.pct + "%"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 13
            color: root.low ? root.colors.error : root.colors.fg
        }
    }
}
