import QtQuick.Effects

// Soft drop shadow for floating overlays, applied via `layer.effect` so the
// content stays fully interactive (layering only affects rendering). The host
// item must be inset from its window edges by ~16px so the shadow has room.
MultiEffect {
    shadowEnabled: true
    shadowColor: Qt.rgba(0, 0, 0, 0.55)
    shadowBlur: 1.0
    blurMax: 14
    shadowVerticalOffset: 4
    shadowHorizontalOffset: 0
    autoPaddingEnabled: true
}
