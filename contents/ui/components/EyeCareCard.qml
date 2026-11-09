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

    // State dari D-Bus Service
    property string eyeState: "idle" // "idle", "running", "break"
    property int intervalMinutes: 20
    property int remainingSeconds: 1200
    property int breakDuration: 20
    property int timeSinceLastBreak: 0
    property bool isOverdue: false
    property bool isPaused: false

    // Manual Input State
    property int manualMinutes: 20

    readonly property bool isRunning: eyeState === "running"
    readonly property bool isBreak: eyeState === "break"
    readonly property bool isIdle: eyeState === "idle"

    // Progress fraction
    readonly property real progressFraction: {
        if (isBreak) {
            return breakDuration > 0 ? Math.max(0.0, Math.min(1.0, remainingSeconds / breakDuration)) : 0.0;
        }
        var totalSec = intervalMinutes * 60;
        return totalSec > 0 ? Math.max(0.0, Math.min(1.0, remainingSeconds / totalSec)) : 0.0;
    }

    function formatTime(totalSec) {
        if (totalSec < 0) totalSec = 0;
        var m = Math.floor(totalSec / 60);
        var s = totalSec % 60;
        var ss = (s < 10 ? "0" : "") + s;
        return m + ":" + ss;
    }

    function formatMinutesDuration(totalSec) {
        if (totalSec < 0) totalSec = 0;
        var m = Math.floor(totalSec / 60);
        if (m < 1) return "< 1 mnt";
        return m + " mnt";
    }

    // --- D-Bus Integration ---
    DBusCall {
        id: dbusEyeCall
        busType: DBus.BusType.Session
        service: "org.kde.plasma.dynamicisland.eyecare"
        path: "/EyeCare"
        iface: "org.kde.plasma.dynamicisland.eyecare"
    }

    DBus.Properties {
        id: dbusEyeProps
        busType: DBus.BusType.Session
        service: "org.kde.plasma.dynamicisland.eyecare"
        path: "/EyeCare"
        iface: "org.kde.plasma.dynamicisland.eyecare"

        onPropertiesChanged: (ifaceName, changedProps, invalidated) => {
            if (changedProps["state"] !== undefined) root.eyeState = changedProps["state"];
            if (changedProps["intervalMinutes"] !== undefined) {
                root.intervalMinutes = changedProps["intervalMinutes"];
                root.manualMinutes = changedProps["intervalMinutes"];
            }
            if (changedProps["remainingSeconds"] !== undefined) root.remainingSeconds = changedProps["remainingSeconds"];
            if (changedProps["breakDuration"] !== undefined) root.breakDuration = changedProps["breakDuration"];
            if (changedProps["timeSinceLastBreak"] !== undefined) root.timeSinceLastBreak = changedProps["timeSinceLastBreak"];
            if (changedProps["isOverdue"] !== undefined) root.isOverdue = changedProps["isOverdue"];
            if (changedProps["isPaused"] !== undefined) root.isPaused = changedProps["isPaused"];
        }

        Component.onCompleted: updateAll()
    }

    DBus.SignalWatcher {
        id: dbusEyeWatcher
        busType: DBus.BusType.Session
        service: "org.kde.plasma.dynamicisland.eyecare"
        path: "/EyeCare"
        iface: "org.kde.plasma.dynamicisland.eyecare"

        function dbusEyeUpdated(state, remaining_seconds, time_since_last_break, is_overdue, is_paused) {
            root.eyeState = state;
            root.remainingSeconds = remaining_seconds;
            root.timeSinceLastBreak = time_since_last_break;
            root.isOverdue = is_overdue;
            root.isPaused = is_paused;
        }

        function dbusBreakStarted(break_duration) {
            root.eyeState = "break";
            root.breakDuration = break_duration;
            root.remainingSeconds = break_duration;
        }

        function dbusBreakFinished() {
            root.eyeState = "running";
            root.remainingSeconds = root.intervalMinutes * 60;
            root.timeSinceLastBreak = 0;
            root.isOverdue = false;
        }
    }

    // Aksi Pengontrol
    function requestStart() {
        var m = manualMinutes > 0 ? manualMinutes : 20;
        dbusEyeCall.call("Start", [m]);
    }

    function requestStop() {
        dbusEyeCall.call("Stop", []);
    }

    function requestSnooze() {
        dbusEyeCall.call("Snooze", [5]);
    }

    function requestSkip() {
        dbusEyeCall.call("SkipBreak", []);
    }

    function applyInterval(minutes) {
        manualMinutes = minutes;
        dbusEyeCall.call("SetInterval", [minutes]);
        if (isIdle) {
            requestStart();
        }
    }

    onProgressFractionChanged: canvasEyeRing.requestPaint()
    onEyeStateChanged: canvasEyeRing.requestPaint()
    onIsOverdueChanged: canvasEyeRing.requestPaint()
    onAccentColorChanged: canvasEyeRing.requestPaint()

    onVisibleChanged: {
        if (visible) {
            dbusEyeProps.updateAll();
        }
    }

    // Main Card Container with safe clearances
    Item {
        anchors.fill: parent
        anchors.leftMargin: 44
        anchors.rightMargin: 44
        anchors.topMargin: 10
        anchors.bottomMargin: 38

        // =============================================================
        // VIEW A: NORMAL SESSION VIEW (Idle / Running)
        // =============================================================
        Item {
            anchors.fill: parent
            visible: !root.isBreak

            // LEFT COLUMN: Circular Progress Ring & Numbers
            Item {
                id: normalLeftCol
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 140

                Canvas {
                    id: canvasEyeRing
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

                        // Track Ring
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, 0, 2 * Math.PI, false);
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.10);
                        ctx.lineWidth = strokeW;
                        ctx.stroke();

                        // Progress Arc
                        var frac = root.progressFraction;
                        if (frac > 0) {
                            ctx.beginPath();
                            var startAngle = -Math.PI / 2;
                            var endAngle = startAngle + (frac * 2 * Math.PI);
                            ctx.arc(cx, cy, radius, startAngle, endAngle, false);

                            var col = root.accentColor;
                            if (root.isOverdue) col = Qt.color("#e74c3c"); // Warning red jika kelebihan waktu layar
                            else if (root.isPaused) col = Qt.color("#f39c12"); // Amber jika dijeda lock/sleep

                            ctx.strokeStyle = col;
                            ctx.lineWidth = strokeW;
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                    }
                }

                // Center Text inside Ring
                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.isRunning ? root.formatTime(root.remainingSeconds) : (root.manualMinutes + ":00")
                        font.pixelSize: 20
                        font.bold: true
                        color: root.isOverdue ? "#e74c3c" : "#ffffff"
                        font.family: root.clockFontFamily !== "" ? root.clockFontFamily : "Inter, Roboto, sans-serif"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (root.isPaused) return (typeof i18n !== "undefined" ? i18n("Layar Dijeda") : "Layar Dijeda");
                            if (root.isOverdue) return (typeof i18n !== "undefined" ? i18n("Kelebihan!") : "Kelebihan!");
                            if (root.isRunning) return (typeof i18n !== "undefined" ? i18n("Menuju Rehat") : "Menuju Rehat");
                            return (typeof i18n !== "undefined" ? i18n("Siap") : "Siap");
                        }
                        font.pixelSize: 10
                        font.bold: root.isOverdue
                        color: root.isOverdue ? "#e74c3c" : Qt.rgba(1, 1, 1, 0.55)
                    }
                }

                // Bottom Active Time Info
                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        var durStr = root.formatMinutesDuration(root.timeSinceLastBreak);
                        return (typeof i18n !== "undefined" ? i18n("Aktif:") : "Aktif:") + " " + durStr;
                    }
                    font.pixelSize: 10
                    font.bold: root.isOverdue
                    color: root.isOverdue ? "#e74c3c" : Qt.rgba(1, 1, 1, 0.45)
                }
            }

            // RIGHT COLUMN: Preset Interval Chips, Manual Stepper, Actions
            Item {
                id: normalRightCol
                anchors.left: normalLeftCol.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Column {
                    anchors.fill: parent
                    spacing: 7

                    // 1. Header & Overdue Alert Bar
                    RowLayout {
                        width: parent.width
                        height: 20

                        Row {
                            spacing: 5
                            Layout.alignment: Qt.AlignVCenter

                            SFSymbolIcon {
                                width: 14
                                height: 14
                                name: "eye"
                                color: root.isOverdue ? "#e74c3c" : root.accentColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: (typeof i18n !== "undefined" ? i18n("Pengingat Mata (20-20-20)") : "Pengingat Mata (20-20-20)")
                                font.pixelSize: 11
                                font.bold: true
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Overdue Badge
                        Rectangle {
                            visible: root.isOverdue
                            Layout.preferredHeight: 18
                            Layout.preferredWidth: overdueBadgeText.implicitWidth + 10
                            radius: 9
                            color: Qt.rgba(0.9, 0.2, 0.2, 0.25)
                            border.width: 1
                            border.color: "#e74c3c"

                            Text {
                                id: overdueBadgeText
                                anchors.centerIn: parent
                                text: (typeof i18n !== "undefined" ? i18n("⚠️ Butuh Rehat") : "⚠️ Butuh Rehat")
                                font.pixelSize: 9
                                font.bold: true
                                color: "#e74c3c"
                            }
                        }
                    }

                    // 2. Preset Interval Chips (20m, 30m, 45m, 60m)
                    Row {
                        width: parent.width
                        spacing: 6

                        readonly property var presets: [20, 30, 45, 60]

                        Repeater {
                            model: parent.presets

                            Rectangle {
                                required property int modelData
                                required property int index

                                width: (normalRightCol.width - (3 * 6)) / 4
                                height: 24
                                radius: 12
                                color: chipMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                border.color: (root.manualMinutes === modelData) ? root.accentColor : Qt.rgba(1, 1, 1, 0.14)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + "m"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: (root.manualMinutes === modelData) ? root.accentColor : "#ffffff"
                                }

                                MouseArea {
                                    id: chipMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.applyInterval(modelData)
                                }
                            }
                        }
                    }

                    // 3. Manual Stepper & Rule Explanation
                    RowLayout {
                        width: parent.width
                        height: 28
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 90
                            Layout.preferredHeight: 26
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.15)

                            Row {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: root.manualMinutes + ""
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: (typeof i18n !== "undefined" ? i18n("menit") : "menit")
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
                                    root.manualMinutes = (root.manualMinutes >= 60) ? 15 : root.manualMinutes + 5;
                                    root.applyInterval(root.manualMinutes);
                                }
                                onWheel: (event) => {
                                    if (event.angleDelta.y > 0) root.manualMinutes = Math.min(120, root.manualMinutes + 5);
                                    else if (event.angleDelta.y < 0) root.manualMinutes = Math.max(5, root.manualMinutes - 5);
                                    root.applyInterval(root.manualMinutes);
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: (typeof i18n !== "undefined" ? i18n("Jeda otomatis saat layar terkunci / laptop sleep.") : "Jeda otomatis saat layar terkunci / laptop sleep.")
                            font.pixelSize: 9
                            color: Qt.rgba(1, 1, 1, 0.40)
                            wrapMode: Text.WordWrap
                        }
                    }

                    // 4. Action Buttons
                    Row {
                        width: parent.width
                        height: 32
                        spacing: 8

                        // Start / Stop Button
                        Rectangle {
                            width: root.isRunning ? (parent.width - 120) : parent.width
                            height: 32
                            radius: 16
                            color: {
                                if (startBtnMa.containsMouse) {
                                    return root.isRunning ? "#c0392b" : Qt.darker(root.accentColor, 1.15);
                                }
                                return root.isRunning ? "#e74c3c" : root.accentColor;
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                SFSymbolIcon {
                                    width: 12
                                    height: 12
                                    name: root.isRunning ? "xmark" : "play.fill"
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.isRunning ? (typeof i18n !== "undefined" ? i18n("Hentikan") : "Hentikan") : (typeof i18n !== "undefined" ? i18n("Mulai Pengingat") : "Mulai Pengingat")
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#ffffff"
                                }
                            }

                            MouseArea {
                                id: startBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.isRunning) root.requestStop();
                                    else root.requestStart();
                                }
                            }
                        }

                        // "Istirahat Sekarang" Button (only visible when running)
                        Rectangle {
                            visible: root.isRunning
                            width: 112
                            height: 32
                            radius: 16
                            color: restNowMa.containsMouse ? Qt.rgba(0.18, 0.8, 0.44, 0.3) : Qt.rgba(0.18, 0.8, 0.44, 0.15)
                            border.width: 1
                            border.color: "#2ecc71"

                            Row {
                                anchors.centerIn: parent
                                spacing: 5

                                SFSymbolIcon {
                                    width: 11
                                    height: 11
                                    name: "eye"
                                    color: "#2ecc71"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (typeof i18n !== "undefined" ? i18n("Rehat 20s") : "Rehat 20s")
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#2ecc71"
                                }
                            }

                            MouseArea {
                                id: restNowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dbusEyeCall.call("TriggerBreak", []);
                                }
                            }
                        }
                    }
                }
            }
        }

        // =============================================================
        // VIEW B: ACTIVE EYE BREAK VIEW (20 Seconds Eye Rest Mode)
        // =============================================================
        Item {
            anchors.fill: parent
            visible: root.isBreak

            // LEFT: 20-Second Emerald Ring
            Item {
                id: breakLeftCol
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 140

                Canvas {
                    id: canvasBreakRing
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

                        // Track
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, 0, 2 * Math.PI, false);
                        ctx.strokeStyle = Qt.rgba(0.18, 0.8, 0.44, 0.15);
                        ctx.lineWidth = strokeW;
                        ctx.stroke();

                        // Arc
                        var frac = root.progressFraction;
                        if (frac > 0) {
                            ctx.beginPath();
                            var startAngle = -Math.PI / 2;
                            var endAngle = startAngle + (frac * 2 * Math.PI);
                            ctx.arc(cx, cy, radius, startAngle, endAngle, false);
                            ctx.strokeStyle = Qt.color("#2ecc71");
                            ctx.lineWidth = strokeW;
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.remainingSeconds + "s"
                        font.pixelSize: 22
                        font.bold: true
                        color: "#2ecc71"
                        font.family: root.clockFontFamily !== "" ? root.clockFontFamily : "Inter, Roboto, sans-serif"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (typeof i18n !== "undefined" ? i18n("Lihat Jauh 6m") : "Lihat Jauh 6m")
                        font.pixelSize: 9
                        font.bold: true
                        color: Qt.rgba(1, 1, 1, 0.6)
                    }
                }
            }

            // RIGHT: Eye Rest Guidance & Snooze/Skip Controls
            Item {
                anchors.left: breakLeftCol.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Column {
                    anchors.fill: parent
                    spacing: 8

                    // Header
                    Row {
                        spacing: 6
                        SFSymbolIcon {
                            width: 16
                            height: 16
                            name: "eye"
                            color: "#2ecc71"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: (typeof i18n !== "undefined" ? i18n("Istirahatkan Matamu Sekarang!") : "Istirahatkan Matamu Sekarang!")
                            font.pixelSize: 12
                            font.bold: true
                            color: "#2ecc71"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Guidance Text
                    Text {
                        width: parent.width
                        text: (typeof i18n !== "undefined" ? i18n("Alihkan pandangan dari layar monitor. Tataplah objek berjarak minimal 6 meter (20 kaki) selama 20 detik untuk merilekskan otot fokus mata Anda.") : "Alihkan pandangan dari layar monitor. Tataplah objek berjarak minimal 6 meter (20 kaki) selama 20 detik untuk merilekskan otot fokus mata Anda.")
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.80)
                        wrapMode: Text.WordWrap
                        lineHeight: 1.25
                    }

                    Item { height: 4; width: 1 }

                    // Action Buttons (Tunda 5 Menit & Lewati)
                    Row {
                        width: parent.width
                        height: 32
                        spacing: 10

                        // Snooze 5 Minutes Button
                        Rectangle {
                            width: (parent.width - 10) / 2
                            height: 32
                            radius: 16
                            color: snoozeBtnMa.containsMouse ? "#e67e22" : "#f39c12"

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: (typeof i18n !== "undefined" ? i18n("Tunda (5 mnt)") : "Tunda (5 mnt)")
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#ffffff"
                                }
                            }

                            MouseArea {
                                id: snoozeBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.requestSnooze()
                            }
                        }

                        // Skip Button
                        Rectangle {
                            width: (parent.width - 10) / 2
                            height: 32
                            radius: 16
                            color: skipBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.16)

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: (typeof i18n !== "undefined" ? i18n("Lewati") : "Lewati")
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#ffffff"
                                }
                            }

                            MouseArea {
                                id: skipBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.requestSkip()
                            }
                        }
                    }
                }
            }
        }
    }
}
