pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property color accentColor: "#3daee9"
    property string clockFontFamily: ""
    property string eyeState: "idle" // "idle", "running", "break"
    property int intervalMinutes: 20
    property int remainingSeconds: 1200
    property int breakDuration: 20
    property int timeSinceLastBreak: 0
    property bool isOverdue: false
    property bool isPaused: false

    readonly property bool isRunning: eyeState === "running"
    readonly property bool isBreak: eyeState === "break"

    readonly property real progressFraction: {
        if (isBreak) {
            return breakDuration > 0 ? Math.max(0.0, Math.min(1.0, remainingSeconds / breakDuration)) : 0.0;
        }
        var totalSec = intervalMinutes * 60;
        return totalSec > 0 ? Math.max(0.0, Math.min(1.0, remainingSeconds / totalSec)) : 0.0;
    }

    signal requestOpenEye()

    function formatTime(totalSec) {
        if (totalSec < 0) totalSec = 0;
        var m = Math.floor(totalSec / 60);
        var s = totalSec % 60;
        var ss = (s < 10 ? "0" : "") + s;
        return m + ":" + ss;
    }

    onProgressFractionChanged: miniEyeRingCanvas.requestPaint()
    onEyeStateChanged: miniEyeRingCanvas.requestPaint()
    onIsOverdueChanged: miniEyeRingCanvas.requestPaint()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 9

        // 1. Mini Circular Progress Ring with Eye Icon
        Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22

            Canvas {
                id: miniEyeRingCanvas
                anchors.fill: parent

                onPaint: {
                    var ctx = getContext("2d");
                    if (ctx.reset) ctx.reset();
                    else ctx.clearRect(0, 0, width, height);

                    var cx = width / 2;
                    var cy = height / 2;
                    var radius = (width / 2) - 2.5;
                    var strokeW = 2.5;

                    // Track
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, 2 * Math.PI, false);
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.14);
                    ctx.lineWidth = strokeW;
                    ctx.stroke();

                    // Arc
                    var frac = root.progressFraction;
                    if (frac > 0) {
                        ctx.beginPath();
                        var startAngle = -Math.PI / 2;
                        var endAngle = startAngle + (frac * 2 * Math.PI);
                        ctx.arc(cx, cy, radius, startAngle, endAngle, false);

                        var col = root.accentColor;
                        if (root.isBreak) col = Qt.color("#2ecc71");
                        else if (root.isOverdue) col = Qt.color("#e74c3c");
                        else if (root.isPaused) col = Qt.color("#f39c12");

                        ctx.strokeStyle = col;
                        ctx.lineWidth = strokeW;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }
            }

            SFSymbolIcon {
                anchors.centerIn: parent
                width: 11
                height: 11
                name: "eye"
                color: root.isBreak ? "#2ecc71" : (root.isOverdue ? "#e74c3c" : root.accentColor)
            }
        }

        // 2. Status Label & Digits
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: {
                    if (root.isBreak) return (typeof i18n !== "undefined" ? i18n("Rehat Mata") : "Rehat Mata");
                    if (root.isOverdue) return (typeof i18n !== "undefined" ? i18n("⚠️ Butuh Rehat") : "⚠️ Butuh Rehat");
                    if (root.isPaused) return (typeof i18n !== "undefined" ? i18n("Layar Dijeda") : "Layar Dijeda");
                    return (typeof i18n !== "undefined" ? i18n("Istirahat Mata") : "Istirahat Mata");
                }
                font.pixelSize: 10
                font.bold: true
                color: root.isBreak ? "#2ecc71" : (root.isOverdue ? "#e74c3c" : Qt.rgba(1, 1, 1, 0.60))
                font.family: "Inter, Roboto, sans-serif"
            }

            Text {
                text: {
                    if (root.isBreak) return root.remainingSeconds + "s " + (typeof i18n !== "undefined" ? i18n("Lihat Jauh") : "Lihat Jauh");
                    return root.formatTime(root.remainingSeconds);
                }
                font.pixelSize: 12
                font.bold: true
                color: root.isBreak ? "#2ecc71" : (root.isOverdue ? "#e74c3c" : "#ffffff")
                font.family: root.clockFontFamily !== "" ? root.clockFontFamily : "Inter, Roboto, sans-serif"
            }
        }

        // 3. Mini Badge / Status Indicator
        Rectangle {
            Layout.preferredHeight: 18
            Layout.preferredWidth: badgeText.implicitWidth + 10
            radius: 9
            color: root.isBreak ? Qt.rgba(0.18, 0.8, 0.44, 0.2) : Qt.rgba(1, 1, 1, 0.10)
            border.width: 1
            border.color: root.isBreak ? "#2ecc71" : Qt.rgba(1, 1, 1, 0.15)

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: root.isBreak ? "6m" : (Math.floor(root.timeSinceLastBreak / 60) + "m")
                font.pixelSize: 9
                font.bold: true
                color: root.isBreak ? "#2ecc71" : Qt.rgba(1, 1, 1, 0.75)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.requestOpenEye()
    }
}

