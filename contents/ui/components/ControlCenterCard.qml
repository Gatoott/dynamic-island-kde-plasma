import QtQuick
import QtQuick.Controls
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.bluezqt as BluezQt
import org.kde.plasma.private.volume as PlasmaAudio
import org.kde.plasma.private.sessions as Sessions
import org.kde.notificationmanager as NM
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.workspace.dbus as DBus

Item {
    id: controlCenterRoot

    property color accentColor: "#3daee9"
    property string currentTimeString: ""
    property string currentDateString: ""
    property string islandMode: "notch" // "notch" or "dock"

    // Metrics passed from root / sensors
    property int cpuPercent: 12
    property int cpuTemp: 40
    property int ramPercent: 42
    property int batteryPercent: 95
    property bool batteryCharging: false
    property int batteryTemp: 30

    // Signals
    signal requestSwitchToMedia()
    signal requestToggleMode()
    signal requestOpenSettings()
    signal requestOpenLauncher()

    // -------------------------------------------------------------
    // Session Management for Shutdown
    // -------------------------------------------------------------
    Sessions.SessionManagement {
        id: sessionManager
    }

    // -------------------------------------------------------------
    // Volume Control (Pure Plasma 6 Native PulseAudio / PipeWire)
    // -------------------------------------------------------------
    PlasmaAudio.SinkModel {
        id: sinkModel
        readonly property var preferredSink: controlCenterRoot.defaultSink
        onDataChanged: controlCenterRoot.updateDefaultSink()
        onRowsInserted: controlCenterRoot.updateDefaultSink()
        onRowsRemoved: controlCenterRoot.updateDefaultSink()
        onModelReset: controlCenterRoot.updateDefaultSink()
        onCountChanged: controlCenterRoot.updateDefaultSink()
        Component.onCompleted: controlCenterRoot.updateDefaultSink()
    }

    property var defaultSink: null

    function updateDefaultSink() {
        if (!sinkModel || sinkModel.count === 0) return;
        var defaultRole = sinkModel.role("Default");
        var pulseObjectRole = sinkModel.role("PulseObject");
        for (var i = 0; i < sinkModel.count; ++i) {
            var idx = sinkModel.index(i, 0);
            var isDef = (defaultRole !== -1) ? sinkModel.data(idx, defaultRole) : false;
            if (isDef === true || isDef === 1 || isDef === "true") {
                defaultSink = (pulseObjectRole !== -1) ? sinkModel.data(idx, pulseObjectRole) : null;
                return;
            }
        }
        if (sinkModel.count > 0 && !defaultSink && pulseObjectRole !== -1) {
            defaultSink = sinkModel.data(sinkModel.index(0, 0), pulseObjectRole);
        }
    }

    readonly property real normalVolume: (defaultSink && defaultSink.baseVolume > 0) ? defaultSink.baseVolume : 65536
    readonly property real currentVolumePercent: defaultSink 
        ? Math.round((defaultSink.volume / normalVolume) * 100) 
        : 0
    readonly property int currentVolumePct: currentVolumePercent
    readonly property bool isMuted: defaultSink ? defaultSink.muted : false

    function setVolumePercent(val) {
        if (!defaultSink) return;
        const clamped = Math.max(0, Math.min(100, Math.round(val)));
        defaultSink.volume = Math.round((clamped / 100) * normalVolume);
        if (defaultSink.muted && clamped > 0) {
            defaultSink.muted = false;
        }
    }

    function toggleMute() {
        if (!defaultSink) return;
        defaultSink.muted = !defaultSink.muted;
    }

    function adjustVolumeWheel(wheel) {
        if (!defaultSink) return;
        var step = normalVolume * 0.05;
        if (wheel.angleDelta.y > 0) {
            defaultSink.volume = Math.min(defaultSink.volume + step, normalVolume);
            if (defaultSink.muted) defaultSink.muted = false;
        } else {
            defaultSink.volume = Math.max(defaultSink.volume - step, 0);
        }
    }

    // -------------------------------------------------------------
    // Brightness Control (DBus to Solid.PowerManagement)
    // -------------------------------------------------------------
    property int currentBrightnessVal: 3000
    property int maxBrightnessVal: 10000
    readonly property int currentBrightnessPct: maxBrightnessVal > 0 ? Math.round((currentBrightnessVal / maxBrightnessVal) * 100) : 60

    DBus.Properties {
        id: brightnessProps
        busType: DBus.BusType.Session
        service: "org.kde.Solid.PowerManagement"
        path: "/org/kde/Solid/PowerManagement/Actions/BrightnessControl"
        iface: "org.kde.Solid.PowerManagement.Actions.BrightnessControl"

        onPropertiesChanged: {
            if (typeof properties !== "undefined" && properties !== null) {
                if (properties.brightness !== undefined) {
                    controlCenterRoot.currentBrightnessVal = properties.brightness;
                }
                if (properties.brightnessMax !== undefined) {
                    controlCenterRoot.maxBrightnessVal = properties.brightnessMax;
                }
            }
        }
    }

    DBusCall {
        id: dbusBrightness
        service: "org.kde.Solid.PowerManagement"
        path: "/org/kde/Solid/PowerManagement/Actions/BrightnessControl"
        iface: "org.kde.Solid.PowerManagement.Actions.BrightnessControl"
        member: "setBrightness"
    }

    function setBrightnessPercent(val) {
        const clamped = Math.max(1, Math.min(100, Math.round(val)));
        const targetVal = Math.round(clamped * maxBrightnessVal / 100);
        controlCenterRoot.currentBrightnessVal = targetVal;
        dbusBrightness.call("setBrightness", [targetVal]);
    }

    // -------------------------------------------------------------
    // Powerdevil Power Profile Cycle
    // -------------------------------------------------------------
    property string currentPowerProfile: "power-saver"

    DBus.Properties {
        id: powerProfileProps
        busType: DBus.BusType.Session
        service: "org.kde.Solid.PowerManagement"
        path: "/org/kde/Solid/PowerManagement/Actions/PowerProfile"
        iface: "org.kde.Solid.PowerManagement.Actions.PowerProfile"

        onPropertiesChanged: {
            if (typeof properties !== "undefined" && properties !== null && properties.currentProfile !== undefined) {
                controlCenterRoot.currentPowerProfile = properties.currentProfile;
            }
        }
    }

    DBusCall {
        id: dbusPowerProfile
        service: "org.kde.Solid.PowerManagement"
        path: "/org/kde/Solid/PowerManagement/Actions/PowerProfile"
        iface: "org.kde.Solid.PowerManagement.Actions.PowerProfile"
        member: "setProfile"
    }

    readonly property string powerProfileDisplayName: {
        switch (currentPowerProfile) {
            case "performance": return i18n("Performance");
            case "balanced": return i18n("Balanced");
            case "power-saver":
            default: return i18n("Power Save");
        }
    }

    function cyclePowerProfile() {
        var next = "balanced";
        if (currentPowerProfile === "power-saver") next = "balanced";
        else if (currentPowerProfile === "balanced") next = "performance";
        else if (currentPowerProfile === "performance") next = "power-saver";

        controlCenterRoot.currentPowerProfile = next;
        dbusPowerProfile.call("setProfile", [next]);
    }

    // -------------------------------------------------------------
    // Wi-Fi Status & Toggle (NetworkManager DBus)
    // -------------------------------------------------------------
    property bool wifiEnabled: true
    property string wifiSsid: "Wi-Fi"

    DBusCall {
        id: dbusWifiToggle
        busType: DBus.BusType.System
        service: "org.freedesktop.NetworkManager"
        path: "/org/freedesktop/NetworkManager"
        iface: "org.freedesktop.DBus.Properties"
        member: "Set"
    }

    function toggleWifi() {
        const nextState = !controlCenterRoot.wifiEnabled;
        controlCenterRoot.wifiEnabled = nextState;
        dbusWifiToggle.call("Set", ["org.freedesktop.NetworkManager", "WirelessEnabled", nextState]);
    }

    // -------------------------------------------------------------
    // Bluetooth Status & Toggle (BluezQt Native)
    // -------------------------------------------------------------
    readonly property bool btPowered: (typeof BluezQt !== "undefined" && BluezQt.Manager) ? BluezQt.Manager.bluetoothOperational : false
    readonly property string btConnectedDevice: {
        if (typeof BluezQt === "undefined" || !BluezQt.Manager) return i18n("Off");
        const devs = BluezQt.Manager.connectedDevices;
        if (devs && devs.length > 0) {
            return devs[0].name || i18n("Terhubung");
        }
        return btPowered ? i18n("On (Idle)") : i18n("Off");
    }

    function toggleBluetooth() {
        if (typeof BluezQt !== "undefined" && BluezQt.Manager) {
            BluezQt.Manager.bluetoothBlocked = !BluezQt.Manager.bluetoothBlocked;
        }
    }

    // -------------------------------------------------------------
    // Do Not Disturb (NM.Server.inhibited)
    // -------------------------------------------------------------
    readonly property bool dndActive: (typeof NM !== "undefined" && NM.Server) ? NM.Server.inhibited : false

    function toggleDND() {
        if (typeof NM !== "undefined" && NM.Server) {
            NM.Server.inhibited = !NM.Server.inhibited;
        }
    }

    // -------------------------------------------------------------
    // Dark Mode Toggle
    // -------------------------------------------------------------
    property bool isDarkMode: true

    function toggleDarkMode() {
        controlCenterRoot.isDarkMode = !controlCenterRoot.isDarkMode;
    }

    DBusCall {
        id: dbusLauncher
        service: "org.kde.plasmashell"
        path: "/PlasmaShell"
        iface: "org.kde.PlasmaShell"
        member: "activateLauncherMenu"
    }

    // -------------------------------------------------------------
    // Periodic Async Data Refresh
    // -------------------------------------------------------------
    Timer {
        interval: 3000
        running: controlCenterRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            dbusPowerProfile.call("currentProfile", [], (reply) => {
                if (typeof reply !== "undefined" && reply !== null && reply.value !== undefined) {
                    controlCenterRoot.currentPowerProfile = reply.value.toString().trim();
                }
            });
            dbusBrightness.call("brightness", [], (reply) => {
                if (typeof reply !== "undefined" && reply !== null && reply.value !== undefined) {
                    controlCenterRoot.currentBrightnessVal = parseInt(reply.value) || controlCenterRoot.currentBrightnessVal;
                }
            });
            dbusBrightness.call("brightnessMax", [], (reply) => {
                if (typeof reply !== "undefined" && reply !== null && reply.value !== undefined) {
                    controlCenterRoot.maxBrightnessVal = parseInt(reply.value) || controlCenterRoot.maxBrightnessVal;
                }
            });
        }
    }

    // =============================================================
    // UI LAYOUT (Scrollable Pure Flickable - No ScrollBar Leak)
    // =============================================================
    Flickable {
        id: controlCenterFlickable
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 38
        anchors.leftMargin: 40 // Ruang aman dari tombol panah navigasi kiri
        anchors.rightMargin: 40 // Ruang aman dari tombol panah navigasi kanan
        clip: true

        contentWidth: width
        contentHeight: contentCol.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: true

        onContentYChanged: {
            var maxY = Math.max(0, contentHeight - height);
            if (contentY < 0) {
                contentY = 0;
            } else if (contentY > maxY) {
                contentY = maxY;
            }
        }

        // TANGKAP PUTARAN MOUSE WHEEL & TRACKPAD GESTURE SECARA EKSPLISIT:
        WheelHandler {
            target: controlCenterFlickable
            property: "contentY"
            rotationScale: -2.5 // Sensitivitas scroll (~37.5px per notch)
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }

        ColumnLayout {
            id: contentCol
            width: controlCenterFlickable.width
            spacing: 12

            // ---------------------------------------------------------
            // 1. Header Bar Status Monitor (Titik Tengah Absolut Terkunci)
            // ---------------------------------------------------------
            Item {
                id: headerStatusBar
                Layout.fillWidth: true
                Layout.preferredHeight: 32

                // 1. SISI KIRI (CPU / RAM / Temp)
                RowLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    RowLayout {
                        spacing: 4
                        Kirigami.Icon {
                            source: "cpu"
                            implicitWidth: 12
                            implicitHeight: 12
                            color: "#9aa0a6"
                        }
                        Text {
                            text: controlCenterRoot.cpuPercent + "%"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#ffffff"
                        }
                        Text {
                            text: controlCenterRoot.cpuTemp + "°C"
                            font.pixelSize: 11
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#9aa0a6"
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 12
                        color: Qt.rgba(1, 1, 1, 0.15)
                    }

                    RowLayout {
                        spacing: 4
                        Kirigami.Icon {
                            source: "media-flash"
                            implicitWidth: 12
                            implicitHeight: 12
                            color: "#9aa0a6"
                        }
                        Text {
                            text: controlCenterRoot.ramPercent + "%"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#ffffff"
                        }
                    }
                }

                // 2. TITIK TENGAH ABSOLUT (Jam & Tanggal Presisi di Sumbu Tengah)
                ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: controlCenterRoot.currentTimeString !== "" ? controlCenterRoot.currentTimeString : "00:00"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: controlCenterRoot.currentDateString !== "" ? controlCenterRoot.currentDateString : ""
                        font.pixelSize: 10
                        font.family: "Inter, Roboto, sans-serif"
                        color: Qt.rgba(1, 1, 1, 0.65)
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        visible: text !== ""
                    }
                }

                // 3. SISI KANAN (Baterai & Suhu Baterai)
                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    RowLayout {
                        spacing: 4
                        Kirigami.Icon {
                            source: controlCenterRoot.batteryCharging ? "battery-charging" : "battery-080"
                            implicitWidth: 13
                            implicitHeight: 13
                            color: controlCenterRoot.batteryCharging ? "#34c759" : "#ffffff"
                        }
                        Text {
                            text: controlCenterRoot.batteryPercent + "%"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#ffffff"
                        }
                    }

                    RowLayout {
                        spacing: 3
                        Kirigami.Icon {
                            source: "sensor-temperature"
                            implicitWidth: 12
                            implicitHeight: 12
                            color: "#9aa0a6"
                        }
                        Text {
                            text: (controlCenterRoot.batteryTemp > 0 ? controlCenterRoot.batteryTemp : 30) + "°C"
                            font.pixelSize: 11
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#9aa0a6"
                        }
                    }
                }
            }

        // ---------------------------------------------------------
        // 2. Quick Toggle Cards (2-Column Grid)
        // ---------------------------------------------------------
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            // Card 1: Wi-Fi (Top-Left)
            Rectangle {
                id: wifiCard
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 14
                color: controlCenterRoot.wifiEnabled ? "#f2f4f7" : Qt.rgba(28/255, 30/255, 34/255, 0.95)
                border.width: 1
                border.color: controlCenterRoot.wifiEnabled ? "transparent" : Qt.rgba(1, 1, 1, 0.1)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: controlCenterRoot.wifiEnabled ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.1)

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: "network-wireless"
                            color: controlCenterRoot.wifiEnabled ? "#111418" : "#ffffff"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: i18n("Wi-Fi")
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.family: "Inter, Roboto, sans-serif"
                            color: controlCenterRoot.wifiEnabled ? "#111418" : "#ffffff"
                        }

                        Text {
                            text: controlCenterRoot.wifiEnabled ? (controlCenterRoot.wifiSsid !== "" ? controlCenterRoot.wifiSsid : i18n("Connected")) : i18n("Off")
                            font.pixelSize: 11
                            font.family: "Inter, Roboto, sans-serif"
                            color: controlCenterRoot.wifiEnabled ? "#555b63" : "#8e95a0"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "›"
                        font.pixelSize: 16
                        font.bold: true
                        color: controlCenterRoot.wifiEnabled ? "#777e88" : "#8e95a0"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: controlCenterRoot.toggleWifi()
                }
            }

            // Card 2: Dock Mode (Top-Right)
            Rectangle {
                id: dockModeCard
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 14
                color: Qt.rgba(28/255, 30/255, 34/255, 0.95)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Text {
                            anchors.centerIn: parent
                            text: controlCenterRoot.islandMode === "notch" ? "◓" : "▭"
                            font.pixelSize: 13
                            color: "#ffffff"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: i18n("Dock Mode")
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#ffffff"
                        }

                        Text {
                            text: controlCenterRoot.islandMode === "notch" ? i18n("Smart (Notch)") : i18n("Floating Dock")
                            font.pixelSize: 11
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#8e95a0"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 16
                        radius: 8
                        color: controlCenterRoot.islandMode === "notch" ? controlCenterRoot.accentColor : Qt.rgba(1, 1, 1, 0.2)

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            x: controlCenterRoot.islandMode === "notch" ? parent.width - width - 2 : 2
                            color: "#ffffff"

                            Behavior on x {
                                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: controlCenterRoot.requestToggleMode()
                }
            }

            // Card 3: Bluetooth (Bottom-Left)
            Rectangle {
                id: btCard
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 14
                color: controlCenterRoot.btPowered ? Qt.rgba(36/255, 40/255, 48/255, 0.95) : Qt.rgba(28/255, 30/255, 34/255, 0.95)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: controlCenterRoot.btPowered ? Qt.rgba(61/255, 174/255, 233/255, 0.25) : Qt.rgba(1, 1, 1, 0.1)

                        Text {
                            anchors.centerIn: parent
                            text: "ᛒ"
                            font.pixelSize: 14
                            font.bold: true
                            color: controlCenterRoot.btPowered ? controlCenterRoot.accentColor : "#ffffff"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: i18n("Bluetooth")
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#ffffff"
                        }

                        Text {
                            text: controlCenterRoot.btConnectedDevice
                            font.pixelSize: 11
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#8e95a0"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "›"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#8e95a0"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: controlCenterRoot.toggleBluetooth()
                }
            }

            // Card 4: Battery Power Profile (Bottom-Right)
            Rectangle {
                id: powerProfileCard
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 14
                color: Qt.rgba(28/255, 30/255, 34/255, 0.95)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: {
                            if (controlCenterRoot.currentPowerProfile === "performance") return Qt.rgba(255/255, 149/255, 0/255, 0.25);
                            if (controlCenterRoot.currentPowerProfile === "balanced") return Qt.rgba(61/255, 174/255, 233/255, 0.25);
                            return Qt.rgba(52/255, 199/255, 89/255, 0.25);
                        }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: {
                                if (controlCenterRoot.currentPowerProfile === "performance") return "speedometer";
                                if (controlCenterRoot.currentPowerProfile === "balanced") return "battery-profile-balanced";
                                return "battery-profile-powersave";
                            }
                            color: {
                                if (controlCenterRoot.currentPowerProfile === "performance") return "#ff9f0a";
                                if (controlCenterRoot.currentPowerProfile === "balanced") return controlCenterRoot.accentColor;
                                return "#34c759";
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: i18n("Power Mode")
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#ffffff"
                        }

                        Text {
                            text: controlCenterRoot.powerProfileDisplayName
                            font.pixelSize: 11
                            font.family: "Inter, Roboto, sans-serif"
                            color: {
                                if (controlCenterRoot.currentPowerProfile === "performance") return "#ff9f0a";
                                if (controlCenterRoot.currentPowerProfile === "balanced") return controlCenterRoot.accentColor;
                                return "#34c759";
                            }
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Kirigami.Icon {
                        implicitWidth: 14
                        implicitHeight: 14
                        source: "view-refresh"
                        color: "#8e95a0"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: controlCenterRoot.cyclePowerProfile()
                }
            }
        }

        // ---------------------------------------------------------
        // 3. Quick Action Icons Row (Centered Circular Buttons)
        // ---------------------------------------------------------
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 38
            spacing: 12

            // 1. Do Not Disturb / Notifications Toggle
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: controlCenterRoot.dndActive 
                    ? Qt.rgba(255/255, 59/255, 48/255, 0.4) 
                    : (dndMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.10))
                border.width: 1
                border.color: controlCenterRoot.dndActive ? "#ff453a" : Qt.rgba(1, 1, 1, 0.08)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: controlCenterRoot.dndActive ? "notifications-disabled" : "notifications"
                    color: controlCenterRoot.dndActive ? "#ff453a" : "#ffffff"
                }

                MouseArea {
                    id: dndMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenterRoot.toggleDND()
                }
            }

            // 2. Dynamic Island Settings (Gear Icon)
            Rectangle {
                id: settingsButton
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: settingsMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.10)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "configure"
                    color: "#ffffff"
                }

                MouseArea {
                    id: settingsMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // 1. Cari objek plasmoid yang valid (dari root atau parent tree)
                        var targetPlasmoid = (typeof plasmoid !== "undefined" && plasmoid) 
                            ? plasmoid 
                            : ((typeof Plasmoid !== "undefined" && Plasmoid) 
                                ? Plasmoid 
                                : ((typeof root !== "undefined" && root.plasmoid) ? root.plasmoid : null));

                        if (targetPlasmoid) {
                            var configAction = (typeof targetPlasmoid.action === "function") ? targetPlasmoid.action("configure") : null;
                            if (configAction) {
                                configAction.trigger();
                            } else if (typeof targetPlasmoid.internalAction === "function") {
                                var internalConfig = targetPlasmoid.internalAction("configure");
                                if (internalConfig) internalConfig.trigger();
                            }
                        }

                        // 2. Tutup kartu notch di tick berikutnya agar dialog pengaturan tidak ter-abort oleh unmap surface
                        Qt.callLater(() => {
                            if (typeof root !== "undefined" && typeof root.closeNotch === "function") {
                                root.closeNotch();
                            } else if (typeof root !== "undefined" && typeof root.triggerCollapseSequence === "function") {
                                root.triggerCollapseSequence();
                            } else {
                                controlCenterRoot.requestOpenSettings();
                            }
                        });
                    }
                }
            }

            // 3. Power / Session Shutdown
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: powerMa.containsMouse ? Qt.rgba(255/255, 59/255, 48/255, 0.5) : Qt.rgba(1, 1, 1, 0.10)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "system-shutdown"
                    color: "#ffffff"
                }

                MouseArea {
                    id: powerMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        sessionManager.requestPromptShutDown();
                    }
                }
            }
        }

        // ---------------------------------------------------------
        // 4. Horizontal Sliders (Volume & Brightness)
        // ---------------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            // Volume Slider
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    implicitWidth: 16
                    implicitHeight: 16
                    Layout.alignment: Qt.AlignVCenter

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        implicitWidth: 14
                        implicitHeight: 14
                        source: (controlCenterRoot.isMuted || controlCenterRoot.currentVolumePercent === 0)
                            ? "audio-volume-muted"
                            : (controlCenterRoot.currentVolumePercent < 50 ? "audio-volume-medium" : "audio-volume-high")
                        color: "#ffffff"
                        opacity: controlCenterRoot.isMuted ? 0.5 : 1.0
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlCenterRoot.toggleMute()
                    }
                }

                Text {
                    text: i18n("Volume")
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.family: "Inter, Roboto, sans-serif"
                    color: "#d0d4dc"
                    Layout.preferredWidth: 60
                }

                Item {
                    id: volSliderItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 7
                        radius: 3.5
                        color: Qt.rgba(1, 1, 1, 0.18)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(7, parent.width * (controlCenterRoot.currentVolumePercent / 100))
                            radius: 3.5
                            color: controlCenterRoot.isMuted ? Qt.rgba(1, 1, 1, 0.45) : "#ffffff"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: false
                        property real startX: 0
                        property real startY: 0
                        property bool isDraggingH: false

                        function updateVol(mouse) {
                            const pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)));
                            controlCenterRoot.setVolumePercent(pct);
                        }

                        onPressed: (mouse) => {
                            startX = mouse.x;
                            startY = mouse.y;
                            isDraggingH = false;
                            preventStealing = false;
                            updateVol(mouse);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                var dx = Math.abs(mouse.x - startX);
                                var dy = Math.abs(mouse.y - startY);
                                if (!isDraggingH && dx > 4 && dx > dy) {
                                    isDraggingH = true;
                                    preventStealing = true;
                                }
                                if (isDraggingH) {
                                    updateVol(mouse);
                                }
                            }
                        }
                        onReleased: {
                            preventStealing = false;
                            isDraggingH = false;
                        }
                        onCanceled: {
                            preventStealing = false;
                            isDraggingH = false;
                        }
                    }
                }

                Text {
                    text: controlCenterRoot.isMuted ? i18n("Mute") : (controlCenterRoot.currentVolumePercent + "%")
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: "Inter, Roboto, sans-serif"
                    color: controlCenterRoot.isMuted ? Qt.rgba(1, 1, 1, 0.55) : "#ffffff"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 38
                }
            }

            // Brightness Slider
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Kirigami.Icon {
                    implicitWidth: 14
                    implicitHeight: 14
                    source: "brightness-high"
                    color: "#ffffff"
                }

                Text {
                    text: i18n("Brightness")
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.family: "Inter, Roboto, sans-serif"
                    color: "#d0d4dc"
                    Layout.preferredWidth: 60
                }

                Item {
                    id: brightSliderItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 7
                        radius: 3.5
                        color: Qt.rgba(1, 1, 1, 0.18)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(7, parent.width * (controlCenterRoot.currentBrightnessPct / 100))
                            radius: 3.5
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: false
                        property real startX: 0
                        property real startY: 0
                        property bool isDraggingH: false

                        function updateBright(mouse) {
                            const pct = Math.max(1, Math.min(100, Math.round((mouse.x / width) * 100)));
                            controlCenterRoot.setBrightnessPercent(pct);
                        }

                        onPressed: (mouse) => {
                            startX = mouse.x;
                            startY = mouse.y;
                            isDraggingH = false;
                            preventStealing = false;
                            updateBright(mouse);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                var dx = Math.abs(mouse.x - startX);
                                var dy = Math.abs(mouse.y - startY);
                                if (!isDraggingH && dx > 4 && dx > dy) {
                                    isDraggingH = true;
                                    preventStealing = true;
                                }
                                if (isDraggingH) {
                                    updateBright(mouse);
                                }
                            }
                        }
                        onReleased: {
                            preventStealing = false;
                            isDraggingH = false;
                        }
                        onCanceled: {
                            preventStealing = false;
                            isDraggingH = false;
                        }
                    }
                }

                Text {
                    text: controlCenterRoot.currentBrightnessPct + "%"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: "Inter, Roboto, sans-serif"
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 38
                }
            }
        }

        // Spacer bawah agar slider paling bawah tidak terpotong saat scroll mentok
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 14
        }
    }
}
}
