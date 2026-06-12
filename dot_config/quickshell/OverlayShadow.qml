import QtQuick

// Wraps a floating overlay in a soft drop shadow so it reads as "above" the
// workspace. Put the real (interactive) content as a child — it's laid into an
// inset `holder`; a hidden silhouette behind it casts the blurred shadow into
// the surrounding `pad`. Keeps content fully interactive (the caster is inert).
//
//   OverlayShadow { anchors.fill: parent; pad: 16
//       ControlCenter { anchors.fill: parent }
//   }
Item {
    id: root
    property int pad: 16
    property real radius: 0
    default property alias content: holder.data

    // Silhouette of the content; invisible itself, only its shadow shows. It is
    // exactly covered by the opaque content on top.
    Rectangle {
        id: caster
        anchors.fill: holder
        color: "black"
        radius: root.radius
        visible: false
        layer.enabled: true
    }
    ShadowEffect {
        anchors.fill: caster
        source: caster
    }

    Item {
        id: holder
        anchors.fill: parent
        anchors.margins: root.pad
    }
}
