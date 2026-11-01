import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.bluezqt as BluezQt
import org.kde.plasma.private.volume as Vol
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
    // Volume Control (Pure Plasma 6 Native)
    // -------------------------------------------------------------
    readonly property var sink: (typeof Vol !== "undefined" && Vol.PreferredDevice) ? Vol.PreferredDevice.sink : null
    readonly property int currentVolumePct: sink ? Math.round(sink.volume / Vol.PulseAudio.NormalVolume * 100) : 70

    function setVolumePercent(val) {
        if (!sink) return;
        const clamped = Math.max(0, Math.min(100, Math.round(val)));
        sink.volume = Math.round(clamped * Vol.PulseAudio.NormalVolume / 100);
        if (sink.muted && clamped > 0) {
            sink.muted = false;
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
    // UI LAYOUT (Scrollable Flickable)
    // =============================================================
    Flickable {
        id: controlCenterFlickable
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 24
        anchors.leftMargin: 44 // Ruang aman dari tombol panah navigasi kiri
        anchors.rightMargin: 44 // Ruang aman dari tombol panah navigasi kanan
        clip: true // Mencegah item meluber keluar batas kartu

        contentWidth: width
        contentHeight: controlCenterLayout.implicitHeight

        boundsBehavior: Flickable.StopAtBounds

        WheelHandler {
            target: controlCenterFlickable
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }

        ColumnLayout {
            id: controlCenterLayout
            width: controlCenterFlickable.width - (controlCenterFlickable.contentHeight > controlCenterFlickable.height ? 6 : 0)
            spacing: 10

        // ---------------------------------------------------------
        // 1. Header Bar Status Monitor
        // ---------------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 30

            RowLayout {
                anchors.fill: parent
                spacing: 8

                // Left: CPU & RAM Stats
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
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

                Item { Layout.fillWidth: true }

                // Center: Digital Clock & Date
                Item {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    implicitWidth: centerClockCol.implicitWidth
                    implicitHeight: centerClockCol.implicitHeight

                    Column {
                        id: centerClockCol
                        anchors.centerIn: parent
                        spacing: 1

                        Text {
                            id: centerClockText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controlCenterRoot.currentTimeString !== "" ? controlCenterRoot.currentTimeString : "00:00"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#ffffff"
                        }

                        Text {
                            id: centerDateText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controlCenterRoot.currentDateString !== "" ? controlCenterRoot.currentDateString : ""
                            font.pixelSize: 9
                            font.family: "Inter, Roboto, sans-serif"
                            color: Qt.rgba(1, 1, 1, 0.65)
                            visible: text !== ""
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Battery & Temp
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
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
        // 3. Quick Action Icons Row (5 Circular Buttons)
        // ---------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            spacing: 10

            // 1. Dark Mode Toggle
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 18
                color: dndMa1.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.1)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "weather-clear-night"
                    color: "#ffffff"
                }

                MouseArea {
                    id: dndMa1
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenterRoot.toggleDarkMode()
                }
            }

            // 2. Do Not Disturb Toggle
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 18
                color: controlCenterRoot.dndActive ? Qt.rgba(255/255, 59/255, 48/255, 0.4) : (dndMa2.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.1))

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: controlCenterRoot.dndActive ? "notifications-disabled" : "notifications"
                    color: controlCenterRoot.dndActive ? "#ff453a" : "#ffffff"
                }

                MouseArea {
                    id: dndMa2
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenterRoot.toggleDND()
                }
            }

            // 3. App Grid / Launcher
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 18
                color: dndMa3.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.1)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "applications-all"
                    color: "#ffffff"
                }

                MouseArea {
                    id: dndMa3
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenterRoot.requestOpenLauncher()
                }
            }

            // 4. System Settings
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 18
                color: dndMa4.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.1)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "configure"
                    color: "#ffffff"
                }

                MouseArea {
                    id: dndMa4
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenterRoot.requestOpenSettings()
                }
            }

            // 5. Power Shutdown
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 18
                color: dndMa5.containsMouse ? Qt.rgba(255/255, 59/255, 48/255, 0.5) : Qt.rgba(1, 1, 1, 0.1)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "system-shutdown"
                    color: "#ffffff"
                }

                MouseArea {
                    id: dndMa5
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

                Kirigami.Icon {
                    implicitWidth: 14
                    implicitHeight: 14
                    source: controlCenterRoot.currentVolumePct === 0 ? "audio-volume-muted" : "audio-volume-high"
                    color: "#ffffff"
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
                            width: Math.max(7, parent.width * (controlCenterRoot.currentVolumePct / 100))
                            radius: 3.5
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true

                        function updateVol(mouse) {
                            const pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)));
                            controlCenterRoot.setVolumePercent(pct);
                        }

                        onPressed: (mouse) => updateVol(mouse)
                        onPositionChanged: (mouse) => {
                            if (pressed) updateVol(mouse);
                        }
                    }
                }

                Text {
                    text: controlCenterRoot.currentVolumePct + "%"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: "Inter, Roboto, sans-serif"
                    color: "#ffffff"
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
                        preventStealing: true

                        function updateBright(mouse) {
                            const pct = Math.max(1, Math.min(100, Math.round((mouse.x / width) * 100)));
                            controlCenterRoot.setBrightnessPercent(pct);
                        }

                        onPressed: (mouse) => updateBright(mouse)
                        onPositionChanged: (mouse) => {
                            if (pressed) updateBright(mouse);
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
    }

    QQC2.ScrollBar.vertical: QQC2.ScrollBar {
        policy: controlCenterFlickable.contentHeight > controlCenterFlickable.height 
            ? QQC2.ScrollBar.AsNeeded 
            : QQC2.ScrollBar.AlwaysOff
        width: 3
    }
}
}
