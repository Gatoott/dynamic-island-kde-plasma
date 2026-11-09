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
        } else if (name === "speaker.wave.1.fill") {
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
            var scx1 = w * 0.44;
            var scy1 = h * 0.50;
            ctx.beginPath();
            ctx.arc(scx1, scy1, w * 0.22, -Math.PI * 0.28, Math.PI * 0.28);
            ctx.stroke();
        } else if (name === "speaker.fill") {
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
        } else if (name === "eye" || name === "eye.fill") {
            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            ctx.beginPath();
            ctx.moveTo(w * 0.10, h * 0.50);
            ctx.quadraticCurveTo(w * 0.50, h * 0.16, w * 0.90, h * 0.50);
            ctx.quadraticCurveTo(w * 0.50, h * 0.84, w * 0.10, h * 0.50);
            ctx.stroke();

            ctx.fillStyle = iconCanvas.color;
            ctx.beginPath();
            ctx.arc(w * 0.50, h * 0.50, w * 0.18, 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "music.note") {
            ctx.fillStyle = iconCanvas.color;
            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            // Note head (tilted oval)
            ctx.save();
            ctx.translate(w * 0.36, h * 0.72);
            ctx.rotate(-20 * Math.PI / 180);
            ctx.scale(1.3, 0.9);
            ctx.beginPath();
            ctx.arc(0, 0, w * 0.15, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();

            // Vertical stem & curved flag
            ctx.beginPath();
            ctx.moveTo(w * 0.52, h * 0.70);
            ctx.lineTo(w * 0.52, h * 0.18);
            ctx.bezierCurveTo(w * 0.74, h * 0.20, w * 0.84, h * 0.38, w * 0.82, h * 0.56);
            ctx.stroke();
        } else if (name === "timer") {
            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            var cx = w * 0.50;
            var cy = h * 0.56;
            var r = w * 0.35;

            // Watch body circle
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.stroke();

            // Top crown / push button
            ctx.beginPath();
            ctx.moveTo(cx, cy - r);
            ctx.lineTo(cx, h * 0.10);
            ctx.moveTo(w * 0.38, h * 0.10);
            ctx.lineTo(w * 0.62, h * 0.10);
            ctx.stroke();

            // Angled clicker at top right (45 deg)
            ctx.beginPath();
            ctx.moveTo(cx + r * 0.68, cy - r * 0.68);
            ctx.lineTo(cx + r * 0.92, cy - r * 0.92);
            ctx.stroke();

            // Timer clock hand inside pointing to ~1:30
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.lineTo(cx + r * 0.45, cy - r * 0.45);
            ctx.stroke();
        } else if (name === "calendar") {
            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            var calX = w * 0.15;
            var calY = h * 0.22;
            var calW = w * 0.70;
            var calH = h * 0.66;
            var calR = w * 0.12;

            drawRoundRect(ctx, calX, calY, calW, calH, calR);
            ctx.stroke();

            // Top hooks
            ctx.beginPath();
            ctx.moveTo(w * 0.34, h * 0.12);
            ctx.lineTo(w * 0.34, h * 0.26);
            ctx.moveTo(w * 0.66, h * 0.12);
            ctx.lineTo(w * 0.66, h * 0.26);
            ctx.stroke();

            // Horizontal header divider
            ctx.beginPath();
            ctx.moveTo(calX, h * 0.44);
            ctx.lineTo(calX + calW, h * 0.44);
            ctx.stroke();

            // Mini date dots inside calendar
            ctx.fillStyle = iconCanvas.color;
            var dotR = w * 0.055;
            var dY1 = h * 0.58;
            var dY2 = h * 0.74;
            var dX1 = w * 0.35;
            var dX2 = w * 0.50;
            var dX3 = w * 0.65;

            ctx.beginPath();
            ctx.arc(dX1, dY1, dotR, 0, Math.PI * 2);
            ctx.arc(dX2, dY1, dotR, 0, Math.PI * 2);
            ctx.arc(dX3, dY1, dotR, 0, Math.PI * 2);
            ctx.arc(dX1, dY2, dotR, 0, Math.PI * 2);
            ctx.arc(dX2, dY2, dotR, 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "slider.horizontal.3") {
            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            var leftX = w * 0.14;
            var rightX = w * 0.86;
            var knobH = h * 0.12;

            // Track 1 & knob
            var y1 = h * 0.26;
            ctx.beginPath();
            ctx.moveTo(leftX, y1);
            ctx.lineTo(rightX, y1);
            ctx.moveTo(w * 0.35, y1 - knobH);
            ctx.lineTo(w * 0.35, y1 + knobH);
            ctx.stroke();

            // Track 2 & knob
            var y2 = h * 0.50;
            ctx.beginPath();
            ctx.moveTo(leftX, y2);
            ctx.lineTo(rightX, y2);
            ctx.moveTo(w * 0.68, y2 - knobH);
            ctx.lineTo(w * 0.68, y2 + knobH);
            ctx.stroke();

            // Track 3 & knob
            var y3 = h * 0.74;
            ctx.beginPath();
            ctx.moveTo(leftX, y3);
            ctx.lineTo(rightX, y3);
            ctx.moveTo(w * 0.45, y3 - knobH);
            ctx.lineTo(w * 0.45, y3 + knobH);
            ctx.stroke();
        } else if (name === "doc.on.clipboard") {
            ctx.strokeStyle = iconCanvas.color;
            ctx.lineWidth = iconCanvas.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            // Board outline
            var bX = w * 0.18;
            var bY = h * 0.20;
            var bW = w * 0.64;
            var bH = h * 0.70;
            var bR = w * 0.10;
            drawRoundRect(ctx, bX, bY, bW, bH, bR);
            ctx.stroke();

            // Top clip
            var cX = w * 0.35;
            var cY = h * 0.10;
            var cW = w * 0.30;
            var cH = h * 0.16;
            var cR = w * 0.06;
            drawRoundRect(ctx, cX, cY, cW, cH, cR);
            ctx.fillStyle = iconCanvas.circleColor;
            ctx.fill();
            ctx.stroke();

            // Document text lines
            ctx.beginPath();
            ctx.moveTo(w * 0.32, h * 0.44);
            ctx.lineTo(w * 0.68, h * 0.44);
            ctx.moveTo(w * 0.32, h * 0.58);
            ctx.lineTo(w * 0.68, h * 0.58);
            ctx.moveTo(w * 0.32, h * 0.72);
            ctx.lineTo(w * 0.54, h * 0.72);
            ctx.stroke();
        }
    }
}
