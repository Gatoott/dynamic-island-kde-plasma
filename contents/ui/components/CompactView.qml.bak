import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Shapes
import "../states"

Item {
    id: compactNotchRoot
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    // Properties
    property real notchW: 190
    property real notchH: 34
    property real wingR: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.notchWingRadius !== undefined) return plasmoid.configuration.notchWingRadius;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.notchWingRadius !== undefined) return Plasmoid.configuration.notchWingRadius;
        return 14;
    }
    property real cornerR: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.notchBottomRadius !== undefined) return plasmoid.configuration.notchBottomRadius;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.notchBottomRadius !== undefined) return Plasmoid.configuration.notchBottomRadius;
        return 14;
    }

    // Style & Shape Options
    property int notchStyle: 0
    property string islandShapeMode: "notch"
    readonly property bool isFloatingStyle: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.notchStyle !== undefined) {
            return plasmoid.configuration.notchStyle === 1;
        }
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.notchStyle !== undefined) {
            return Plasmoid.configuration.notchStyle === 1;
        }
        return notchStyle === 1;
    }
    readonly property real effectiveWingR: isFloatingStyle ? 0 : wingR

    property color cfgBgColor: "#0b0b0f"
    property color cfgBorderColor: "#2a2b36"
    property color cfgAccentColor: "#3daee9"
    property int cfgClockFontSize: 13
    property string cfgClockFontFamily: ""
    property bool cfgClockFontBold: true
    property string cfgLyricsFontFamily: ""
    property int cfgLyricsFontSize: 13
    property bool cfgLyricsFontBold: true
    property bool cfgShowVisualizer: true
    property bool cfgShowCompactVisualizer: false
    property color albumDominantColor: cfgAccentColor

    // Mini Audio Visualizer Customization
    property int miniVisBarWidth: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisBarWidth !== undefined) return plasmoid.configuration.miniVisBarWidth;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisBarWidth !== undefined) return Plasmoid.configuration.miniVisBarWidth;
        return 2;
    }
    property int miniVisHeight: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
            if (plasmoid.configuration.miniVisHeight !== undefined) return plasmoid.configuration.miniVisHeight;
            if (plasmoid.configuration.miniVisMaxHeight !== undefined) return plasmoid.configuration.miniVisMaxHeight;
        }
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration) {
            if (Plasmoid.configuration.miniVisHeight !== undefined) return Plasmoid.configuration.miniVisHeight;
            if (Plasmoid.configuration.miniVisMaxHeight !== undefined) return Plasmoid.configuration.miniVisMaxHeight;
        }
        return 14;
    }
    property int miniVisSpacing: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisSpacing !== undefined) return plasmoid.configuration.miniVisSpacing;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisSpacing !== undefined) return Plasmoid.configuration.miniVisSpacing;
        return 2;
    }
    property int miniVisColorMode: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisColorMode !== undefined) return plasmoid.configuration.miniVisColorMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisColorMode !== undefined) return Plasmoid.configuration.miniVisColorMode;
        return 0;
    }
    property color miniVisCustomColor: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisCustomColor) return plasmoid.configuration.miniVisCustomColor;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisCustomColor) return Plasmoid.configuration.miniVisCustomColor;
        return Qt.color("#38bdf8");
    }
    property int miniVisAlignment: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisAlignment !== undefined) return plasmoid.configuration.miniVisAlignment;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisAlignment !== undefined) return Plasmoid.configuration.miniVisAlignment;
        return 1;
    }
    property bool miniVisRounded: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisRounded !== undefined) return plasmoid.configuration.miniVisRounded;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisRounded !== undefined) return Plasmoid.configuration.miniVisRounded;
        return true;
    }

    readonly property var plasmoidConfig: (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration) 
        ? plasmoid.configuration 
        : ((typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration) ? Plasmoid.configuration : null)

    // Mini Music Icon (Left of Clock) Customization
    property bool miniMusicIconEnabled: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconEnabled !== undefined) return plasmoid.configuration.miniMusicIconEnabled;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconEnabled !== undefined) return Plasmoid.configuration.miniMusicIconEnabled;
        return true;
    }
    property int miniMusicIconSize: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconSize !== undefined) return plasmoid.configuration.miniMusicIconSize;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconSize !== undefined) return Plasmoid.configuration.miniMusicIconSize;
        return 13;
    }
    property int miniMusicIconWeight: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconWeight !== undefined) return plasmoid.configuration.miniMusicIconWeight;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconWeight !== undefined) return Plasmoid.configuration.miniMusicIconWeight;
        return 600;
    }
    property int miniMusicIconColorMode: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconColorMode !== undefined) return plasmoid.configuration.miniMusicIconColorMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconColorMode !== undefined) return Plasmoid.configuration.miniMusicIconColorMode;
        return 0;
    }
    property color miniMusicIconCustomColor: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconCustomColor) return Qt.color(plasmoid.configuration.miniMusicIconCustomColor);
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconCustomColor) return Qt.color(Plasmoid.configuration.miniMusicIconCustomColor);
        return Qt.color("#ffffff");
    }

    // State bindings
    property bool isPlaying: false
    property string currentTimeString: "00:00"
    property string trackTitle: ""
    property string trackArtist: ""
    property bool activeNotificationPill: false
    property string notifAppName: ""
    property string notifIcon: ""
    property string notifSummary: ""
    property string notifBody: ""
    property bool activeBatteryPill: false
    property bool batteryIsCharging: false
    property int sysBatteryPct: 100
    property bool showPillLyrics: false
    property string currentLyricLine: ""

    signal requestToggle()

    width: isFloatingStyle ? notchW : (notchW + (effectiveWingR * 2))
    height: notchH

    Behavior on notchW {
        NumberAnimation {
            duration: 340
            easing.type: Easing.OutBack
            easing.overshoot: 1.25
        }
    }

    // ==============================================================
    // 1A. SILUET FLOATING CAPSULE (Tanpa Lekukan Sayap Atas - Borderless)
    // ==============================================================
    Rectangle {
        id: floatingPillBody
        visible: compactNotchRoot.isFloatingStyle
        anchors.fill: parent
        radius: height / 2 // Kapsul membulat penuh sempurna
        color: compactNotchRoot.cfgBgColor.a > 0 ? compactNotchRoot.cfgBgColor : "#0b0b0f"
        border.width: 0
        border.color: "transparent"
        clip: true
    }

    // ==============================================================
    // 1B. SILUET LIVING NOTCH (PathCubic Inverted Fillet Sayap Nempel Atas - Borderless)
    // ==============================================================
    Shape {
        id: compactSilhouette
        visible: !compactNotchRoot.isFloatingStyle
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        // Siluet Bodi Tunggal Living Notch (Border & Stroke dimatikan agar borderless dan menyatu mulus dengan panel)
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: compactNotchRoot.cfgBgColor

            startX: 0
            startY: 0

            // 1. Lekukan CEKUNG sayap kiri
            PathCubic {
                x: compactNotchRoot.wingR
                y: compactNotchRoot.wingR
                control1X: compactNotchRoot.wingR * 0.55
                control1Y: 0
                control2X: compactNotchRoot.wingR
                control2Y: compactNotchRoot.wingR * 0.45
            }

            // 2. Dinding kiri lurus ke bawah
            PathLine {
                x: compactNotchRoot.wingR
                y: compactNotchRoot.notchH - compactNotchRoot.cornerR
            }

            // 3. Sudut cembung kiri bawah
            PathArc {
                x: compactNotchRoot.wingR + compactNotchRoot.cornerR
                y: compactNotchRoot.notchH
                radiusX: Math.max(0.1, compactNotchRoot.cornerR)
                radiusY: Math.max(0.1, compactNotchRoot.cornerR)
                direction: PathArc.Counterclockwise
            }

            // 4. Garis horizontal dasar notch
            PathLine {
                x: compactNotchRoot.width - compactNotchRoot.wingR - compactNotchRoot.cornerR
                y: compactNotchRoot.notchH
            }

            // 5. Sudut cembung kanan bawah
            PathArc {
                x: compactNotchRoot.width - compactNotchRoot.wingR
                y: compactNotchRoot.notchH - compactNotchRoot.cornerR
                radiusX: Math.max(0.1, compactNotchRoot.cornerR)
                radiusY: Math.max(0.1, compactNotchRoot.cornerR)
                direction: PathArc.Counterclockwise
            }

            // 6. Dinding kanan lurus ke atas
            PathLine {
                x: compactNotchRoot.width - compactNotchRoot.wingR
                y: compactNotchRoot.wingR
            }

            // 7. Lekukan CEKUNG sayap kanan keluar ke bibir layar
            PathCubic {
                x: compactNotchRoot.width
                y: 0
                control1X: compactNotchRoot.width - compactNotchRoot.wingR
                control1Y: compactNotchRoot.wingR * 0.45
                control2X: compactNotchRoot.width - (compactNotchRoot.wingR * 0.55)
                control2Y: 0
            }

            // 8. Tutup garis horizontal atas
            PathLine { x: 0; y: 0 }
        }
    }

    // ==============================================================
    // KONTAINER KONTEN COMPACT (Centered di area notchW)
    // ==============================================================
    Item {
        id: contentContainer
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: compactNotchRoot.notchW
        clip: true

        // State 1: Notification Pill
        NotificationPill {
            anchors.fill: parent
            visible: opacity > 0
            opacity: compactNotchRoot.activeNotificationPill ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            appName: compactNotchRoot.notifAppName
            appIcon: compactNotchRoot.notifIcon
            summary: compactNotchRoot.notifSummary
            body: compactNotchRoot.notifBody
        }

        // State 2: Battery Pill
        BatteryPill {
            anchors.fill: parent
            visible: opacity > 0
            opacity: (!compactNotchRoot.activeNotificationPill && compactNotchRoot.activeBatteryPill) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            isCharging: compactNotchRoot.batteryIsCharging
            batteryPercent: compactNotchRoot.sysBatteryPct
        }

        // State 3: Dynamic Lyrics Pill
        LyricsPillView {
            anchors.fill: parent
            visible: opacity > 0
            opacity: (!compactNotchRoot.activeNotificationPill && !compactNotchRoot.activeBatteryPill && compactNotchRoot.showPillLyrics) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            currentLyricLine: compactNotchRoot.currentLyricLine
            trackTitle: compactNotchRoot.trackTitle
            trackArtist: compactNotchRoot.trackArtist
            accentColor: compactNotchRoot.cfgAccentColor
            albumColor: compactNotchRoot.albumDominantColor
            fontSize: compactNotchRoot.cfgLyricsFontSize
            lyricsFontFamily: compactNotchRoot.cfgLyricsFontFamily
            lyricsFontBold: compactNotchRoot.cfgLyricsFontBold
            showCompactVisualizer: compactNotchRoot.cfgShowCompactVisualizer
            isPlaying: compactNotchRoot.isPlaying

            miniMusicIconEnabled: compactNotchRoot.miniMusicIconEnabled
            miniMusicIconSize: compactNotchRoot.miniMusicIconSize
            miniMusicIconWeight: compactNotchRoot.miniMusicIconWeight
            miniMusicIconColorMode: compactNotchRoot.miniMusicIconColorMode
            miniMusicIconCustomColor: compactNotchRoot.miniMusicIconCustomColor

            miniVisBarWidth: compactNotchRoot.miniVisBarWidth
            miniVisHeight: compactNotchRoot.miniVisHeight
            miniVisSpacing: compactNotchRoot.miniVisSpacing
            miniVisColorMode: compactNotchRoot.miniVisColorMode
            miniVisCustomColor: compactNotchRoot.miniVisCustomColor
            miniVisAlignment: compactNotchRoot.miniVisAlignment
            miniVisRounded: compactNotchRoot.miniVisRounded
        }

        // State 4: Standby View (Jam & Audio Visualizer)
        StandbyView {
            anchors.fill: parent
            visible: opacity > 0
            opacity: (!compactNotchRoot.activeNotificationPill && !compactNotchRoot.activeBatteryPill && !compactNotchRoot.showPillLyrics) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            isPlaying: compactNotchRoot.isPlaying
            currentTimeString: compactNotchRoot.currentTimeString
            trackTitle: compactNotchRoot.trackTitle
            trackArtist: compactNotchRoot.trackArtist
            accentColor: compactNotchRoot.cfgAccentColor
            albumColor: compactNotchRoot.albumDominantColor
            fontSize: compactNotchRoot.cfgClockFontSize
            clockFontFamily: compactNotchRoot.cfgClockFontFamily
            clockFontBold: compactNotchRoot.cfgClockFontBold
            showVisualizer: compactNotchRoot.cfgShowVisualizer
            miniVisBarWidth: compactNotchRoot.miniVisBarWidth
            miniVisHeight: compactNotchRoot.miniVisHeight
            miniVisSpacing: compactNotchRoot.miniVisSpacing
            miniVisColorMode: compactNotchRoot.miniVisColorMode
            miniVisCustomColor: compactNotchRoot.miniVisCustomColor
            miniVisAlignment: compactNotchRoot.miniVisAlignment
            miniVisRounded: compactNotchRoot.miniVisRounded

            miniMusicIconEnabled: compactNotchRoot.miniMusicIconEnabled
            miniMusicIconSize: compactNotchRoot.miniMusicIconSize
            miniMusicIconWeight: compactNotchRoot.miniMusicIconWeight
            miniMusicIconColorMode: compactNotchRoot.miniMusicIconColorMode
            miniMusicIconCustomColor: compactNotchRoot.miniMusicIconCustomColor
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: compactNotchRoot.requestToggle()
        }
    }
}
