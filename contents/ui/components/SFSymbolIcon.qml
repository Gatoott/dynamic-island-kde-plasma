import QtQuick

Canvas {
    id: iconCanvas

    property string name: "chevron.left"
    property color color: "#ffffff"
    property real strokeWidth: 1.8
    property color circleColor: Qt.rgba(1, 1, 1, 0.16)

    width: 16
    height: 16

    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    onStrokeWidthChanged: requestPaint()
    onCircleColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function drawRoundRect(ctx, x, y, w, h, r) {
        if (r > w / 2) r = w / 2;
        if (r > h / 2) r = h / 2;
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
    }

    onPaint: {
        var ctx = getContext("2d");
        if (ctx.reset) {
            ctx.reset();
        } else {
            ctx.clearRect(0, 0, width, height);
        }

        var w = width;
        var h = height;

        if (name === "chevron.left" || name === "go-previous") {
            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            ctx.moveTo(w * 0.65, h * 0.16);
            ctx.lineTo(w * 0.30, h * 0.50);
            ctx.lineTo(w * 0.65, h * 0.84);
            ctx.stroke();
        } else if (name === "chevron.right" || name === "go-next") {
            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            ctx.moveTo(w * 0.35, h * 0.16);
            ctx.lineTo(w * 0.70, h * 0.50);
            ctx.lineTo(w * 0.35, h * 0.84);
            ctx.stroke();
        } else if (name === "play.fill") {
            ctx.fillStyle = iconCanvas.color;
            ctx.beginPath();
            ctx.moveTo(w * 0.32, h * 0.20);
            ctx.lineTo(w * 0.78, h * 0.50);
            ctx.lineTo(w * 0.32, h * 0.80);
            ctx.closePath();
            ctx.fill();
        } else if (name === "pause.fill") {
            ctx.fillStyle = iconCanvas.color;
            var barW = Math.max(2, w * 0.22);
            var barH = h * 0.62;
            var barY = (h - barH) / 2;
            drawRoundRect(ctx, w * 0.24, barY, barW, barH, barW / 2);
            ctx.fill();
            drawRoundRect(ctx, w * 0.76 - barW, barY, barW, barH, barW / 2);
            ctx.fill();
        } else if (name === "backward.fill") {
            ctx.fillStyle = iconCanvas.color;
            var bW = Math.max(2, w * 0.14);
            var bH = h * 0.64;
            var bY = (h - bH) / 2;
            drawRoundRect(ctx, w * 0.12, bY, bW, bH, bW / 2);
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(w * 0.88, h * 0.18);
            ctx.lineTo(w * 0.32, h * 0.50);
            ctx.lineTo(w * 0.88, h * 0.82);
            ctx.closePath();
            ctx.fill();
        } else if (name === "forward.fill") {
            ctx.fillStyle = iconCanvas.color;
            var fW = Math.max(2, w * 0.14);
            var fH = h * 0.64;
            var fY = (h - fH) / 2;
            ctx.beginPath();
            ctx.moveTo(w * 0.12, h * 0.18);
            ctx.lineTo(w * 0.68, h * 0.50);
            ctx.lineTo(w * 0.12, h * 0.82);
            ctx.closePath();
            ctx.fill();
            drawRoundRect(ctx, w * 0.88 - fW, fY, fW, fH, fW / 2);
            ctx.fill();
        } else if (name === "speaker.wave.2.fill") {
            ctx.fillStyle = iconCanvas.color;
            ctx.beginPath();
            ctx.moveTo(w * 0.10, h * 0.36);
            ctx.lineTo(w * 0.30, h * 0.36);
            ctx.lineTo(w * 0.52, h * 0.18);
            ctx.lineTo(w * 0.52, h * 0.82);
            ctx.lineTo(w * 0.30, h * 0.64);
            ctx.lineTo(w * 0.10, h * 0.64);
            ctx.closePath();
            ctx.fill();

            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            var scx = w * 0.44;
            var scy = h * 0.50;
            ctx.beginPath();
            ctx.arc(scx, scy, w * 0.22, -Math.PI * 0.28, Math.PI * 0.28);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(scx, scy, w * 0.40, -Math.PI * 0.28, Math.PI * 0.28);
            ctx.stroke();
        } else if (name === "speaker.slash.fill") {
            ctx.fillStyle = iconCanvas.color;
            ctx.beginPath();
            ctx.moveTo(w * 0.10, h * 0.36);
            ctx.lineTo(w * 0.30, h * 0.36);
            ctx.lineTo(w * 0.52, h * 0.18);
            ctx.lineTo(w * 0.52, h * 0.82);
            ctx.lineTo(w * 0.30, h * 0.64);
            ctx.lineTo(w * 0.10, h * 0.64);
            ctx.closePath();
            ctx.fill();

            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            var mx = w * 0.74, my = h * 0.50, mOff = w * 0.12;
            ctx.beginPath();
            ctx.moveTo(mx - mOff, my - mOff);
            ctx.lineTo(mx + mOff, my + mOff);
            ctx.moveTo(mx + mOff, my - mOff);
            ctx.lineTo(mx - mOff, my + mOff);
            ctx.stroke();
        } else if (name === "quote.bubble.fill") {
            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            var bw = w * 0.82;
            var bh = h * 0.60;
            var bx = (w - bw) / 2;
            var by = h * 0.16;
            var r = 3;

            ctx.beginPath();
            ctx.moveTo(bx + r, by);
            ctx.lineTo(bx + bw - r, by);
            ctx.arcTo(bx + bw, by, bx + bw, by + r, r);
            ctx.lineTo(bx + bw, by + bh - r);
            ctx.arcTo(bx + bw, by + bh, bx + bw - r, by + bh, r);
            ctx.lineTo(bx + 8, by + bh);
            ctx.lineTo(bx + 2, by + bh + 4);
            ctx.lineTo(bx + 5, by + bh);
            ctx.lineTo(bx + r, by + bh);
            ctx.arcTo(bx, by + bh, bx, by + bh - r, r);
            ctx.lineTo(bx, by + r);
            ctx.arcTo(bx, by, bx + r, by, r);
            ctx.closePath();
            ctx.stroke();

            ctx.beginPath();
            ctx.moveTo(bx + 4, by + bh * 0.38);
            ctx.lineTo(bx + bw - 4, by + bh * 0.38);
            ctx.moveTo(bx + 4, by + bh * 0.68);
            ctx.lineTo(bx + bw - 6, by + bh * 0.68);
            ctx.stroke();
        } else if (name === "bell.fill") {
            ctx.fillStyle = iconCanvas.color;
            ctx.beginPath();
            ctx.arc(w * 0.5, h * 0.14, w * 0.08, 0, Math.PI * 2);
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(w * 0.36, h * 0.22);
            ctx.lineTo(w * 0.64, h * 0.22);
            ctx.bezierCurveTo(w * 0.64, h * 0.45, w * 0.78, h * 0.68, w * 0.86, h * 0.74);
            ctx.lineTo(w * 0.14, h * 0.74);
            ctx.bezierCurveTo(w * 0.22, h * 0.68, w * 0.36, h * 0.45, w * 0.36, h * 0.22);
            ctx.closePath();
            ctx.fill();

            ctx.beginPath();
            ctx.arc(w * 0.5, h * 0.75, w * 0.11, 0, Math.PI);
            ctx.fill();
        } else if (name === "xmark.circle.fill") {
            ctx.fillStyle = iconCanvas.circleColor;
            ctx.beginPath();
            ctx.arc(w * 0.5, h * 0.5, w * 0.46, 0, Math.PI * 2);
            ctx.fill();

            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            var xOff = w * 0.16;
            ctx.beginPath();
            ctx.moveTo(w * 0.5 - xOff, h * 0.5 - xOff);
            ctx.lineTo(w * 0.5 + xOff, h * 0.5 + xOff);
            ctx.moveTo(w * 0.5 + xOff, h * 0.5 - xOff);
            ctx.lineTo(w * 0.5 - xOff, h * 0.5 + xOff);
            ctx.stroke();
        } else if (name === "xmark") {
            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            var sOff = w * 0.26;
            ctx.beginPath();
            ctx.moveTo(w * 0.5 - sOff, h * 0.5 - sOff);
            ctx.lineTo(w * 0.5 + sOff, h * 0.5 + sOff);
            ctx.moveTo(w * 0.5 + sOff, h * 0.5 - sOff);
            ctx.lineTo(w * 0.5 - sOff, h * 0.5 + sOff);
            ctx.stroke();
        }
    }
}
