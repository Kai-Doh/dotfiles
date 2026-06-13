import QtQuick

// A gradient-stroked border ring that matches the Hyprland active-window border
// (a diagonal primary -> tertiary -> secondary sweep, same 3 colors / ~45°).
// Transparent fill — overlay it on any panel with `anchors.fill` and a high `z`;
// it only paints the edge, so it doesn't block input to the content beneath.
//
//   GradientBorder {
//       anchors.fill: parent; z: 100
//       color1: c.primary; color2: c.tertiary; color3: c.secondary
//   }
Canvas {
    id: root
    property color color1: "transparent"
    property color color2: "transparent"
    property color color3: "transparent"
    property real borderWidth: 2
    property real radius: 0

    // Repaint whenever geometry or colors change (e.g. matugen retheme).
    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()
    onColor1Changed: requestPaint()
    onColor2Changed: requestPaint()
    onColor3Changed: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (width <= 0 || height <= 0)
            return;

        const bw = borderWidth;
        const x = bw / 2, y = bw / 2;          // inset so the stroke stays inside
        const w = width - bw, h = height - bw;
        const r = Math.max(0, radius - bw / 2);

        const g = ctx.createLinearGradient(0, 0, width, height); // diagonal
        g.addColorStop(0.0, color1);
        g.addColorStop(0.5, color2);
        g.addColorStop(1.0, color3);
        ctx.strokeStyle = g;
        ctx.lineWidth = bw;

        ctx.beginPath();
        ctx.moveTo(x + r, y);
        ctx.lineTo(x + w - r, y);
        ctx.arcTo(x + w, y, x + w, y + r, r);
        ctx.lineTo(x + w, y + h - r);
        ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
        ctx.lineTo(x + r, y + h);
        ctx.arcTo(x, y + h, x, y + h - r, r);
        ctx.lineTo(x, y + r);
        ctx.arcTo(x, y, x + r, y, r);
        ctx.closePath();
        ctx.stroke();
    }
}
