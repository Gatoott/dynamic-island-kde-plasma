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
    readonly property bool isFloatingStyle: notchStyle === 1 || islandShapeMode === "dock" || islandShapeMode === "pill"
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
    // 1A. SILUET FLOATING CAPSULE (Tanpa Lekukan Sayap Atas)
    // ==============================================================
    Rectangle {
        id: floatingPillBody
        visible: compactNotchRoot.isFloatingStyle
        anchors.fill: parent
        radius: height / 2 // Kapsul membulat penuh sempurna
        color: compactNotchRoot.cfgBgColor.a > 0 ? compactNotchRoot.cfgBgColor : "#0b0b0f"
        border.width: 1
        border.color: compactNotchRoot.cfgBorderColor.a > 0 ? compactNotchRoot.cfgBorderColor : Qt.rgba(1, 1, 1, 0.12)
        clip: true

        // Inner subtle rim highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, (parent.height / 2) - 1)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
        }
    }

    // ==============================================================
    // 1B. SILUET LIVING NOTCH (PathCubic Inverted Fillet Sayap Nempel Atas)
    // ==============================================================
    Shape {
        id: compactSilhouette
        visible: !compactNotchRoot.isFloatingStyle
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        // 1A. Aksen Dark Glow Minimalis Mengitari Siluet
        ShapePath {
            strokeColor: Qt.rgba(0.2, 0.45, 0.85, 0.28)
            strokeWidth: 3
            fillColor: "transparent"

            startX: 0
            startY: 0

            // Lekukan CEKUNG sayap kiri
            PathCubic {
                x: compactNotchRoot.wingR
                y: compactNotchRoot.wingR
                control1X: compactNotchRoot.wingR * 0.55
                control1Y: 0
                control2X: compactNotchRoot.wingR
                control2Y: compactNotchRoot.wingR * 0.45
            }

            // Dinding vertikal kiri
            PathLine {
                x: compactNotchRoot.wingR
                y: compactNotchRoot.notchH - compactNotchRoot.cornerR
            }

            // Sudut cembung kiri bawah
            PathArc {
                x: compactNotchRoot.wingR + compactNotchRoot.cornerR
                y: compactNotchRoot.notchH
                radiusX: Math.max(0.1, compactNotchRoot.cornerR)
                radiusY: Math.max(0.1, compactNotchRoot.cornerR)
                direction: PathArc.Counterclockwise
            }

            // Garis horizontal dasar notch
            PathLine {
                x: compactNotchRoot.width - compactNotchRoot.wingR - compactNotchRoot.cornerR
                y: compactNotchRoot.notchH
            }

            // Sudut cembung kanan bawah
            PathArc {
                x: compactNotchRoot.width - compactNotchRoot.wingR
                y: compactNotchRoot.notchH - compactNotchRoot.cornerR
                radiusX: Math.max(0.1, compactNotchRoot.cornerR)
                radiusY: Math.max(0.1, compactNotchRoot.cornerR)
                direction: PathArc.Counterclockwise
            }

            // Dinding vertikal kanan
            PathLine {
                x: compactNotchRoot.width - compactNotchRoot.wingR
                y: compactNotchRoot.wingR
            }

            // Lekukan CEKUNG sayap kanan
            PathCubic {
                x: compactNotchRoot.width
                y: 0
                control1X: compactNotchRoot.width - compactNotchRoot.wingR
                control1Y: compactNotchRoot.wingR * 0.45
                control2X: compactNotchRoot.width - (compactNotchRoot.wingR * 0.55)
                control2Y: 0
            }
        }

        // 1B. Siluet Bodi + 1px Outline Semi-Transparan
        ShapePath {
            strokeColor: compactNotchRoot.cfgBorderColor
            strokeWidth: 1
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
            fontSize: compactNotchRoot.cfgLyricsFontSize
            lyricsFontFamily: compactNotchRoot.cfgLyricsFontFamily
            lyricsFontBold: compactNotchRoot.cfgLyricsFontBold
            showCompactVisualizer: compactNotchRoot.cfgShowCompactVisualizer
            isPlaying: compactNotchRoot.isPlaying
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
            fontSize: compactNotchRoot.cfgClockFontSize
            clockFontFamily: compactNotchRoot.cfgClockFontFamily
            clockFontBold: compactNotchRoot.cfgClockFontBold
            showVisualizer: compactNotchRoot.cfgShowVisualizer
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: compactNotchRoot.requestToggle()
        }
    }
}
