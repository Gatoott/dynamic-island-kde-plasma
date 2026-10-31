import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import "."
import "../states"

Item {
    id: unifiedNotchRoot
    clip: false

    // Pastikan root item kartu menempel kokoh di bibir atas container:
    anchors.top: parent ? parent.top : undefined
    anchors.topMargin: (typeof root !== "undefined" && root.isFloatingStyle) ? root.effectiveVerticalOffset : 0
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

    // State
    property bool isExpanded: false
    property int currentExpandedTab: 0
    property bool showLyrics: false
    property string currentTimeString: "00:00"
    property int notchStyle: 0
    property string islandShapeMode: "notch"
    readonly property bool isFloatingStyle: notchStyle === 1 || islandShapeMode === "dock" || islandShapeMode === "pill"

    // Tab Modular Visibility
    property bool showControlTab: true
    property bool showMediaTab: true
    property bool showClipboardTab: true
    property bool showNotificationTab: true

    readonly property var availableTabs: {
        var tabs = [];
        if (showControlTab) tabs.push("control");
        if (showMediaTab) tabs.push("media");
        if (showClipboardTab) tabs.push("clipboard");
        if (showNotificationTab) tabs.push("notification");
        if (tabs.length === 0) tabs.push("control");
        return tabs;
    }
    readonly property string activeTabKey: (availableTabs && availableTabs.length > 0) ? availableTabs[currentExpandedTab % availableTabs.length] : "control"

    // Typography Options
    property string cfgClockFontFamily: ""
    property bool cfgClockFontBold: true
    property string cfgLyricsFontFamily: ""
    property int cfgLyricsFontSize: 13
    property bool cfgLyricsFontBold: true

    // Visual styles passed from parent
    property color cfgAccentColor: "#3daee9"
    property color cfgBgColor: Qt.rgba(0.05, 0.06, 0.07, 0.95)
    property color cfgBorderColor: Qt.rgba(1, 1, 1, 0.2)
    property int cfgExpandedWidth: 420
    property int cfgExpandedHeight: 335
    property int compactWidth: 180
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
    property bool cfgShowCompactVisualizer: false
    property string currentDateString: ""

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

    // Notification History
    property var notificationHistory: []

    // Signals
    signal requestToggle()
    signal requestClose()
    signal requestSwitchTab(int tabIndex)
    signal requestPlayPause()
    signal requestNext()
    signal requestPrevious()
    signal requestSeek(real positionSeconds)
    signal requestToggleLyrics()
    signal requestCloseLyrics()
    signal requestRetryLyrics()
    signal requestDemoLyrics()
    signal requestClearAllNotifications()
    signal requestRemoveNotification(var notifId)
    signal collapseCompleted()
    signal collapseFinished()

    // -------------------------------------------------------------
    // Unified Geometry & Physical Shrink Dimensions (Single Silhouette)
    // -------------------------------------------------------------
    property real bodyOpacity: 1.0
    property bool isOverlayDialog: false

    property real cfgNotchWingRadius: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.notchWingRadius !== undefined) return plasmoid.configuration.notchWingRadius;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.notchWingRadius !== undefined) return Plasmoid.configuration.notchWingRadius;
        return 14;
    }
    property real cfgNotchBottomRadius: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.notchBottomRadius !== undefined) return plasmoid.configuration.notchBottomRadius;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.notchBottomRadius !== undefined) return Plasmoid.configuration.notchBottomRadius;
        return 14;
    }

    readonly property real wingRadius: cfgNotchWingRadius
    readonly property real effectiveWingRadius: isFloatingStyle ? 0 : wingRadius
    property real cornerRadius: cfgNotchBottomRadius
    Behavior on cornerRadius { NumberAnimation { duration: 200 } }

    // Pemetaan Dimensi Eksplisit Tiap Tab (Anti-NaN & Anti-Squish)
    // Tab 0: Control Center (Landscape Dashboard) -> 520 x 380
    // Tab 1: Media Player (Landscape Card)        -> 540 x 210
    // Tab 2: Synced Lyrics (Landscape Split)      -> 620 x 220
    // Tab 3: Clipboard Manager                    -> 480 x 360
    // Tab 4: Notification History                 -> 480 x 360
    function getTargetWidthForTab(tabIndex, lyricsActive) {
        var key = activeTabKey;
        if (key === "media" || tabIndex === 1) {
            return lyricsActive ? 640 : 540;
        }
        if (key === "control" || tabIndex === 0) {
            return 520;
        }
        if (key === "clipboard" || tabIndex === 2) {
            return 480;
        }
        if (key === "notification" || tabIndex === 3) {
            return 480;
        }
        return 520;
    }

    function getTargetHeightForTab(tabIndex, lyricsActive) {
        var key = activeTabKey;
        if (key === "media" || tabIndex === 1) {
            return lyricsActive ? 220 : 210;
        }
        if (key === "control" || tabIndex === 0) {
            return 380;
        }
        if (key === "clipboard" || tabIndex === 2) {
            return 360;
        }
        if (key === "notification" || tabIndex === 3) {
            return 360;
        }
        return 360;
    }

    // Ikat targetW dan targetH secara langsung dan reaktif:
    property real targetW: isExpanded ? getTargetWidthForTab(currentExpandedTab, showLyrics) : compactWidth
    property real targetH: isExpanded ? getTargetHeightForTab(currentExpandedTab, showLyrics) : compactHeight

    width: isFloatingStyle ? targetW : (targetW + (effectiveWingRadius * 2))
    height: targetH
    opacity: 1.0

    readonly property bool isMorphing: widthAnim.running || heightAnim.running

    Behavior on targetW {
        NumberAnimation {
            id: widthAnim
            duration: 280
            easing.type: Easing.OutQuad
        }
    }
    Behavior on targetH {
        NumberAnimation {
            id: heightAnim
            duration: 280
            easing.type: Easing.OutQuad
        }
    }

    onIsExpandedChanged: {
        if (isExpanded) {
            unifiedNotchRoot.bodyOpacity = 1.0;
            unifiedNotchRoot.opacity = 1.0;
            unifiedNotchRoot.width = Qt.binding(function() {
                return unifiedNotchRoot.isFloatingStyle ? unifiedNotchRoot.targetW : (unifiedNotchRoot.targetW + (unifiedNotchRoot.effectiveWingRadius * 2));
            });
            unifiedNotchRoot.height = Qt.binding(function() {
                return unifiedNotchRoot.targetH;
            });
        } else {
            // Jika selisih tinggi sudah sangat kecil, langsung selesaikan tanpa menunggu animasi
            if (Math.abs(unifiedNotchRoot.height - compactHeight) < 2) {
                unifiedNotchRoot.collapseCompleted();
                unifiedNotchRoot.collapseFinished();
            }
        }
    }

    Timer {
        id: bufferFlushTimer
        interval: 20
        repeat: false
        onTriggered: {
            console.log("[NOTCH] T=300ms: GPU buffer kosong transparan ter-flush, eksekusi handoff!");
            unifiedNotchRoot.collapseCompleted();
            unifiedNotchRoot.collapseFinished();
        }
    }

    Connections {
        target: heightAnim
        function onRunningChanged() {
            if (!heightAnim.running && !unifiedNotchRoot.isExpanded) {
                console.log("[NOTCH] T=280ms: Animasi ciut fisik selesai!");
                if (unifiedNotchRoot.isOverlayDialog) {
                    // Setel opacity bodi notch menjadi 0.0 (seketika kosong/transparan)
                    unifiedNotchRoot.bodyOpacity = 0.0;
                    // Jeda 1 frame (~20ms) agar GPU sempat mengosongkan buffer render sebelum unmap
                    bufferFlushTimer.restart();
                } else {
                    unifiedNotchRoot.collapseCompleted();
                    unifiedNotchRoot.collapseFinished();
                }
            }
        }
    }

    // ==============================================================
    // 1. SILUET TUNGGAL UTUH (Bodi + Sayap Kiri & Kanan Tanpa Sambungan)
    // Satu ShapePath tertutup: Mustahil ada garis tumpuk atau undakan
    // ==============================================================
    // 1A. SILUET FLOATING CAPSULE (Tanpa Lekukan Sayap Atas)
    // ==============================================================
    Rectangle {
        id: floatingSilhouette
        visible: unifiedNotchRoot.isFloatingStyle
        anchors.fill: parent
        opacity: unifiedNotchRoot.bodyOpacity
        radius: unifiedNotchRoot.isExpanded ? unifiedNotchRoot.cornerRadius : (height / 2)
        Behavior on radius { NumberAnimation { duration: 200 } }
        color: unifiedNotchRoot.cfgBgColor.a > 0 ? unifiedNotchRoot.cfgBgColor : "#0b0b0f"
        border.width: 1
        border.color: unifiedNotchRoot.cfgBorderColor.a > 0 ? unifiedNotchRoot.cfgBorderColor : Qt.rgba(1, 1, 1, 0.12)
        clip: true

        // Inner subtle rim highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
        }
    }

    // ==============================================================
    // 1B. SILUET LIVING NOTCH (Bodi + Sayap Kiri & Kanan - Gambar 1)
    // Satu ShapePath tertutup: Mustahil ada garis tumpuk atau undakan
    // ==============================================================
    Shape {
        id: notchSilhouette
        visible: !unifiedNotchRoot.isFloatingStyle
        anchors.fill: parent
        opacity: unifiedNotchRoot.bodyOpacity
        layer.enabled: true
        layer.samples: 4

        // 1A. Aksen Dark Glow Minimalis Mengitari Siluet (seperti Gambar 1)
        ShapePath {
            strokeColor: Qt.rgba(0.2, 0.45, 0.85, 0.28)
            strokeWidth: 3
            fillColor: "transparent"

            startX: 0
            startY: 0

            // 1. Lekukan CEKUNG sayap kiri (Inverted Fillet) menggunakan PathCubic
            PathCubic {
                x: unifiedNotchRoot.wingRadius
                y: unifiedNotchRoot.wingRadius
                control1X: unifiedNotchRoot.wingRadius * 0.55
                control1Y: 0
                control2X: unifiedNotchRoot.wingRadius
                control2Y: unifiedNotchRoot.wingRadius * 0.45
            }

            // 2. Dinding vertikal kiri turun ke bawah
            PathLine {
                x: unifiedNotchRoot.wingRadius
                y: unifiedNotchRoot.targetH - unifiedNotchRoot.cornerRadius
            }

            // 3. Sudut cembung kiri bawah
            PathArc {
                x: unifiedNotchRoot.wingRadius + unifiedNotchRoot.cornerRadius
                y: unifiedNotchRoot.targetH
                radiusX: Math.max(0.1, unifiedNotchRoot.cornerRadius)
                radiusY: Math.max(0.1, unifiedNotchRoot.cornerRadius)
                direction: PathArc.Counterclockwise
            }

            // 4. Garis horizontal dasar notch
            PathLine {
                x: unifiedNotchRoot.width - unifiedNotchRoot.wingRadius - unifiedNotchRoot.cornerRadius
                y: unifiedNotchRoot.targetH
            }

            // 5. Sudut cembung kanan bawah
            PathArc {
                x: unifiedNotchRoot.width - unifiedNotchRoot.wingRadius
                y: unifiedNotchRoot.targetH - unifiedNotchRoot.cornerRadius
                radiusX: Math.max(0.1, unifiedNotchRoot.cornerRadius)
                radiusY: Math.max(0.1, unifiedNotchRoot.cornerRadius)
                direction: PathArc.Counterclockwise
            }

            // 6. Dinding vertikal kanan naik ke atas
            PathLine {
                x: unifiedNotchRoot.width - unifiedNotchRoot.wingRadius
                y: unifiedNotchRoot.wingRadius
            }

            // 7. Lekukan CEKUNG sayap kanan keluar menuju garis atas
            PathCubic {
                x: unifiedNotchRoot.width
                y: 0
                control1X: unifiedNotchRoot.width - unifiedNotchRoot.wingRadius
                control1Y: unifiedNotchRoot.wingRadius * 0.45
                control2X: unifiedNotchRoot.width - (unifiedNotchRoot.wingRadius * 0.55)
                control2Y: 0
            }
        }

        // 1B. Siluet Tunggal Bodi + 1px Outline Semi-Transparan (Gambar 1 Blueprint)
        ShapePath {
            strokeColor: unifiedNotchRoot.cfgBorderColor.a > 0 ? unifiedNotchRoot.cfgBorderColor : "#2a2b36"
            strokeWidth: 1
            fillColor: unifiedNotchRoot.cfgBgColor.a > 0 ? unifiedNotchRoot.cfgBgColor : "#0b0b0f"

            // Mulai dari sayap lekukan kiri atas
            startX: 0
            startY: 0

            // 1. Lekukan CEKUNG sayap kiri (Inverted Fillet) menggunakan PathCubic
            PathCubic {
                x: unifiedNotchRoot.wingRadius
                y: unifiedNotchRoot.wingRadius
                control1X: unifiedNotchRoot.wingRadius * 0.55
                control1Y: 0
                control2X: unifiedNotchRoot.wingRadius
                control2Y: unifiedNotchRoot.wingRadius * 0.45
            }

            // 2. Dinding vertikal kiri turun ke bawah
            PathLine {
                x: unifiedNotchRoot.wingRadius
                y: unifiedNotchRoot.targetH - unifiedNotchRoot.cornerRadius
            }

            // 3. Sudut cembung kiri bawah
            PathArc {
                x: unifiedNotchRoot.wingRadius + unifiedNotchRoot.cornerRadius
                y: unifiedNotchRoot.targetH
                radiusX: Math.max(0.1, unifiedNotchRoot.cornerRadius)
                radiusY: Math.max(0.1, unifiedNotchRoot.cornerRadius)
                direction: PathArc.Counterclockwise
            }

            // 4. Garis horizontal dasar notch
            PathLine {
                x: unifiedNotchRoot.width - unifiedNotchRoot.wingRadius - unifiedNotchRoot.cornerRadius
                y: unifiedNotchRoot.targetH
            }

            // 5. Sudut cembung kanan bawah
            PathArc {
                x: unifiedNotchRoot.width - unifiedNotchRoot.wingRadius
                y: unifiedNotchRoot.targetH - unifiedNotchRoot.cornerRadius
                radiusX: Math.max(0.1, unifiedNotchRoot.cornerRadius)
                radiusY: Math.max(0.1, unifiedNotchRoot.cornerRadius)
                direction: PathArc.Counterclockwise
            }

            // 6. Dinding vertikal kanan naik ke atas
            PathLine {
                x: unifiedNotchRoot.width - unifiedNotchRoot.wingRadius
                y: unifiedNotchRoot.wingRadius
            }

            // 7. Lekukan CEKUNG sayap kanan keluar menuju garis atas
            PathCubic {
                x: unifiedNotchRoot.width
                y: 0
                control1X: unifiedNotchRoot.width - unifiedNotchRoot.wingRadius
                control1Y: unifiedNotchRoot.wingRadius * 0.45
                control2X: unifiedNotchRoot.width - (unifiedNotchRoot.wingRadius * 0.55)
                control2Y: 0
            }

            // 8. Tutup garis atas
            PathLine { x: 0; y: 0 }
        }
    }

    // --- Subtle Top Glow Edge (Hanya Aktif saat Nempel Atas / Living Notch) ---
    Rectangle {
        visible: !unifiedNotchRoot.isFloatingStyle
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: unifiedNotchRoot.targetW
        height: 2
        opacity: unifiedNotchRoot.bodyOpacity * 0.8
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
    // 2. KONTAINER KONTEN (Di-clip rapi di dalam area bodi notch)
    // ==============================================================
    Item {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: unifiedNotchRoot.targetW
        height: unifiedNotchRoot.targetH
        clip: true

        // ----------------------------------------------------------
        // 2A. MODE COMPACT (Jam / Visualizer / Lirik / Notif / Battery)
        // ----------------------------------------------------------
        Item {
            id: compactContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: unifiedNotchRoot.compactHeight

            visible: opacity > 0
            opacity: (unifiedNotchRoot.isExpanded || unifiedNotchRoot.isOverlayDialog) ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // State 1: Notification Pill
            NotificationPill {
                anchors.fill: parent
                visible: opacity > 0
                opacity: unifiedNotchRoot.activeNotificationPill ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
                appName: unifiedNotchRoot.notifAppName
                appIcon: unifiedNotchRoot.notifIcon
                summary: unifiedNotchRoot.notifSummary
                body: unifiedNotchRoot.notifBody
            }

            // State 2: Battery Pill
            BatteryPill {
                anchors.fill: parent
                visible: opacity > 0
                opacity: (!unifiedNotchRoot.activeNotificationPill && unifiedNotchRoot.activeBatteryPill) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
                isCharging: unifiedNotchRoot.batteryIsCharging
                batteryPercent: unifiedNotchRoot.sysBatteryPct
            }

            // State 3: Dynamic Lyrics Pill
            LyricsPillView {
                anchors.fill: parent
                visible: opacity > 0
                opacity: (!unifiedNotchRoot.activeNotificationPill && !unifiedNotchRoot.activeBatteryPill && unifiedNotchRoot.showPillLyrics) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
                currentLyricLine: unifiedNotchRoot.currentLyricLine
                trackTitle: unifiedNotchRoot.trackTitle
                trackArtist: unifiedNotchRoot.trackArtist
                accentColor: unifiedNotchRoot.cfgAccentColor
                fontSize: unifiedNotchRoot.cfgLyricsFontSize
                lyricsFontFamily: unifiedNotchRoot.cfgLyricsFontFamily
                lyricsFontBold: unifiedNotchRoot.cfgLyricsFontBold
                showCompactVisualizer: unifiedNotchRoot.cfgShowCompactVisualizer
                isPlaying: unifiedNotchRoot.isPlaying
            }

            // State 4: Standby View (Music Icon, Clock, Visualizer)
            StandbyView {
                anchors.fill: parent
                visible: opacity > 0
                opacity: (!unifiedNotchRoot.activeNotificationPill && !unifiedNotchRoot.activeBatteryPill && !unifiedNotchRoot.showPillLyrics) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
                isPlaying: unifiedNotchRoot.isPlaying
                currentTimeString: unifiedNotchRoot.currentTimeString
                trackTitle: unifiedNotchRoot.trackTitle
                trackArtist: unifiedNotchRoot.trackArtist
                accentColor: unifiedNotchRoot.cfgAccentColor
                fontSize: unifiedNotchRoot.cfgClockFontSize
                clockFontFamily: unifiedNotchRoot.cfgClockFontFamily
                clockFontBold: unifiedNotchRoot.cfgClockFontBold
                showVisualizer: unifiedNotchRoot.cfgShowVisualizer
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: unifiedNotchRoot.requestToggle()
            }
        }

        // ----------------------------------------------------------
        // 2B. MODE EXPANDED (Top handle + Cards area)
        // ----------------------------------------------------------
        Item {
            id: expandedContent
            anchors.fill: parent
            visible: opacity > 0
            opacity: unifiedNotchRoot.isExpanded ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: unifiedNotchRoot.isExpanded ? 200 : 80; easing.type: Easing.OutQuad }
            }

            // Clean top notch handle (mini pill grip)
            Item {
                id: topNotchHandle
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 18
                z: 10

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: unifiedNotchRoot.requestClose()
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    height: 4
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.3)
                }
            }

            // Cards Body Area - Fills notch body completely (Full-Bleed)
            Item {
                id: cardBodyContainer
                anchors.fill: parent
                clip: true

                Loader {
                    id: tabLoader
                    anchors.fill: parent
                    sourceComponent: {
                        if (!unifiedNotchRoot.isExpanded) return null;
                        switch (unifiedNotchRoot.activeTabKey) {
                            case "control": return controlCenterComponent;
                            case "media": return mediaLyricsComponent;
                            case "clipboard": return clipboardComponent;
                            case "notification": return notificationHistoryComponent;
                            default: return controlCenterComponent;
                        }
                    }
                }

                // Tab: Control Center Utama
                Component {
                    id: controlCenterComponent
                    ControlCenterCard {
                        anchors.fill: parent
                        accentColor: unifiedNotchRoot.cfgAccentColor
                        currentTimeString: unifiedNotchRoot.currentTimeString
                        currentDateString: unifiedNotchRoot.currentDateString
                        islandMode: unifiedNotchRoot.islandShapeMode
                        cpuPercent: unifiedNotchRoot.sysCpuPct
                        cpuTemp: unifiedNotchRoot.sysTemp
                        ramPercent: unifiedNotchRoot.sysRamPct
                        batteryPercent: unifiedNotchRoot.sysBatteryPct
                        batteryCharging: unifiedNotchRoot.sysBatteryCharging
                        batteryTemp: 32

                        onRequestSwitchToMedia: {
                            var mediaIdx = unifiedNotchRoot.availableTabs.indexOf("media");
                            if (mediaIdx !== -1) {
                                unifiedNotchRoot.requestSwitchTab(mediaIdx);
                            }
                        }
                    }
                }

                // Tab: Media Player & Dynamic Lyrics
                Component {
                    id: mediaLyricsComponent
                    MediaLyricsCard {
                        anchors.fill: parent
                        isFloatingStyle: unifiedNotchRoot.isFloatingStyle
                        trackTitle: unifiedNotchRoot.trackTitle
                        trackArtist: unifiedNotchRoot.trackArtist
                        trackAlbum: unifiedNotchRoot.trackAlbum
                        albumArtUrl: unifiedNotchRoot.albumArtUrl
                        trackPosition: unifiedNotchRoot.trackPosition
                        trackLength: unifiedNotchRoot.trackLength
                        isPlaying: unifiedNotchRoot.isPlaying
                        canControl: unifiedNotchRoot.canControl
                        canGoNext: unifiedNotchRoot.canGoNext
                        canGoPrevious: unifiedNotchRoot.canGoPrevious
                        accentColor: unifiedNotchRoot.cfgAccentColor
                        showLyrics: unifiedNotchRoot.showLyrics
                        lyricsList: unifiedNotchRoot.lyricsList
                        currentLyricIndex: unifiedNotchRoot.currentLyricIndex
                        lyricsLoading: unifiedNotchRoot.lyricsLoading
                        lyricsFound: unifiedNotchRoot.lyricsFound
                        activeTabIndex: unifiedNotchRoot.currentExpandedTab
                        lyricsFontFamily: unifiedNotchRoot.cfgLyricsFontFamily
                        lyricsFontSize: unifiedNotchRoot.cfgLyricsFontSize
                        lyricsFontBold: unifiedNotchRoot.cfgLyricsFontBold
                        currentTimeString: unifiedNotchRoot.currentTimeString
                        currentDateString: unifiedNotchRoot.currentDateString
                        clockFontFamily: unifiedNotchRoot.cfgClockFontFamily

                        onRequestPlayPause: unifiedNotchRoot.requestPlayPause()
                        onRequestNext: unifiedNotchRoot.requestNext()
                        onRequestPrevious: unifiedNotchRoot.requestPrevious()
                        onRequestSeek: (pos) => unifiedNotchRoot.requestSeek(pos)
                        onRequestToggleLyrics: unifiedNotchRoot.requestToggleLyrics()
                        onRequestCloseLyrics: unifiedNotchRoot.requestCloseLyrics()
                        onRequestRetryLyrics: unifiedNotchRoot.requestRetryLyrics()
                        onRequestDemoLyrics: unifiedNotchRoot.requestDemoLyrics()
                        onRequestSwitchTab: (tabIdx) => unifiedNotchRoot.requestSwitchTab(tabIdx)
                    }
                }

                // Tab: Clipboard Manager (Klipper Integration)
                Component {
                    id: clipboardComponent
                    ClipboardCard {
                        anchors.fill: parent
                        accentColor: unifiedNotchRoot.cfgAccentColor
                    }
                }

                // Tab: Notification History
                Component {
                    id: notificationHistoryComponent
                    NotificationHistoryCard {
                        anchors.fill: parent
                        accentColor: unifiedNotchRoot.cfgAccentColor
                        notificationItems: unifiedNotchRoot.notificationHistory
                        onRequestClearAll: unifiedNotchRoot.requestClearAllNotifications()
                        onRequestRemoveItem: (id) => unifiedNotchRoot.requestRemoveNotification(id)
                    }
                }
            }

            // Bottom Navigation Bar with Dots
            Item {
                id: navDotsBar
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 24
                z: 10

                // Pagination Dots
                Row {
                    id: paginationDotsRow
                    anchors.centerIn: parent
                    visible: unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isMorphing && unifiedNotchRoot.availableTabs.length > 1
                    spacing: 7

                    Repeater {
                        model: unifiedNotchRoot.availableTabs.length
                        Rectangle {
                            required property int index
                            readonly property bool isCurrent: (unifiedNotchRoot.currentExpandedTab % unifiedNotchRoot.availableTabs.length) === index
                            width: isCurrent ? 16 : 6
                            height: 6
                            radius: 3
                            color: isCurrent ? unifiedNotchRoot.cfgAccentColor : Qt.rgba(1, 1, 1, 0.25)
                            Behavior on width { NumberAnimation { duration: 200 } }
                            Behavior on color { ColorAnimation { duration: 200 } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: unifiedNotchRoot.requestSwitchTab(parent.index)
                            }
                        }
                    }
                }
            }

            // Left Arrow (<) - Floating Overlay
            Rectangle {
                id: leftNavBtn
                width: 28
                height: 28
                radius: 14
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                z: 10
                visible: unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isMorphing && unifiedNotchRoot.availableTabs.length > 1
                color: leftNavMa.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: "go-previous"
                    color: "#ffffff"
                }

                MouseArea {
                    id: leftNavMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var count = unifiedNotchRoot.availableTabs.length;
                        if (count > 0) {
                            unifiedNotchRoot.requestSwitchTab((unifiedNotchRoot.currentExpandedTab - 1 + count) % count);
                        }
                    }
                }
            }

            // Right Arrow (>) - Floating Overlay
            Rectangle {
                id: rightNavBtn
                width: 28
                height: 28
                radius: 14
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                z: 10
                visible: unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isMorphing && unifiedNotchRoot.availableTabs.length > 1
                color: rightNavMa.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: "go-next"
                    color: "#ffffff"
                }

                MouseArea {
                    id: rightNavMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var count = unifiedNotchRoot.availableTabs.length;
                        if (count > 0) {
                            unifiedNotchRoot.requestSwitchTab((unifiedNotchRoot.currentExpandedTab + 1) % count);
                        }
                    }
                }
            }
        }
    }
}
