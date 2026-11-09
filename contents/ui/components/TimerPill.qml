pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property color accentColor: "#3daee9"
    property string clockFontFamily: ""
    property string timerState: "idle" // "idle", "running", "paused", "finished"
    property int remainingSeconds: 0
    property int totalDuration: 0
    property real targetTimestamp: 0.0

    readonly property bool isRunning: timerState === "running"
    readonly property bool isPaused: timerState === "paused"
    readonly property bool isFinished: timerState === "finished"

    readonly property real progressFraction: {
        if (totalDuration <= 0) return 0.0;
        if (isFinished) return 0.0;
        return Math.max(0.0, Math.min(1.0, remainingSeconds / totalDuration));
    }

    signal requestOpenTimer()

    function formatTime(totalSec) {
        if (totalSec < 0) totalSec = 0;
        var h = Math.floor(totalSec / 3600);
        var m = Math.floor((totalSec % 3600) / 60);
        var s = totalSec % 60;

        var ss = (s < 10 ? "0" : "") + s;
        if (h > 0) {
            var mm = (m < 10 ? "0" : "") + m;
            return h + ":" + mm + ":" + ss;
        } else {
            return m + ":" + ss;
        }
    }

    function formatTargetTime(ts) {
        if (ts <= 0 || !isRunning) return "";
        var d = new Date(ts * 1000);
        var h = d.getHours();
        var m = d.getMinutes();
        var hh = (h < 10 ? "0" : "") + h;
        var mm = (m < 10 ? "0" : "") + m;
        return hh + ":" + mm;
    }

    onProgressFractionChanged: miniRingCanvas.requestPaint()
    onTimerStateChanged: miniRingCanvas.requestPaint()
    onAccentColorChanged: miniRingCanvas.requestPaint()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 9

        // 1. Mini Progress Ring Icon
        Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22

            Canvas {
                id: miniRingCanvas
                anchors.fill: parent

                onPaint: {
                    var ctx = getContext("2d");
                    if (ctx.reset) ctx.reset();
                    else ctx.clearRect(0, 0, width, height);

                    var cx = width / 2;
                    var cy = height / 2;
                    var radius = (width / 2) - 2.5;
                    var strokeW = 2.5;

                    // Track Ring
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, 2 * Math.PI, false);
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.14);
                    ctx.lineWidth = strokeW;
                    ctx.stroke();

                    // Active Arc
                    var frac = root.progressFraction;
                    if (frac > 0) {
                        ctx.beginPath();
                        var startAngle = -Math.PI / 2;
                        var endAngle = startAngle + (frac * 2 * Math.PI);
                        ctx.arc(cx, cy, radius, startAngle, endAngle, false);

                        var col = root.accentColor;
                        if (root.isPaused) col = Qt.color("#f39c12");
                        else if (root.isFinished) col = Qt.color("#e74c3c");

                        ctx.strokeStyle = col;
                        ctx.lineWidth = strokeW;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }
            }

            // Inner icon
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 10
                height: 10
                source: root.isFinished ? "dialog-warning" : (root.isPaused ? "media-playback-pause" : "chronometer")
                color: root.isFinished ? "#e74c3c" : (root.isPaused ? "#f39c12" : root.accentColor)
            }
        }

        // 2. Status & Countdown Text
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.isFinished ? (typeof i18n !== "undefined" ? i18n("Timer Selesai!") : "Timer Selesai!") : (typeof i18n !== "undefined" ? i18n("Timer") : "Timer")
                font.pixelSize: 10
                font.bold: true
                color: root.isFinished ? "#e74c3c" : Qt.rgba(1, 1, 1, 0.60)
                font.family: "Inter, Roboto, sans-serif"
            }

            Text {
                text: {
                    if (root.isFinished) return "00:00";
                    return root.formatTime(root.remainingSeconds) + (root.isPaused ? " (" + (typeof i18n !== "undefined" ? i18n("Dijeda") : "Dijeda") + ")" : "");
                }
                font.pixelSize: 12
                font.bold: true
                color: root.isFinished ? "#e74c3c" : "#ffffff"
                font.family: root.clockFontFamily !== "" ? root.clockFontFamily : "Inter, Roboto, sans-serif"
            }
        }

        // 3. Target End Time Badge
        Rectangle {
            Layout.preferredHeight: 18
            Layout.preferredWidth: targetTimeText.implicitWidth + 10
            radius: 9
            visible: root.isRunning && root.targetTimestamp > 0
            color: Qt.rgba(1, 1, 1, 0.10)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)

            Text {
                id: targetTimeText
                anchors.centerIn: parent
                text: root.formatTargetTime(root.targetTimestamp)
                font.pixelSize: 9
                font.bold: true
                color: Qt.rgba(1, 1, 1, 0.75)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.requestOpenTimer()
    }
}
