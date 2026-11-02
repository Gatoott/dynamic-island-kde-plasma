import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import "."
import "../states"

Item {
    id: unifiedNotchRoot
    clip: true

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
        if (showMediaTab) tabs.push("media");
        if (showNotificationTab) tabs.push("notification");
        if (showControlTab) tabs.push("control");
        if (showClipboardTab) tabs.push("clipboard");
        if (tabs.length === 0) tabs.push("media");
        return tabs;
    }
    readonly property string activeTabKey: (availableTabs && availableTabs.length > 0) ? availableTabs[currentExpandedTab % availableTabs.length] : "media"

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
    property int expandedBgStyle: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.expandedBgStyle !== undefined) return plasmoid.configuration.expandedBgStyle;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.expandedBgStyle !== undefined) return Plasmoid.configuration.expandedBgStyle;
        return 0;
    }
    property int mediaCardBgMode: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.mediaCardBgMode !== undefined) return plasmoid.configuration.mediaCardBgMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.mediaCardBgMode !== undefined) return Plasmoid.configuration.mediaCardBgMode;
        return 0;
    }
    property int lyricsBgMode: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.lyricsBgMode !== undefined) return plasmoid.configuration.lyricsBgMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.lyricsBgMode !== undefined) return Plasmoid.configuration.lyricsBgMode;
        return 1;
    }

    readonly property color effectiveBgColor: {
        if (expandedBgStyle === 1) {
            return Qt.rgba(0.06, 0.06, 0.08, 0.72);
        }
        return cfgBgColor.a > 0 ? cfgBgColor : "#09090b";
    }

    readonly property color effectiveBorderColor: {
        if (expandedBgStyle === 1) {
            return Qt.rgba(1, 1, 1, 0.15);
        }
        return cfgBorderColor.a > 0 ? cfgBorderColor : Qt.rgba(1, 1, 1, 0.12);
    }

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

    // Flag pelindung transisi atomik
    property bool isClosing: false
    property bool isOpening: false

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

    // Tetapkan satu nilai tinggi & lebar tetap (Uniform Dimensions):
    readonly property real standardCardHeight: 180
    readonly property real standardCardWidth: getTargetWidthForTab(currentExpandedTab, showLyrics)
    property alias expandedContentArea: expandedContent

    // Pemetaan Dimensi Eksplisit Tiap Tab (Anti-NaN & Anti-Squish)
    function getTargetWidthForTab(tabIndex, lyricsActive) {
        if (activeTabKey === "media" && lyricsActive) {
            return 640;
        }
        return 500;
    }

    function getTargetHeightForTab(tabIndex, lyricsActive) {
        return standardCardHeight;
    }

    // Ikat targetW dan targetH secara langsung dan reaktif (Kunci targetH agar selalu sama):
    property real targetW: isExpanded ? getTargetWidthForTab(currentExpandedTab, showLyrics) : compactWidth
    property real targetH: isExpanded ? standardCardHeight : compactHeight

    width: isFloatingStyle ? targetW : (targetW + (effectiveWingRadius * 2))
    height: targetH
    opacity: 1.0

    readonly property bool isMorphing: widthAnim.running || heightAnim.running || closeSequenceAnimation.running || openSequenceAnimation.running

    Behavior on targetW {
        enabled: !unifiedNotchRoot.isClosing && !unifiedNotchRoot.isOpening
        NumberAnimation {
            id: widthAnim
            duration: 280
            easing.type: Easing.OutQuad
        }
    }
    Behavior on targetH {
        enabled: !unifiedNotchRoot.isClosing && !unifiedNotchRoot.isOpening
        NumberAnimation {
            id: heightAnim
            duration: 280
            easing.type: Easing.OutQuad
        }
    }

    // -------------------------------------------------------------
    // TRANSISI PENUTUPAN ATOMIK (Anti-Flicker & Ghost Frame Shield)
    // -------------------------------------------------------------
    ParallelAnimation {
        id: closeSequenceAnimation

        // 1. Fade out konten secara cepat (80ms)
        NumberAnimation {
            target: expandedContent
            property: "opacity"
            to: 0.0
            duration: 80
            easing.type: Easing.OutQuad
        }

        // 2. Susutkan dimensi kartu ke ukuran compactWidth & compactHeight (180ms)
        NumberAnimation {
            target: unifiedNotchRoot
            property: "targetW"
            to: unifiedNotchRoot.compactWidth
            duration: 180
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: unifiedNotchRoot
            property: "targetH"
            to: unifiedNotchRoot.compactHeight
            duration: 180
            easing.type: Easing.InOutCubic
        }

        onFinished: {
            unifiedNotchRoot.isClosing = false;
            unifiedNotchRoot.collapseCompleted();
            unifiedNotchRoot.collapseFinished();
            Qt.callLater(function() {
                expandedContent.opacity = 1.0;
            });
        }
    }

    // -------------------------------------------------------------
    // TRANSISI PEMBUKAAN ATOMIK
    // -------------------------------------------------------------
    ParallelAnimation {
        id: openSequenceAnimation

        NumberAnimation {
            target: unifiedNotchRoot
            property: "targetW"
            from: unifiedNotchRoot.compactWidth
            to: unifiedNotchRoot.getTargetWidthForTab(unifiedNotchRoot.currentExpandedTab, unifiedNotchRoot.showLyrics)
            duration: 200
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: unifiedNotchRoot
            property: "targetH"
            from: unifiedNotchRoot.compactHeight
            to: unifiedNotchRoot.standardCardHeight
            duration: 200
            easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            PauseAnimation { duration: 30 }
            NumberAnimation {
                target: expandedContent
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 170
                easing.type: Easing.OutQuad
            }
        }

        onFinished: {
            unifiedNotchRoot.isOpening = false;
            unifiedNotchRoot.targetW = Qt.binding(function() {
                return unifiedNotchRoot.isExpanded ? unifiedNotchRoot.getTargetWidthForTab(unifiedNotchRoot.currentExpandedTab, unifiedNotchRoot.showLyrics) : unifiedNotchRoot.compactWidth;
            });
            unifiedNotchRoot.targetH = Qt.binding(function() {
                return unifiedNotchRoot.isExpanded ? unifiedNotchRoot.standardCardHeight : unifiedNotchRoot.compactHeight;
            });
            expandedContent.opacity = 1.0;
        }
    }

    function startCollapse() {
        if (isClosing || !isExpanded) return;
        if (openSequenceAnimation.running) {
            openSequenceAnimation.stop();
            isOpening = false;
        }
        isClosing = true;
        closeSequenceAnimation.restart();
    }

    function startExpand() {
        if (closeSequenceAnimation.running) {
            closeSequenceAnimation.stop();
            isClosing = false;
        }
        isOpening = true;
        isClosing = false;
        bodyOpacity = 1.0;
        openSequenceAnimation.restart();
    }

    function resetGeometryAfterUnmap() {
        targetW = Qt.binding(function() {
            return unifiedNotchRoot.isExpanded ? unifiedNotchRoot.getTargetWidthForTab(unifiedNotchRoot.currentExpandedTab, unifiedNotchRoot.showLyrics) : unifiedNotchRoot.compactWidth;
        });
        targetH = Qt.binding(function() {
            return unifiedNotchRoot.isExpanded ? unifiedNotchRoot.standardCardHeight : unifiedNotchRoot.compactHeight;
        });
        expandedContent.opacity = 1.0;
        bodyOpacity = 1.0;
    }

    onIsExpandedChanged: {
        if (isExpanded) {
            if (!isOpening && !isClosing) {
                startExpand();
            }
        } else {
            if (!isClosing && !isOpening && targetH > compactHeight) {
                startCollapse();
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
        radius: (unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isClosing) ? unifiedNotchRoot.cornerRadius : (height / 2)
        Behavior on radius { NumberAnimation { duration: 200 } }
        color: unifiedNotchRoot.effectiveBgColor
        border.width: 0
        clip: true
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
        layer.enabled: visible && (unifiedNotchRoot.isExpanded || unifiedNotchRoot.isMorphing || opacity > 0)
        layer.samples: 4

        // Siluet Tunggal Bodi Notch (Tanpa border samping & bawah)
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: unifiedNotchRoot.effectiveBgColor

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
            opacity: 1.0

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
                        if (!unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isClosing) return null;
                        switch (unifiedNotchRoot.activeTabKey) {
                            case "media": return mediaLyricsComponent;
                            case "notification": return notificationHistoryComponent;
                            case "control": return controlCenterComponent;
                            case "clipboard": return clipboardComponent;
                            default: return mediaLyricsComponent;
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
                        expandedBgStyle: unifiedNotchRoot.expandedBgStyle
                        mediaCardBgMode: unifiedNotchRoot.mediaCardBgMode
                        lyricsBgMode: unifiedNotchRoot.lyricsBgMode
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
                anchors.bottomMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 20
                z: 10

                // Pagination Dots
                Row {
                    id: paginationDotsRow
                    anchors.centerIn: parent
                    visible: unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isMorphing && unifiedNotchRoot.availableTabs.length > 1 && !unifiedNotchRoot.showLyrics
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
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                z: 10
                visible: unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isMorphing && unifiedNotchRoot.availableTabs.length > 1
                color: leftNavMa.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)

                SFSymbolIcon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    name: "chevron.left"
                    strokeWidth: 1.8
                    color: leftNavMa.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.75)
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
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                z: 10
                visible: unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isMorphing && unifiedNotchRoot.availableTabs.length > 1
                color: rightNavMa.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)

                SFSymbolIcon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    name: "chevron.right"
                    strokeWidth: 1.8
                    color: rightNavMa.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.75)
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
