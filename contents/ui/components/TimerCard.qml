pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.dbus as DBus

Item {
    id: root

    implicitWidth: 500
    implicitHeight: 200

    property color accentColor: "#3daee9"
    property string clockFontFamily: ""

    // Timer State dari Backend D-Bus / Fallback
    property string timerState: "idle" // "idle", "running", "paused", "finished"
    property int remainingSeconds: 0
    property int totalDuration: 0
    property real targetTimestamp: 0.0
    property bool soundEnabled: true

    // Manual Input State
    property int inputHours: 0
    property int inputMinutes: 15
    property int inputSeconds: 0

    readonly property int totalInputSeconds: (inputHours * 3600) + (inputMinutes * 60) + inputSeconds
    readonly property bool isRunning: timerState === "running"
    readonly property bool isPaused: timerState === "paused"
    readonly property bool isFinished: timerState === "finished"
    readonly property bool isIdle: timerState === "idle"

    // Circular progress fraction (1.0 = penuh, 0.0 = habis)
    readonly property real progressFraction: {
        if (totalDuration <= 0) return 0.0;
        if (isFinished) return 0.0;
        return Math.max(0.0, Math.min(1.0, remainingSeconds / totalDuration));
    }

    // Format waktu sisa: "14:59" atau "01:25:30"
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

    // Format waktu target selesai (contoh: "Selesai 10:45")
    function formatTargetTime(ts) {
        if (ts <= 0 || !isRunning) return "";
        var d = new Date(ts * 1000);
        var h = d.getHours();
        var m = d.getMinutes();
        var hh = (h < 10 ? "0" : "") + h;
        var mm = (m < 10 ? "0" : "") + m;
        return (typeof i18n !== "undefined" ? i18n("Selesai") : "Selesai") + " " + hh + ":" + mm;
    }

    // --- D-Bus Integration ---
    DBusCall {
        id: dbusTimerCall
        busType: DBus.BusType.Session
        service: "org.kde.plasma.dynamicisland.timer"
        path: "/Timer"
        iface: "org.kde.plasma.dynamicisland.timer"
    }

    DBus.Properties {
        id: dbusTimerProps
        busType: DBus.BusType.Session
        service: "org.kde.plasma.dynamicisland.timer"
        path: "/Timer"
        iface: "org.kde.plasma.dynamicisland.timer"

        onPropertiesChanged: (ifaceName, changedProps, invalidated) => {
            if (changedProps["state"] !== undefined) root.timerState = changedProps["state"];
            if (changedProps["remainingSeconds"] !== undefined) root.remainingSeconds = changedProps["remainingSeconds"];
            if (changedProps["totalDuration"] !== undefined) root.totalDuration = changedProps["totalDuration"];
            if (changedProps["targetTimestamp"] !== undefined) root.targetTimestamp = changedProps["targetTimestamp"];
            if (changedProps["soundEnabled"] !== undefined) root.soundEnabled = changedProps["soundEnabled"];
        }

        Component.onCompleted: updateAll()
    }

    DBus.SignalWatcher {
        id: dbusTimerWatcher
        busType: DBus.BusType.Session
        service: "org.kde.plasma.dynamicisland.timer"
        path: "/Timer"
        iface: "org.kde.plasma.dynamicisland.timer"

        function dbusTimerUpdated(state, remaining_seconds, total_duration, target_timestamp) {
            root.timerState = state;
            root.remainingSeconds = remaining_seconds;
            root.totalDuration = total_duration;
            root.targetTimestamp = target_timestamp;
        }

        function dbusTimerFinished(total_duration) {
            root.timerState = "finished";
            root.remainingSeconds = 0;
        }
    }

    // Controller Actions
    function requestStart() {
        if (isPaused) {
            dbusTimerCall.call("Resume", []);
            return;
        }
        var sec = totalInputSeconds;
        if (sec <= 0) sec = 60; // default 1 menit jika 0
        dbusTimerCall.call("Start", [sec]);
    }

    function requestPause() {
        dbusTimerCall.call("Pause", []);
    }

    function requestReset() {
        dbusTimerCall.call("Reset", []);
    }

    function applyPreset(minutes) {
        inputHours = Math.floor(minutes / 60);
        inputMinutes = minutes % 60;
        inputSeconds = 0;
        if (isIdle || isFinished) {
            requestStart();
        }
    }

    onProgressFractionChanged: canvasRing.requestPaint()
    onAccentColorChanged: canvasRing.requestPaint()

    onVisibleChanged: {
        if (visible) {
            dbusTimerProps.updateAll();
        }
    }

    // Main Card Container with margins
    Item {
        anchors.fill: parent
        anchors.leftMargin: 44
        anchors.rightMargin: 44
        anchors.topMargin: 10
        anchors.bottomMargin: 38

        // -------------------------------------------------------------
        // LEFT COLUMN: Circular Progress Ring & Big Digits
        // -------------------------------------------------------------
        Item {
            id: leftCol
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 140

            // Circular Progress Canvas
            Canvas {
                id: canvasRing
                anchors.centerIn: parent
                width: 110
                height: 110

                onPaint: {
                    var ctx = getContext("2d");
                    if (ctx.reset) ctx.reset();
                    else ctx.clearRect(0, 0, width, height);

                    var cx = width / 2;
                    var cy = height / 2;
                    var radius = (width / 2) - 6;
                    var strokeW = 5;

                    // 1. Background Track Ring
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, 2 * Math.PI, false);
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.10);
                    ctx.lineWidth = strokeW;
                    ctx.stroke();

                    // 2. Active Progress Arc
                    var frac = root.progressFraction;
                    if (frac > 0) {
                        ctx.beginPath();
                        var startAngle = -Math.PI / 2;
                        var endAngle = startAngle + (frac * 2 * Math.PI);
                        ctx.arc(cx, cy, radius, startAngle, endAngle, false);

                        var ringCol = root.accentColor;
                        if (root.isPaused) ringCol = Qt.color("#f39c12");
                        else if (root.isFinished) ringCol = Qt.color("#e74c3c");

                        ctx.strokeStyle = ringCol;
                        ctx.lineWidth = strokeW;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }
            }

            // Big Numbers & Sub-label inside ring
            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    id: bigDigitsText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (root.isRunning || root.isPaused) {
                            return root.formatTime(root.remainingSeconds);
                        } else if (root.isFinished) {
                            return "00:00";
                        } else {
                            return root.formatTime(root.totalInputSeconds);
                        }
                    }
                    font.pixelSize: (text.length > 5) ? 17 : 21
                    font.bold: true
                    color: root.isFinished ? "#e74c3c" : "#ffffff"
                    font.family: root.clockFontFamily !== "" ? root.clockFontFamily : "Inter, Roboto, sans-serif"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (root.isFinished) return (typeof i18n !== "undefined" ? i18n("Waktu Habis!") : "Waktu Habis!");
                        if (root.isPaused) return (typeof i18n !== "undefined" ? i18n("Dijeda") : "Dijeda");
                        if (root.isRunning) return root.formatTargetTime(root.targetTimestamp);
                        return (typeof i18n !== "undefined" ? i18n("Siap") : "Siap");
                    }
                    font.pixelSize: 10
                    color: root.isFinished ? "#e74c3c" : Qt.rgba(1, 1, 1, 0.5)
                    font.bold: root.isFinished
                }
            }
        }

        // -------------------------------------------------------------
        // RIGHT COLUMN: Preset Chips, Manual Time Inputs, Action Buttons
        // -------------------------------------------------------------
        Item {
            id: rightCol
            anchors.left: leftCol.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Column {
                anchors.fill: parent
                spacing: 6

                // 1. Preset Chips (8 Chips: 1, 5, 10, 15, 25, 30, 45, 60m)
                Grid {
                    id: chipsGrid
                    width: parent.width
                    columns: 4
                    columnSpacing: 6
                    rowSpacing: 5

                    readonly property var presets: [1, 5, 10, 15, 25, 30, 45, 60]

                    Repeater {
                        model: chipsGrid.presets

                        Rectangle {
                            required property int modelData
                            required property int index

                            width: (chipsGrid.width - (3 * chipsGrid.columnSpacing)) / 4
                            height: 22
                            radius: 11
                            color: chipMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: (root.totalInputSeconds === (modelData * 60) && (root.isIdle || root.isFinished)) 
                                ? root.accentColor 
                                : Qt.rgba(1, 1, 1, 0.14)

                            Text {
                                anchors.centerIn: parent
                                text: modelData + "m"
                                font.pixelSize: 10
                                font.bold: true
                                color: (root.totalInputSeconds === (modelData * 60) && (root.isIdle || root.isFinished))
                                    ? root.accentColor
                                    : "#ffffff"
                            }

                            MouseArea {
                                id: chipMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyPreset(modelData)
                            }
                        }
                    }
                }

                // 2. Manual Time Inputs (HH : MM : SS)
                Item {
                    width: parent.width
                    height: 32

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        // Hours Input Box
                        Rectangle {
                            width: 52
                            height: 28
                            radius: 7
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.15)

                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Text {
                                    text: (root.inputHours < 10 ? "0" : "") + root.inputHours
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "j"
                                    font.pixelSize: 10
                                    color: Qt.rgba(1, 1, 1, 0.45)
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: 1
                                }
                            }

                            // Stepper MouseArea
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.inputHours = (root.inputHours + 1) % 24;
                                }
                                onWheel: (event) => {
                                    if (event.angleDelta.y > 0) root.inputHours = (root.inputHours + 1) % 24;
                                    else if (event.angleDelta.y < 0) root.inputHours = (root.inputHours - 1 + 24) % 24;
                                }
                            }
                        }

                        Text {
                            text: ":"
                            font.pixelSize: 14
                            font.bold: true
                            color: Qt.rgba(1, 1, 1, 0.4)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Minutes Input Box
                        Rectangle {
                            width: 52
                            height: 28
                            radius: 7
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.15)

                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Text {
                                    text: (root.inputMinutes < 10 ? "0" : "") + root.inputMinutes
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "m"
                                    font.pixelSize: 10
                                    color: Qt.rgba(1, 1, 1, 0.45)
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: 1
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.inputMinutes = (root.inputMinutes + 1) % 60;
                                }
                                onWheel: (event) => {
                                    if (event.angleDelta.y > 0) root.inputMinutes = (root.inputMinutes + 1) % 60;
                                    else if (event.angleDelta.y < 0) root.inputMinutes = (root.inputMinutes - 1 + 60) % 60;
                                }
                            }
                        }

                        Text {
                            text: ":"
                            font.pixelSize: 14
                            font.bold: true
                            color: Qt.rgba(1, 1, 1, 0.4)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Seconds Input Box
                        Rectangle {
                            width: 52
                            height: 28
                            radius: 7
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.15)

                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Text {
                                    text: (root.inputSeconds < 10 ? "0" : "") + root.inputSeconds
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "d"
                                    font.pixelSize: 10
                                    color: Qt.rgba(1, 1, 1, 0.45)
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: 1
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.inputSeconds = (root.inputSeconds + 10) % 60;
                                }
                                onWheel: (event) => {
                                    if (event.angleDelta.y > 0) root.inputSeconds = (root.inputSeconds + 5) % 60;
                                    else if (event.angleDelta.y < 0) root.inputSeconds = (root.inputSeconds - 5 + 60) % 60;
                                }
                            }
                        }
                    }
                }

                // 3. Action Buttons (Mulai / Jeda / Lanjut & Reset)
                Row {
                    width: parent.width
                    height: 32
                    spacing: 8

                    // Primary Button (Start / Pause / Resume)
                    Rectangle {
                        width: parent.width - 78
                        height: 32
                        radius: 16
                        color: {
                            if (primaryBtnMa.containsMouse) {
                                if (root.isRunning) return "#e67e22";
                                if (root.isPaused) return "#27ae60";
                                return Qt.darker(root.accentColor, 1.15);
                            }
                            if (root.isRunning) return "#f39c12"; // Amber/Orange
                            if (root.isPaused) return "#2ecc71"; // Emerald/Green
                            return root.accentColor;
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            SFSymbolIcon {
                                width: 12
                                height: 12
                                anchors.verticalCenter: parent.verticalCenter
                                name: root.isRunning ? "pause.fill" : "play.fill"
                                color: "#ffffff"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    if (root.isRunning) return (typeof i18n !== "undefined" ? i18n("Jeda") : "Jeda");
                                    if (root.isPaused) return (typeof i18n !== "undefined" ? i18n("Lanjutkan") : "Lanjutkan");
                                    return (typeof i18n !== "undefined" ? i18n("Mulai") : "Mulai");
                                }
                                font.pixelSize: 11
                                font.bold: true
                                color: "#ffffff"
                            }
                        }

                        MouseArea {
                            id: primaryBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.isRunning) root.requestPause();
                                else root.requestStart();
                            }
                        }
                    }

                    // Reset Button
                    Rectangle {
                        width: 70
                        height: 32
                        radius: 16
                        color: resetBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        opacity: (root.isIdle && root.totalInputSeconds === 0) ? 0.4 : 1.0

                        Text {
                            anchors.centerIn: parent
                            text: (typeof i18n !== "undefined" ? i18n("Reset") : "Reset")
                            font.pixelSize: 11
                            font.bold: true
                            color: "#ffffff"
                        }

                        MouseArea {
                            id: resetBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.requestReset()
                        }
                    }
                }
            }
        }
    }
}
