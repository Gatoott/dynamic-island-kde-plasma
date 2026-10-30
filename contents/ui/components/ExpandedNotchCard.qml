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
    signal collapseCompleted()
    signal collapseFinished()

    // -------------------------------------------------------------
    // Unified Geometry & Physical Shrink Dimensions (Single Silhouette)
    // -------------------------------------------------------------
    property real bodyOpacity: 1.0
    property bool isOverlayDialog: false

    readonly property real wingRadius: 14
    property real cornerRadius: isExpanded ? 22 : 18
    Behavior on cornerRadius { NumberAnimation { duration: 200 } }

    property real targetW: compactWidth
    property real targetH: compactHeight

    width: targetW + (wingRadius * 2)
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
        if (!isExpanded) {
            targetH = compactHeight;
            targetW = compactWidth;
        } else {
            unifiedNotchRoot.bodyOpacity = 1.0;
            targetH = cfgExpandedHeight;
            targetW = (currentExpandedTab === 1 && showLyrics) ? 680 : cfgExpandedWidth;
        }
    }

    onCompactWidthChanged: { if (!isExpanded) targetW = compactWidth; }
    onCompactHeightChanged: { if (!isExpanded) targetH = compactHeight; }
    onCfgExpandedWidthChanged: { if (isExpanded && (currentExpandedTab !== 1 || !showLyrics)) targetW = cfgExpandedWidth; }
    onCfgExpandedHeightChanged: { if (isExpanded) targetH = cfgExpandedHeight; }
    onCurrentExpandedTabChanged: { if (isExpanded) targetW = (currentExpandedTab === 1 && showLyrics) ? 680 : cfgExpandedWidth; }
    onShowLyricsChanged: { if (isExpanded) targetW = (currentExpandedTab === 1 && showLyrics) ? 680 : cfgExpandedWidth; }

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
    // ==============================================================
    // 1. SILUET TUNGGAL UTUH (Bodi + Sayap Kiri & Kanan - Gambar 1)
    // Satu ShapePath tertutup: Mustahil ada garis tumpuk atau undakan
    // ==============================================================
    Shape {
        id: notchSilhouette
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
                radiusX: unifiedNotchRoot.cornerRadius
                radiusY: unifiedNotchRoot.cornerRadius
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
                radiusX: unifiedNotchRoot.cornerRadius
                radiusY: unifiedNotchRoot.cornerRadius
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
                radiusX: unifiedNotchRoot.cornerRadius
                radiusY: unifiedNotchRoot.cornerRadius
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
                radiusX: unifiedNotchRoot.cornerRadius
                radiusY: unifiedNotchRoot.cornerRadius
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

    // --- Subtle Top Glow Edge (Nusa 1.1 Style) ---
    Rectangle {
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
                accentColor: unifiedNotchRoot.cfgAccentColor
                fontSize: unifiedNotchRoot.cfgClockFontSize
            }

            // State 4: Standby View (♫, Clock, Visualizer)
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

            // Cards Area
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

                Loader {
                    id: tabLoader
                    anchors.fill: parent
                    sourceComponent: {
                        if (!unifiedNotchRoot.isExpanded) return null;
                        switch (unifiedNotchRoot.currentExpandedTab) {
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
                        accentColor: unifiedNotchRoot.cfgAccentColor
                        currentTimeString: unifiedNotchRoot.currentTimeString
                        islandMode: unifiedNotchRoot.islandShapeMode
                        cpuPercent: unifiedNotchRoot.sysCpuPct
                        cpuTemp: unifiedNotchRoot.sysTemp
                        ramPercent: unifiedNotchRoot.sysRamPct
                        batteryPercent: unifiedNotchRoot.sysBatteryPct
                        batteryCharging: unifiedNotchRoot.sysBatteryCharging
                        batteryTemp: 32

                        onRequestSwitchToMedia: unifiedNotchRoot.requestSwitchTab(1)
                    }
                }

                // Tab 1: Media Player & Dynamic Lyrics
                Component {
                    id: mediaLyricsComponent
                    MediaLyricsCard {
                        anchors.fill: parent
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

                        onRequestPlayPause: unifiedNotchRoot.requestPlayPause()
                        onRequestNext: unifiedNotchRoot.requestNext()
                        onRequestPrevious: unifiedNotchRoot.requestPrevious()
                        onRequestSeek: (pos) => unifiedNotchRoot.requestSeek(pos)
                        onRequestToggleLyrics: unifiedNotchRoot.requestToggleLyrics()
                        onRequestRetryLyrics: unifiedNotchRoot.requestRetryLyrics()
                        onRequestSwitchTab: (tabIdx) => unifiedNotchRoot.requestSwitchTab(tabIdx)
                    }
                }

                // Tab 2: Clipboard Manager (Klipper Integration)
                Component {
                    id: clipboardComponent
                    ClipboardCard {
                        anchors.fill: parent
                        accentColor: unifiedNotchRoot.cfgAccentColor
                    }
                }
            }

            // Left Arrow (<)
            Rectangle {
                id: leftNavBtn
                width: 28
                height: 28
                radius: 14
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                visible: unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isMorphing
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
                        unifiedNotchRoot.requestSwitchTab((unifiedNotchRoot.currentExpandedTab - 1 + 3) % 3);
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
                visible: unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isMorphing
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
                        unifiedNotchRoot.requestSwitchTab((unifiedNotchRoot.currentExpandedTab + 1) % 3);
                    }
                }
            }

            // Pagination Dots
            Row {
                id: paginationDotsRow
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                visible: unifiedNotchRoot.isExpanded && !unifiedNotchRoot.isMorphing
                spacing: 7

                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: unifiedNotchRoot.currentExpandedTab === index ? 16 : 6
                        height: 6
                        radius: 3
                        color: unifiedNotchRoot.currentExpandedTab === index ? unifiedNotchRoot.cfgAccentColor : Qt.rgba(1, 1, 1, 0.25)
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
    }
}
