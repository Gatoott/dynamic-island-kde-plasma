import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "."
import "../states"

Rectangle {
    id: livingNotch
    clip: true

    // State
    property bool isExpanded: false
    property int currentExpandedTab: 0
    property bool showLyrics: false
    property string currentTimeString: "00:00"
    property string islandShapeMode: "notch"

    // Visual styles passed from parent
    property color cfgAccentColor: "#3daee9"
    property color cfgBgColor: Qt.rgba(0.05, 0.06, 0.07, 0.95)
    property color cfgBorderColor: Qt.rgba(1, 1, 1, 0.2)
    property int cfgExpandedWidth: 420
    property int cfgExpandedHeight: 335
    property int compactWidth: 145
    property int compactHeight: 36

    // Compact State Bindings
    property bool activeNotificationPill: false
    property string notifAppName: ""
    property string notifSummary: ""
    property string notifBody: ""
    property string notifIcon: ""
    property bool activeBatteryPill: false
    property bool batteryIsCharging: false
    property bool showPillLyrics: false
    property string currentLyricLine: ""
    property int cfgClockFontSize: 13
    property bool cfgShowVisualizer: true

    // System Metrics
    property int sysCpuPct: 12
    property int sysTemp: 40
    property int sysRamPct: 42
    property int sysBatteryPct: 100
    property bool sysBatteryCharging: false

    // Media properties
    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property string albumArtUrl: ""
    property real trackPosition: 0
    property real trackLength: 0
    property bool isPlaying: false
    property bool canControl: true
    property bool canGoNext: true
    property bool canGoPrevious: true
    property var lyricsList: []
    property int currentLyricIndex: -1
    property bool lyricsLoading: false
    property bool lyricsFound: false

    // Signals
    signal requestToggle()
    signal requestClose()
    signal requestSwitchTab(int tabIndex)
    signal requestPlayPause()
    signal requestNext()
    signal requestPrevious()
    signal requestSeek(real positionSeconds)
    signal requestToggleLyrics()
    signal requestRetryLyrics()

    // Dynamic Geometry Calculation
    readonly property int targetWidth: {
        if (!isExpanded) return compactWidth;
        if (currentExpandedTab === 1 && showLyrics) return 680;
        return cfgExpandedWidth;
    }
    readonly property int targetHeight: isExpanded ? cfgExpandedHeight : compactHeight

    width: targetWidth
    height: targetHeight

    color: cfgBgColor
    border.color: cfgBorderColor
    border.width: 1

    // Hardware living notch geometry:
    // Flat top corners (0) to seamlessly attach to screen / panel edge
    // Rounded bottom corners (16 when compact, 22 when expanded)
    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: isExpanded ? 22 : 16
    bottomRightRadius: isExpanded ? 22 : 16

    Behavior on bottomLeftRadius { NumberAnimation { duration: 200 } }
    Behavior on bottomRightRadius { NumberAnimation { duration: 200 } }

    // -------------------------------------------------------------
    // Hardware OpenGL/Vulkan Texture Layer Caching during Animation
    // -------------------------------------------------------------
    readonly property bool isMorphing: widthAnim.running || heightAnim.running
    layer.enabled: isMorphing
    layer.smooth: true

    // Original fluid spring animation formula (Nusa 1.1)
    Behavior on width {
        NumberAnimation {
            id: widthAnim
            duration: 350
            easing.type: Easing.OutBack
            easing.overshoot: 1.25
        }
    }
    Behavior on height {
        NumberAnimation {
            id: heightAnim
            duration: 350
            easing.type: Easing.OutBack
            easing.overshoot: 1.25
        }
    }

    // --- Subtle Top Glow Edge (Nusa 1.1 Style) ---
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        opacity: 0.8
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0.2, 0.4, 0.9, 0.0) }
            GradientStop { position: 0.3; color: Qt.rgba(0.4, 0.45, 1.0, 0.5) }
            GradientStop { position: 0.5; color: Qt.rgba(0.55, 0.4, 1.0, 0.65) }
            GradientStop { position: 0.7; color: Qt.rgba(0.4, 0.45, 1.0, 0.5) }
            GradientStop { position: 1.0; color: Qt.rgba(0.2, 0.4, 0.9, 0.0) }
        }
    }

    // ==============================================================
    // 1. COMPACT CONTENT (Shown when collapsed)
    // ==============================================================
    Item {
        id: compactContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: livingNotch.compactHeight

        visible: opacity > 0
        opacity: (livingNotch.isExpanded || livingNotch.isMorphing) ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 160 } }

        // State 1: Notification Pill
        NotificationPill {
            anchors.fill: parent
            visible: opacity > 0
            opacity: livingNotch.activeNotificationPill ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            appName: livingNotch.notifAppName
            appIcon: livingNotch.notifIcon
            summary: livingNotch.notifSummary
            body: livingNotch.notifBody
        }

        // State 2: Battery Pill
        BatteryPill {
            anchors.fill: parent
            visible: opacity > 0
            opacity: (!livingNotch.activeNotificationPill && livingNotch.activeBatteryPill) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            isCharging: livingNotch.batteryIsCharging
            batteryPercent: livingNotch.sysBatteryPct
        }

        // State 3: Dynamic Lyrics Pill
        LyricsPillView {
            anchors.fill: parent
            visible: opacity > 0
            opacity: (!livingNotch.activeNotificationPill && !livingNotch.activeBatteryPill && livingNotch.showPillLyrics) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            currentLyricLine: livingNotch.currentLyricLine
            accentColor: livingNotch.cfgAccentColor
            fontSize: livingNotch.cfgClockFontSize
        }

        // State 4: Standby View (♫, Clock, Visualizer)
        StandbyView {
            anchors.fill: parent
            visible: opacity > 0
            opacity: (!livingNotch.activeNotificationPill && !livingNotch.activeBatteryPill && !livingNotch.showPillLyrics) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            isPlaying: livingNotch.isPlaying
            currentTimeString: livingNotch.currentTimeString
            trackTitle: livingNotch.trackTitle
            trackArtist: livingNotch.trackArtist
            accentColor: livingNotch.cfgAccentColor
            fontSize: livingNotch.cfgClockFontSize
            showVisualizer: livingNotch.cfgShowVisualizer
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: livingNotch.requestToggle()
        }
    }

    // ==============================================================
    // 2. CLEAN HARDWARE NOTCH TOP HANDLE (Zero Window Chrome / Headers)
    // ==============================================================
    Item {
        id: topNotchHandle
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 18
        visible: livingNotch.isExpanded

        // Click top handle to collapse living notch
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: livingNotch.requestClose()
        }

        // Mini Pill Grip (Center)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.3)
        }
    }

    // ==============================================================
    // 3. EXPANDED CARDS CONTENT AREA (Tab 0: Control, Tab 1: Media, Tab 2: Clip)
    // ==============================================================
    Item {
        id: cardsArea
        anchors.top: topNotchHandle.bottom
        anchors.topMargin: 2
        anchors.bottom: paginationDotsRow.top
        anchors.bottomMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 36
        anchors.rightMargin: 36

        // Fast GPU fade during morphing: keeps rendering at 60 FPS
        Loader {
            id: tabLoader
            anchors.fill: parent
            opacity: (livingNotch.isMorphing || !livingNotch.isExpanded) ? 0.0 : 1.0
            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
            }

            sourceComponent: {
                if (!livingNotch.isExpanded) return null;
                switch (livingNotch.currentExpandedTab) {
                    case 0: return controlCenterComponent;
                    case 1: return mediaLyricsComponent;
                    case 2: return clipboardComponent;
                    default: return controlCenterComponent;
                }
            }
        }

        // Tab 0: Control Center Utama
        Component {
            id: controlCenterComponent
            ControlCenterCard {
                anchors.fill: parent
                accentColor: livingNotch.cfgAccentColor
                currentTimeString: livingNotch.currentTimeString
                islandMode: livingNotch.islandShapeMode
                cpuPercent: livingNotch.sysCpuPct
                cpuTemp: livingNotch.sysTemp
                ramPercent: livingNotch.sysRamPct
                batteryPercent: livingNotch.sysBatteryPct
                batteryCharging: livingNotch.sysBatteryCharging
                batteryTemp: 32

                onRequestSwitchToMedia: livingNotch.requestSwitchTab(1)
            }
        }

        // Tab 1: Media Player & Dynamic Lyrics
        Component {
            id: mediaLyricsComponent
            MediaLyricsCard {
                anchors.fill: parent
                trackTitle: livingNotch.trackTitle
                trackArtist: livingNotch.trackArtist
                trackAlbum: livingNotch.trackAlbum
                albumArtUrl: livingNotch.albumArtUrl
                trackPosition: livingNotch.trackPosition
                trackLength: livingNotch.trackLength
                isPlaying: livingNotch.isPlaying
                canControl: livingNotch.canControl
                canGoNext: livingNotch.canGoNext
                canGoPrevious: livingNotch.canGoPrevious
                accentColor: livingNotch.cfgAccentColor
                showLyrics: livingNotch.showLyrics
                lyricsList: livingNotch.lyricsList
                currentLyricIndex: livingNotch.currentLyricIndex
                lyricsLoading: livingNotch.lyricsLoading
                lyricsFound: livingNotch.lyricsFound
                activeTabIndex: livingNotch.currentExpandedTab

                onRequestPlayPause: livingNotch.requestPlayPause()
                onRequestNext: livingNotch.requestNext()
                onRequestPrevious: livingNotch.requestPrevious()
                onRequestSeek: (pos) => livingNotch.requestSeek(pos)
                onRequestToggleLyrics: livingNotch.requestToggleLyrics()
                onRequestRetryLyrics: livingNotch.requestRetryLyrics()
                onRequestSwitchTab: (tabIdx) => livingNotch.requestSwitchTab(tabIdx)
            }
        }

        // Tab 2: Clipboard Manager (Klipper Integration)
        Component {
            id: clipboardComponent
            ClipboardCard {
                anchors.fill: parent
                accentColor: livingNotch.cfgAccentColor
            }
        }
    }

    // ==============================================================
    // 4. VERTICALLY CENTERED NAVIGATION ARROWS
    // ==============================================================
    // Left Arrow (<)
    Rectangle {
        id: leftNavBtn
        width: 28
        height: 28
        radius: 14
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: livingNotch.isExpanded && !livingNotch.isMorphing
        color: leftNavMa.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14)

        Text {
            anchors.centerIn: parent
            text: "‹"
            font.pixelSize: 18
            font.bold: true
            color: "#ffffff"
        }

        MouseArea {
            id: leftNavMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                livingNotch.requestSwitchTab((livingNotch.currentExpandedTab - 1 + 3) % 3);
            }
        }
    }

    // Right Arrow (>)
    Rectangle {
        id: rightNavBtn
        width: 28
        height: 28
        radius: 14
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: livingNotch.isExpanded && !livingNotch.isMorphing
        color: rightNavMa.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14)

        Text {
            anchors.centerIn: parent
            text: "›"
            font.pixelSize: 18
            font.bold: true
            color: "#ffffff"
        }

        MouseArea {
            id: rightNavMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                livingNotch.requestSwitchTab((livingNotch.currentExpandedTab + 1) % 3);
            }
        }
    }

    // ==============================================================
    // 5. PAGINATION DOTS (Bottom Center)
    // ==============================================================
    Row {
        id: paginationDotsRow
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        visible: livingNotch.isExpanded && !livingNotch.isMorphing
        spacing: 7

        Repeater {
            model: 3
            Rectangle {
                required property int index
                width: livingNotch.currentExpandedTab === index ? 16 : 6
                height: 6
                radius: 3
                color: livingNotch.currentExpandedTab === index ? livingNotch.cfgAccentColor : Qt.rgba(1, 1, 1, 0.25)
                Behavior on width { NumberAnimation { duration: 200 } }
                Behavior on color { ColorAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: livingNotch.requestSwitchTab(parent.index)
                }
            }
        }
    }
}
