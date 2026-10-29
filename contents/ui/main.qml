import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.private.battery as Battery
import org.kde.ksysguard.sensors as Sensors
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.workspace.dbus as DBus
import "components"
import "states"

PlasmoidItem {
    id: root
    clip: false

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // --- Configurations ---
    readonly property int cfgCompactWidth: Plasmoid.configuration.compactWidth || 145
    readonly property int cfgCompactHeight: Plasmoid.configuration.compactHeight || 36
    readonly property int cfgExpandedWidth: Plasmoid.configuration.expandedWidth || 420
    readonly property int cfgExpandedHeight: Plasmoid.configuration.expandedHeight || 335
    readonly property int cfgBorderRadius: Plasmoid.configuration.borderRadius || 18
    readonly property int cfgNotchCornerRadius: Plasmoid.configuration.notchCornerRadius || 18
    readonly property int cfgVerticalOffset: Plasmoid.configuration.verticalOffset !== undefined ? Plasmoid.configuration.verticalOffset : 0
    readonly property int cfgHorizontalOffset: Plasmoid.configuration.horizontalOffset !== undefined ? Plasmoid.configuration.horizontalOffset : 0
    readonly property int cfgClockFontSize: Plasmoid.configuration.clockFontSize || 13
    readonly property string cfgIslandShapeMode: Plasmoid.configuration.islandShapeMode || "notch"
    readonly property bool cfgExpandOnHover: Plasmoid.configuration.expandOnHover || false
    readonly property bool cfgShowVisualizer: Plasmoid.configuration.showVisualizer !== undefined ? Plasmoid.configuration.showVisualizer : true
    readonly property int cfgNotificationDuration: Plasmoid.configuration.notificationDuration || 4500

    readonly property color cfgBgColor: {
        var c = Plasmoid.configuration.backgroundColor;
        var op = (Plasmoid.configuration.backgroundOpacity !== undefined) ? Plasmoid.configuration.backgroundOpacity : 0.95;
        var parsed = Qt.color(c || "#0d0f12");
        return Qt.rgba(parsed.r, parsed.g, parsed.b, op);
    }
    readonly property color cfgBorderColor: Qt.color(Plasmoid.configuration.borderColor || "#33ffffff")
    readonly property color cfgAccentColor: Qt.color(Plasmoid.configuration.accentColor || "#3daee9")

    // --- Expansion & Morphing State (SINGLE CONTAINER) ---
    property bool isExpanded: false
    property int currentExpandedTab: 0 // 0 = Control Center, 1 = Media Player & Lyrics, 2 = Clipboard
    property int savedPanelHeight: 46

    readonly property bool showPillLyrics: root.showLyrics && root.isPlaying && root.currentLyricLine !== ""

    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge)

    readonly property int currentCompactWidth: {
        if (root.activeNotificationPill) return 340;
        if (root.activeBatteryPill) return 210;
        if (root.showPillLyrics) {
            return Math.max(root.cfgCompactWidth, Math.min(500, pillLyricsMetrics.advanceWidth + 70));
        }
        return root.isPlaying ? root.cfgCompactWidth + 30 : root.cfgCompactWidth;
    }

    preferredRepresentation: compactRepresentation
    Layout.preferredWidth: (!root.inPanel) ? desktopLivingNotch.width : compactPill.width
    Layout.preferredHeight: (!root.inPanel) ? desktopLivingNotch.height : root.cfgCompactHeight
    Layout.minimumWidth: 100
    Layout.maximumHeight: root.inPanel ? root.cfgCompactHeight : 10000
    implicitWidth: (!root.inPanel) ? desktopLivingNotch.width : compactPill.width
    implicitHeight: (!root.inPanel) ? desktopLivingNotch.height : root.cfgCompactHeight

    TextMetrics {
        id: pillLyricsMetrics
        font.pixelSize: root.cfgClockFontSize
        font.weight: Font.DemiBold
        font.family: "Inter, Roboto, sans-serif"
        text: root.currentLyricLine
    }

    // --- Clock & Date ---
    property string currentTimeString: "00:00"
    property string currentDateString: "Sat 18 Oct"

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            root.currentTimeString = Qt.formatTime(now, "hh:mm");
            root.currentDateString = Qt.formatDate(now, "ddd d MMM");
        }
    }

    // --- MPRIS Media Integration ---
    Mpris.Mpris2Model {
        id: mprisModel
    }

    readonly property var activePlayer: mprisModel.currentPlayer
    readonly property bool isPlaying: activePlayer ? (activePlayer.playbackStatus === Mpris.PlaybackStatus.Playing) : false
    readonly property string trackTitle: activePlayer ? (activePlayer.track || "") : ""
    readonly property string trackArtist: activePlayer ? (activePlayer.artist || "") : ""
    readonly property string trackAlbum: activePlayer ? (activePlayer.album || "") : ""
    readonly property string albumArtUrl: activePlayer ? (activePlayer.artUrl || "") : ""
    readonly property real trackPosition: activePlayer ? (activePlayer.position / 1000000.0) : 0
    readonly property real trackLength: activePlayer ? (activePlayer.length / 1000000.0) : 0
    readonly property bool canControl: activePlayer ? activePlayer.canControl : false
    readonly property bool canGoNext: activePlayer ? activePlayer.canGoNext : false
    readonly property bool canGoPrevious: activePlayer ? activePlayer.canGoPrevious : false

    function playPause() {
        if (activePlayer) activePlayer.PlayPause();
    }
    function nextTrack() {
        if (activePlayer) activePlayer.Next();
    }
    function previousTrack() {
        if (activePlayer) activePlayer.Previous();
    }
    function seekTrack(posSeconds) {
        if (activePlayer && activePlayer.canSeek) {
            var currentPosSec = activePlayer.position / 1000000.0;
            var offsetSec = posSeconds - currentPosSec;
            activePlayer.Seek(Math.round(offsetSec * 1000000));
        }
    }

    // --- LRCLIB Synced Lyrics Engine (Universal & Fail-safe) ---
    property bool showLyrics: false
    property var lyricsList: []
    property int currentLyricIndex: -1
    property string currentLyricLine: ""
    property bool lyricsLoading: false
    property bool lyricsFound: false
    property string lastFetchedKey: ""

    onTrackTitleChanged: {
        currentLyricIndex = -1;
        currentLyricLine = "";
        lyricsList = [];
        lyricsFound = false;
        if (trackTitle && trackTitle.length > 0) {
            fetchLyrics(true);
        }
    }

    onShowLyricsChanged: {
        if (showLyrics && (!lyricsList || lyricsList.length === 0)) {
            fetchLyrics(true);
        }
    }

    onTrackPositionChanged: {
        if (!lyricsList || lyricsList.length === 0) return;
        var pos = trackPosition;
        var idx = -1;
        for (var i = 0; i < lyricsList.length; i++) {
            if (lyricsList[i].time <= pos) {
                idx = i;
            } else {
                break;
            }
        }
        if (idx !== currentLyricIndex) {
            currentLyricIndex = idx;
            currentLyricLine = (idx >= 0 && idx < lyricsList.length) ? lyricsList[idx].text : "";
        }
    }

    function cleanTrackTitle(title) {
        if (!title) return "";
        return title
            .replace(/\s*[\(\[\{](official|audio|video|lyric|remaster|deluxe|version|feat|ft\.)[^\)\]\}]*[\)\]\}]/gi, "")
            .replace(/\s*-\s*(official|audio|video|lyric|remaster|deluxe|version).*$/gi, "")
            .trim();
    }

    function parseLrc(lrcText) {
        if (!lrcText) return [];
        var lines = lrcText.split("\n");
        var result = [];
        var timeRegex = /\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (!line) continue;

            timeRegex.lastIndex = 0;
            var timestamps = [];
            var match;
            while ((match = timeRegex.exec(line)) !== null) {
                var min = parseInt(match[1], 10);
                var sec = parseInt(match[2], 10);
                var ms = 0;
                if (match[3]) {
                    var msStr = match[3];
                    if (msStr.length === 1) ms = parseInt(msStr, 10) * 100;
                    else if (msStr.length === 2) ms = parseInt(msStr, 10) * 10;
                    else ms = parseInt(msStr, 10);
                }
                timestamps.push(min * 60 + sec + ms / 1000.0);
            }

            if (timestamps.length > 0) {
                var text = line.replace(/\[\d{1,2}:\d{2}(?:\.\d{1,3})?\]/g, "").trim();
                for (var t = 0; t < timestamps.length; t++) {
                    result.push({ time: timestamps[t], text: text });
                }
            }
        }
        result.sort(function(a, b) { return a.time - b.time; });
        return result;
    }

    function fetchLyrics(force) {
        if (!trackTitle || trackTitle.trim() === "") return;
        var cleanTitle = cleanTrackTitle(trackTitle);
        var artist = trackArtist ? trackArtist.trim() : "";

        if ((!artist || artist === "Brave" || artist === "Chromium") && cleanTitle.indexOf(" - ") !== -1) {
            var parts = cleanTitle.split(" - ");
            artist = parts[0].trim();
            cleanTitle = cleanTrackTitle(parts[1]);
        }

        var key = cleanTitle + "___" + artist;
        if (!force && key === lastFetchedKey && lyricsList.length > 0) return;

        lastFetchedKey = key;
        lyricsLoading = true;
        lyricsFound = false;

        var url = "https://lrclib.net/api/get?track_name=" + encodeURIComponent(cleanTitle) +
                  "&artist_name=" + encodeURIComponent(artist);
        if (trackAlbum && trackAlbum.length > 0) url += "&album_name=" + encodeURIComponent(trackAlbum);
        if (trackLength > 0) url += "&duration=" + Math.round(trackLength);

        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", "PlasmaDynamicIsland/1.0");
        xhr.timeout = 7000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        if (data.syncedLyrics && data.syncedLyrics.length > 0) {
                            var parsed = root.parseLrc(data.syncedLyrics);
                            if (parsed.length > 0) {
                                root.lyricsList = parsed;
                                root.lyricsFound = true;
                                root.lyricsLoading = false;
                                return;
                            }
                        } else if (data.plainLyrics) {
                            var pLines = data.plainLyrics.split("\n");
                            var plainParsed = [];
                            for (var k = 0; k < pLines.length; k++) {
                                if (pLines[k].trim()) plainParsed.push({ time: k * 3.5, text: pLines[k].trim() });
                            }
                            if (plainParsed.length > 0) {
                                root.lyricsList = plainParsed;
                                root.lyricsFound = true;
                                root.lyricsLoading = false;
                                return;
                            }
                        }
                    } catch (e) {
                        console.error("LRCLIB parse error:", e);
                    }
                }
                fallbackSearchLyrics(cleanTitle, artist);
            }
        };
        xhr.ontimeout = function() {
            fallbackSearchLyrics(cleanTitle, artist);
        };
        xhr.send();
    }

    function fallbackSearchLyrics(cleanTitle, artist) {
        var query = cleanTitle;
        if (artist && artist !== "Brave" && artist !== "Chromium") query += " " + artist;
        var searchUrl = "https://lrclib.net/api/search?q=" + encodeURIComponent(query);

        var xhr = new XMLHttpRequest();
        xhr.open("GET", searchUrl);
        xhr.setRequestHeader("User-Agent", "PlasmaDynamicIsland/1.0");
        xhr.timeout = 7000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.lyricsLoading = false;
                if (xhr.status === 200) {
                    try {
                        var items = JSON.parse(xhr.responseText);
                        if (Array.isArray(items) && items.length > 0) {
                            for (var i = 0; i < items.length; i++) {
                                if (items[i].syncedLyrics && items[i].syncedLyrics.length > 0) {
                                    var parsed = root.parseLrc(items[i].syncedLyrics);
                                    if (parsed.length > 0) {
                                        root.lyricsList = parsed;
                                        root.lyricsFound = true;
                                        return;
                                    }
                                }
                            }
                            if (items[0].plainLyrics) {
                                var pLines = items[0].plainLyrics.split("\n");
                                var plainParsed = [];
                                for (var k = 0; k < pLines.length; k++) {
                                    if (pLines[k].trim()) plainParsed.push({ time: k * 3.5, text: pLines[k].trim() });
                                }
                                root.lyricsList = plainParsed;
                                root.lyricsFound = true;
                                return;
                            }
                        }
                    } catch (e) {
                        console.error("Fallback search parse error:", e);
                    }
                }
                root.lyricsFound = false;
            }
        };
        xhr.send();
    }

    // --- Native KDE Plasma 6 System Sensors ---
    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: 2000
    }
    Sensors.Sensor {
        id: ramSensor
        sensorId: "memory/physical/usedPercent"
        updateRateLimit: 2000
    }
    Sensors.Sensor {
        id: tempSensor
        sensorId: "cpu/all/averageTemperature"
        updateRateLimit: 2000
    }

    readonly property int sysCpuPct: (typeof cpuSensor !== "undefined" && cpuSensor.value !== undefined && !isNaN(cpuSensor.value)) ? Math.round(cpuSensor.value) : 12
    readonly property int sysRamPct: (typeof ramSensor !== "undefined" && ramSensor.value !== undefined && !isNaN(ramSensor.value)) ? Math.round(ramSensor.value) : 42
    readonly property int sysTemp: (typeof tempSensor !== "undefined" && tempSensor.value !== undefined && !isNaN(tempSensor.value)) ? Math.round(tempSensor.value) : 40
    property int sysBatteryPct: 100
    property bool sysBatteryCharging: false

    // --- Battery & Power Monitor ---
    property bool activeBatteryPill: false
    property bool batteryIsCharging: false
    property int lastPluggedInState: -1

    Timer {
        id: batteryDismissTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.activeBatteryPill = false;
        }
    }

    Battery.BatteryControlModel {
        id: batteryModel

        onPluggedInChanged: {
            if (root.lastPluggedInState === -1) {
                root.lastPluggedInState = batteryModel.pluggedIn ? 1 : 0;
                root.sysBatteryCharging = batteryModel.pluggedIn;
                return;
            }
            var current = batteryModel.pluggedIn ? 1 : 0;
            if (current !== root.lastPluggedInState) {
                root.lastPluggedInState = current;
                root.batteryIsCharging = batteryModel.pluggedIn;
                root.sysBatteryCharging = batteryModel.pluggedIn;
                if (!root.isExpanded) {
                    root.activeBatteryPill = true;
                    batteryDismissTimer.restart();
                }
            }
        }
    }

    // --- Global Notifications Monitor (WatchedNotificationsModel) ---
    property bool activeNotificationPill: false
    property string notifAppName: ""
    property string notifSummary: ""
    property string notifBody: ""
    property string notifIcon: ""

    Timer {
        id: notifDismissTimer
        interval: root.cfgNotificationDuration
        repeat: false
        onTriggered: {
            root.activeNotificationPill = false;
        }
    }

    NotificationManager.WatchedNotificationsModel {
        id: watchedNotifications

        onRowsInserted: (parent, first, last) => {
            if (root.isExpanded) return;
            try {
                var idx = watchedNotifications.index(last, 0);
                var summary = "";
                var body = "";
                var app = "";
                var icon = "";

                var roles = watchedNotifications.roleNames();
                for (var key in roles) {
                    var rName = roles[key];
                    var roleNum = Number(key);
                    if (rName === "summary") summary = watchedNotifications.data(idx, roleNum) || "";
                    else if (rName === "body") body = watchedNotifications.data(idx, roleNum) || "";
                    else if (rName === "applicationName") app = watchedNotifications.data(idx, roleNum) || "";
                    else if (rName === "applicationIconName" || rName === "iconName") icon = watchedNotifications.data(idx, roleNum) || "";
                }

                if (summary !== "" || body !== "") {
                    root.notifAppName = app;
                    root.notifSummary = summary;
                    root.notifBody = body;
                    root.notifIcon = icon || "preferences-desktop-notification";
                    root.activeNotificationPill = true;
                    notifDismissTimer.restart();
                }
            } catch (e) {
                console.log("Error processing notification:", e);
            }
        }
    }

    // --- State Machine for Fluid Spring Animations & Overlay Canvas ---
    property bool dialogVisible: false
    property bool notchExpanding: false

    Timer {
        id: expandSpringTimer
        interval: 16
        repeat: false
        onTriggered: {
            root.notchExpanding = true;
        }
    }

    Timer {
        id: collapseTimer
        interval: 360
        repeat: false
        onTriggered: {
            root.dialogVisible = false;
            root.isExpanded = false;
        }
    }

    function expandNotch() {
        root.activeNotificationPill = false;
        root.activeBatteryPill = false;
        if (root.inPanel) {
            collapseTimer.stop();
            root.dialogVisible = true;
            root.isExpanded = true;
            expandSpringTimer.restart();
        } else {
            root.isExpanded = true;
            root.notchExpanding = true;
        }
    }

    function collapseNotch() {
        if (root.inPanel) {
            expandSpringTimer.stop();
            root.notchExpanding = false;
            collapseTimer.restart();
        } else {
            root.isExpanded = false;
            root.notchExpanding = false;
        }
    }

    function toggleExpanded() {
        if (!root.isExpanded) {
            expandNotch();
        } else {
            collapseNotch();
        }
    }

    // ==============================================================
    // 1. IN-PANEL COMPACT PILL (Trigger & Standby Indicator)
    // Berada di dalam containment panel KDE
    // ==============================================================
    Rectangle {
        id: compactPill
        clip: true

        visible: root.inPanel
        width: root.currentCompactWidth
        height: root.cfgCompactHeight

        anchors.top: parent.top
        anchors.topMargin: root.cfgVerticalOffset
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.cfgHorizontalOffset

        color: root.cfgBgColor
        border.color: root.cfgBorderColor
        border.width: 1

        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: (root.isExpanded && root.inPanel) ? 0 : 16
        bottomRightRadius: (root.isExpanded && root.inPanel) ? 0 : 16
        Behavior on bottomLeftRadius { NumberAnimation { duration: 180 } }
        Behavior on bottomRightRadius { NumberAnimation { duration: 180 } }

        Behavior on width {
            NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.25 }
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

        // Compact State Contents
        Item {
            id: compactState
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.cfgCompactHeight

            visible: opacity > 0
            opacity: (root.isExpanded && root.inPanel) ? 0.3 : 1.0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            // State 1: Notification Pill
            NotificationPill {
                anchors.fill: parent
                visible: opacity > 0
                opacity: root.activeNotificationPill ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                appName: root.notifAppName
                appIcon: root.notifIcon
                summary: root.notifSummary
                body: root.notifBody
            }

            // State 2: Battery Pill
            BatteryPill {
                anchors.fill: parent
                visible: opacity > 0
                opacity: (!root.activeNotificationPill && root.activeBatteryPill) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                isCharging: root.batteryIsCharging
                batteryPercent: root.sysBatteryPct
            }

            // State 3: Dynamic Lyrics Pill
            LyricsPillView {
                anchors.fill: parent
                visible: opacity > 0
                opacity: (!root.activeNotificationPill && !root.activeBatteryPill && root.showPillLyrics) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                currentLyricLine: root.currentLyricLine
                accentColor: root.cfgAccentColor
                fontSize: root.cfgClockFontSize
            }

            // State 4: Standby View
            StandbyView {
                anchors.fill: parent
                visible: opacity > 0
                opacity: (!root.activeNotificationPill && !root.activeBatteryPill && !root.showPillLyrics) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                isPlaying: root.isPlaying
                currentTimeString: root.currentTimeString
                trackTitle: root.trackTitle
                trackArtist: root.trackArtist
                accentColor: root.cfgAccentColor
                fontSize: root.cfgClockFontSize
                showVisualizer: root.cfgShowVisualizer
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: {
                    root.toggleExpanded();
                }

                onEntered: {
                    if (root.cfgExpandOnHover) {
                        root.toggleExpanded();
                    }
                }
            }
        }
    }

    // ==============================================================
    // 2. PANEL EXPANDED DIALOG (Transparent Fixed-Canvas Overlay)
    // Ukuran window dialog statis (720x420) dengan NoBackground (tanpa frame & shadow)
    // livingNotch di dalamnya yang melar elastis via Easing.OutBack (60 FPS)
    // ==============================================================
    PlasmaCore.Dialog {
        id: expandedDialog
        visualParent: compactPill
        location: Plasmoid.location
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
        backgroundHints: PlasmaCore.Types.NoBackground
        hideOnWindowDeactivate: true
        visible: root.dialogVisible && root.inPanel

        onVisibleChanged: {
            if (!visible && root.isExpanded && root.inPanel) {
                root.collapseNotch();
            }
        }

        mainItem: Item {
            id: fixedCanvas
            implicitWidth: 720
            implicitHeight: 420
            width: 720
            height: 420

            // Klik di area kanvas transparan di luar livingNotch untuk menutup
            MouseArea {
                anchors.fill: parent
                onClicked: root.collapseNotch()
            }

            ExpandedNotchCard {
                id: expandedCardPanel
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                compactWidth: root.currentCompactWidth
                compactHeight: root.cfgCompactHeight
                isExpanded: root.notchExpanding

                cfgAccentColor: root.cfgAccentColor
                cfgBgColor: root.cfgBgColor
                cfgBorderColor: root.cfgBorderColor
                cfgExpandedWidth: root.cfgExpandedWidth
                cfgExpandedHeight: root.cfgExpandedHeight
                currentExpandedTab: root.currentExpandedTab
                showLyrics: root.showLyrics
                currentTimeString: root.currentTimeString
                islandShapeMode: root.cfgIslandShapeMode

                sysCpuPct: root.sysCpuPct
                sysTemp: root.sysTemp
                sysRamPct: root.sysRamPct
                sysBatteryPct: root.sysBatteryPct
                sysBatteryCharging: root.sysBatteryCharging

                trackTitle: root.trackTitle
                trackArtist: root.trackArtist
                trackAlbum: root.trackAlbum
                albumArtUrl: root.albumArtUrl
                trackPosition: root.trackPosition
                trackLength: root.trackLength
                isPlaying: root.isPlaying
                canControl: root.canControl
                canGoNext: root.canGoNext
                canGoPrevious: root.canGoPrevious
                lyricsList: root.lyricsList
                currentLyricIndex: root.currentLyricIndex
                lyricsLoading: root.lyricsLoading
                lyricsFound: root.lyricsFound

                onRequestToggle: root.toggleExpanded()
                onRequestClose: root.collapseNotch()
                onRequestSwitchTab: (tabIdx) => root.currentExpandedTab = tabIdx
                onRequestPlayPause: root.playPause()
                onRequestNext: root.nextTrack()
                onRequestPrevious: root.previousTrack()
                onRequestSeek: (pos) => root.seekTrack(pos)
                onRequestToggleLyrics: {
                    root.showLyrics = !root.showLyrics;
                    if (root.showLyrics && (!root.lyricsList || root.lyricsList.length === 0)) {
                        root.fetchLyrics(true);
                    }
                }
                onRequestRetryLyrics: root.fetchLyrics(true)
            }
        }
    }

    // ==============================================================
    // 3. DESKTOP / STANDALONE LIVING NOTCH
    // Digunakan saat widget berada di Desktop atau plasmoidviewer
    // Satu kontainer tunggal yang morphing elastis secara langsung
    // ==============================================================
    ExpandedNotchCard {
        id: desktopLivingNotch
        visible: !root.inPanel
        anchors.top: parent.top
        anchors.topMargin: root.cfgVerticalOffset
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.cfgHorizontalOffset

        compactWidth: root.currentCompactWidth
        compactHeight: root.cfgCompactHeight
        isExpanded: root.isExpanded

        cfgAccentColor: root.cfgAccentColor
        cfgBgColor: root.cfgBgColor
        cfgBorderColor: root.cfgBorderColor
        cfgExpandedWidth: root.cfgExpandedWidth
        cfgExpandedHeight: root.cfgExpandedHeight
        currentExpandedTab: root.currentExpandedTab
        showLyrics: root.showLyrics
        currentTimeString: root.currentTimeString
        islandShapeMode: root.cfgIslandShapeMode

        // Compact state bindings
        activeNotificationPill: root.activeNotificationPill
        notifAppName: root.notifAppName
        notifIcon: root.notifIcon
        notifSummary: root.notifSummary
        notifBody: root.notifBody
        activeBatteryPill: root.activeBatteryPill
        batteryIsCharging: root.batteryIsCharging
        showPillLyrics: root.showPillLyrics
        currentLyricLine: root.currentLyricLine
        cfgClockFontSize: root.cfgClockFontSize
        cfgShowVisualizer: root.cfgShowVisualizer

        sysCpuPct: root.sysCpuPct
        sysTemp: root.sysTemp
        sysRamPct: root.sysRamPct
        sysBatteryPct: root.sysBatteryPct
        sysBatteryCharging: root.sysBatteryCharging

        trackTitle: root.trackTitle
        trackArtist: root.trackArtist
        trackAlbum: root.trackAlbum
        albumArtUrl: root.albumArtUrl
        trackPosition: root.trackPosition
        trackLength: root.trackLength
        isPlaying: root.isPlaying
        canControl: root.canControl
        canGoNext: root.canGoNext
        canGoPrevious: root.canGoPrevious
        lyricsList: root.lyricsList
        currentLyricIndex: root.currentLyricIndex
        lyricsLoading: root.lyricsLoading
        lyricsFound: root.lyricsFound

        onRequestToggle: root.toggleExpanded()
        onRequestClose: root.collapseNotch()
        onRequestSwitchTab: (tabIdx) => root.currentExpandedTab = tabIdx
        onRequestPlayPause: root.playPause()
        onRequestNext: root.nextTrack()
        onRequestPrevious: root.previousTrack()
        onRequestSeek: (pos) => root.seekTrack(pos)
        onRequestToggleLyrics: {
            root.showLyrics = !root.showLyrics;
            if (root.showLyrics && (!root.lyricsList || root.lyricsList.length === 0)) {
                root.fetchLyrics(true);
            }
        }
        onRequestRetryLyrics: root.fetchLyrics(true)
    }
}

