import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Shapes
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
    readonly property int cfgCompactWidth: Plasmoid.configuration.compactWidth || 180
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
    readonly property int cfgNotificationDuration: Plasmoid.configuration.notificationDuration || 4000
    readonly property bool cfgShowControlTab: Plasmoid.configuration.showControlTab !== undefined ? Plasmoid.configuration.showControlTab : true
    readonly property bool cfgShowMediaTab: Plasmoid.configuration.showMediaTab !== undefined ? Plasmoid.configuration.showMediaTab : true
    readonly property bool cfgShowClipboardTab: Plasmoid.configuration.showClipboardTab !== undefined ? Plasmoid.configuration.showClipboardTab : true
    readonly property bool cfgShowNotificationTab: Plasmoid.configuration.showNotificationTab !== undefined ? Plasmoid.configuration.showNotificationTab : true
    readonly property string cfgClockFontFamily: {
        var f = Plasmoid.configuration.clockFontFamily;
        return (f && f !== "Default (Inter/Roboto)") ? f : "";
    }
    readonly property bool cfgClockFontBold: Plasmoid.configuration.clockFontBold !== undefined ? Plasmoid.configuration.clockFontBold : true
    readonly property string cfgLyricsFontFamily: {
        var f = Plasmoid.configuration.lyricsFontFamily;
        return (f && f !== "Default (Inter/Roboto)") ? f : "";
    }
    readonly property int cfgLyricsFontSize: Plasmoid.configuration.lyricsFontSize || 13
    readonly property bool cfgLyricsFontBold: Plasmoid.configuration.lyricsFontBold !== undefined ? Plasmoid.configuration.lyricsFontBold : true
    readonly property bool cfgShowCompactVisualizer: Plasmoid.configuration.showCompactVisualizer !== undefined ? Plasmoid.configuration.showCompactVisualizer : false

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

    readonly property bool showPillLyrics: root.showLyrics && root.isPlaying

    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge)

    TextMetrics {
        id: notifMetrics
        font.pixelSize: 12
        font.weight: Font.Bold
        font.family: "Inter, Roboto, sans-serif"
        text: root.notifSummary.length > 0 ? root.notifSummary : (root.notifAppName.length > 0 ? root.notifAppName : "Notification")
    }

    readonly property int currentCompactWidth: {
        if (root.activeNotificationPill) {
            return Math.max(220, Math.min(380, notifMetrics.advanceWidth + 64));
        }
        if (root.activeBatteryPill) return 210;
        if (root.showPillLyrics) {
            // Tight auto-width hugging: 14 (music icon) + 8 (spacing) + text + (miniVisualizer 22 if active) + 24 (left 12 + right 12)
            var iconW = 14;
            var gap = 8;
            var visW = root.cfgShowCompactVisualizer ? 22 : 0;
            var textW = Math.ceil(pillLyricsMetrics.advanceWidth);
            var padding = 24;
            var totalW = iconW + gap + textW + visW + padding;
            return Math.max(160, Math.min(540, totalW));
        }
        return root.isPlaying ? root.cfgCompactWidth + 30 : root.cfgCompactWidth;
    }

    readonly property int currentNotchWidth: {
        if (!root.isExpanded) {
            return root.currentCompactWidth;
        }
        if (root.currentExpandedTab === 1 && root.showLyrics) {
            return 640;
        }
        return root.cfgExpandedWidth;
    }

    preferredRepresentation: compactRepresentation
    Layout.preferredWidth: (!root.inPanel) ? desktopLivingNotch.width : (root.currentCompactWidth + 32)
    Layout.preferredHeight: (!root.inPanel) ? desktopLivingNotch.height : root.cfgCompactHeight
    Layout.minimumWidth: 100
    Layout.maximumHeight: root.inPanel ? root.cfgCompactHeight : 10000
    implicitWidth: (!root.inPanel) ? desktopLivingNotch.width : (root.currentCompactWidth + 32)
    implicitHeight: (!root.inPanel) ? desktopLivingNotch.height : root.cfgCompactHeight

    TextMetrics {
        id: pillLyricsMetrics
        font.pixelSize: root.cfgLyricsFontSize
        font.bold: root.cfgLyricsFontBold
        font.family: root.cfgLyricsFontFamily !== "" ? root.cfgLyricsFontFamily : "Inter, Roboto, sans-serif"
        text: root.currentLyricLine !== "" ? root.currentLyricLine : (root.trackTitle !== "" ? root.trackTitle : "...")
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
            root.lastSyncPosition = posSeconds;
            root.lastSyncTimestamp = Date.now();
            root.estimatedTrackPosition = posSeconds;
            root.updateLyricProgress(posSeconds);
        }
    }

    // --- LRCLIB Synced Lyrics Engine (Universal & Continuous 100ms Precision) ---
    property bool showLyrics: false
    property var lyricsList: []
    property int currentLyricIndex: -1
    property string currentLyricLine: ""
    property bool lyricsLoading: false
    property bool lyricsFound: false
    property string lastFetchedKey: ""

    property real lastSyncPosition: 0
    property double lastSyncTimestamp: 0
    property real estimatedTrackPosition: 0

    Timer {
        id: lyricsSyncTimer
        interval: 100
        repeat: true
        running: root.isPlaying
        onTriggered: {
            if (!root.isPlaying) return;
            var elapsedSec = (Date.now() - root.lastSyncTimestamp) / 1000.0;
            var estPos = root.lastSyncPosition + elapsedSec;
            if (root.trackLength > 0 && estPos > root.trackLength) {
                estPos = root.trackLength;
            }
            root.estimatedTrackPosition = estPos;
            root.updateLyricProgress(estPos);
        }
    }

    onTrackTitleChanged: {
        currentLyricIndex = -1;
        currentLyricLine = "";
        lyricsList = [];
        lyricsFound = false;
        lastSyncPosition = 0;
        lastSyncTimestamp = Date.now();
        estimatedTrackPosition = 0;
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
        lastSyncPosition = trackPosition;
        lastSyncTimestamp = Date.now();
        estimatedTrackPosition = trackPosition;
        updateLyricProgress(trackPosition);
    }

    onIsPlayingChanged: {
        lastSyncPosition = trackPosition;
        lastSyncTimestamp = Date.now();
        estimatedTrackPosition = trackPosition;
        if (isPlaying) {
            lyricsSyncTimer.restart();
        }
        updateLyricProgress(trackPosition);
    }

    function updateLyricProgress(pos) {
        if (!lyricsList || lyricsList.length === 0) return;
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

    // --- Global Notifications Monitor (WatchedNotificationsModel & Session History) ---
    property bool activeNotificationPill: false
    property string notifAppName: ""
    property string notifSummary: ""
    property string notifBody: ""
    property string notifIcon: ""
    property var notificationHistory: []

    Timer {
        id: notifDismissTimer
        interval: 4000
        repeat: false
        onTriggered: {
            root.activeNotificationPill = false;
        }
    }

    function addNotification(app, summary, body, icon) {
        var now = new Date();
        var timeStr = Qt.formatTime(now, "hh:mm");
        var item = {
            id: Date.now() + "_" + Math.floor(Math.random() * 10000),
            appName: app || "System",
            app: app || "System",
            summary: summary || (app || "Notification"),
            body: body || "",
            icon: icon || "preferences-desktop-notification",
            time: timeStr
        };
        var list = root.notificationHistory.slice(0);
        list.unshift(item);
        if (list.length > 40) list = list.slice(0, 40);
        root.notificationHistory = list;

        // Trigger compact notification pill (title only)
        root.notifAppName = app || "";
        root.notifSummary = summary || (app || "Notification");
        root.notifBody = body || "";
        root.notifIcon = icon || "preferences-desktop-notification";

        if (!root.isExpanded) {
            root.activeNotificationPill = true;
            notifDismissTimer.interval = 4000;
            notifDismissTimer.restart();
        }
    }

    function removeNotification(notifId) {
        var list = root.notificationHistory.filter(function(item) {
            return item.id !== notifId;
        });
        root.notificationHistory = list;
    }

    function clearAllNotifications() {
        root.notificationHistory = [];
    }

    NotificationManager.WatchedNotificationsModel {
        id: watchedNotifications

        onRowsInserted: (parent, first, last) => {
            for (var r = first; r <= last; r++) {
                try {
                    var idx = watchedNotifications.index(r, 0);
                    var summary = watchedNotifications.data(idx, 0) || "";
                    var body = watchedNotifications.data(idx, 266) || "";
                    var app = watchedNotifications.data(idx, 270) || "";
                    var appIcon = watchedNotifications.data(idx, 271) || watchedNotifications.data(idx, 267) || "";

                    if (summary !== "" || body !== "" || app !== "") {
                        root.addNotification(app, summary, body, appIcon);
                    }
                } catch (e) {
                    console.log("Error processing notification row:", e);
                }
            }
        }
    }

    // --- Independent Window Surface State (NON-REACTIVE TO isExpanded) ---
    property bool dialogSurfaceOpen: false

    // Timer Fallback Penutupan Dialog (Mencegah Deadlock):
    Timer {
        id: closeWatchdogTimer
        interval: 380 // Sedikit lebih lama dari durasi animasi 280ms
        repeat: false
        onTriggered: {
            if (!root.isExpanded) {
                console.log("[NOTCH] Watchdog: Memastikan dialog tertutup dan notch panel aktif");
                root.dialogSurfaceOpen = false;
            }
        }
    }

    function openNotch() {
        if (closeWatchdogTimer.running) {
            closeWatchdogTimer.stop();
        }
        root.activeNotificationPill = false;
        root.activeBatteryPill = false;
        if (root.inPanel) {
            root.dialogSurfaceOpen = true; // Munculkan kanvas transparan terlebih dahulu
            root.isExpanded = true;        // Baru picu animasi melar targetH & targetW ke bawah
        } else {
            root.isExpanded = true;
        }
    }

    function expandNotch() {
        openNotch();
    }

    function collapseNotch() {
        triggerCollapseSequence();
    }

    function triggerCollapseSequence() {
        if (!root.isExpanded) return;

        console.log("[NOTCH] T=0ms: Mulai animasi ciut fisik...");
        root.isExpanded = false; // Memicu targetH -> compactHeight (36)
        closeWatchdogTimer.restart(); // Jalankan timer pengaman anti-deadlock
    }

    function toggleExpanded() {
        if (!root.isExpanded) {
            openNotch();
        } else {
            triggerCollapseSequence();
        }
    }

    // ==============================================================
    // 1. IN-PANEL COMPACT NOTCH (Single Unified Contour Pill)
    // Berada di dalam containment panel KDE
    // ==============================================================
    Item {
        id: panelNotchContainer
        visible: root.inPanel && !root.isExpanded
        width: panelCompactNotch.width
        height: root.cfgCompactHeight

        anchors.top: parent.top
        anchors.topMargin: root.cfgVerticalOffset
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.cfgHorizontalOffset

        opacity: root.isExpanded ? 0.0 : 1.0
        enabled: !root.isExpanded

        CompactView {
            id: panelCompactNotch
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            notchW: root.currentCompactWidth
            notchH: root.cfgCompactHeight
            wingR: 14
            cornerR: 18

            cfgAccentColor: root.cfgAccentColor
            cfgBgColor: root.cfgBgColor
            cfgBorderColor: root.cfgBorderColor
            cfgClockFontSize: root.cfgClockFontSize
            cfgClockFontFamily: root.cfgClockFontFamily
            cfgClockFontBold: root.cfgClockFontBold
            cfgLyricsFontFamily: root.cfgLyricsFontFamily
            cfgLyricsFontSize: root.cfgLyricsFontSize
            cfgLyricsFontBold: root.cfgLyricsFontBold
            cfgShowVisualizer: root.cfgShowVisualizer
            cfgShowCompactVisualizer: root.cfgShowCompactVisualizer

            // Compact state bindings
            activeNotificationPill: root.activeNotificationPill
            notifAppName: root.notifAppName
            notifIcon: root.notifIcon
            notifSummary: root.notifSummary
            notifBody: root.notifBody
            activeBatteryPill: root.activeBatteryPill
            batteryIsCharging: root.batteryIsCharging
            sysBatteryPct: root.sysBatteryPct
            showPillLyrics: root.showPillLyrics
            currentLyricLine: root.currentLyricLine

            isPlaying: root.isPlaying
            currentTimeString: root.currentTimeString
            trackTitle: root.trackTitle
            trackArtist: root.trackArtist

            onRequestToggle: root.openNotch()
        }
    }

    // ==============================================================
    // 2. PANEL EXPANDED OVERLAY (Transparent Fixed-Canvas Overlay)
    // Ukuran window dialog statis (720x480) dengan NoBackground (tanpa frame & shadow)
    // Berada di bibir paling atas layar (y=0) sehingga siluet utuh yang melar
    // ==============================================================
    PlasmaCore.Dialog {
        id: expandedDialog
        width: 720
        height: 480
        // Lepaskan ikatan visualParent: atur koordinat absolut terhadap layar (menempel di tengah atas)
        x: Math.round((Screen.desktopAvailableWidth - width) / 2) + root.cfgHorizontalOffset
        y: root.cfgVerticalOffset
        type: PlasmaCore.Dialog.Normal
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.BypassWindowManagerHint | Qt.NoDropShadowWindowHint
        backgroundHints: PlasmaCore.Types.NoBackground
        hideOnWindowDeactivate: false
        visible: root.dialogSurfaceOpen

        onActiveChanged: {
            if (!active && root.isExpanded) {
                console.log("[NOTCH] Focus lost terdeteksi, memicu triggerCollapseSequence()");
                root.triggerCollapseSequence();
            }
        }

        mainItem: Item {
            id: fixedCanvas
            implicitWidth: 720
            implicitHeight: 480
            width: 720
            height: 480
            anchors.top: parent.top
            y: 0

            // Klik di area kanvas transparan di luar livingNotch untuk menutup
            MouseArea {
                anchors.fill: parent
                onClicked: root.triggerCollapseSequence()
            }

            ExpandedNotchCard {
                id: expandedCardPanel
                anchors.top: parent.top
                y: 0
                anchors.horizontalCenter: parent.horizontalCenter
                isOverlayDialog: true
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

                showControlTab: root.cfgShowControlTab
                showMediaTab: root.cfgShowMediaTab
                showClipboardTab: root.cfgShowClipboardTab
                showNotificationTab: root.cfgShowNotificationTab

                cfgClockFontFamily: root.cfgClockFontFamily
                cfgClockFontBold: root.cfgClockFontBold
                cfgLyricsFontFamily: root.cfgLyricsFontFamily
                cfgLyricsFontSize: root.cfgLyricsFontSize
                cfgLyricsFontBold: root.cfgLyricsFontBold

                // Compact state bindings (identik dengan panelCompactNotch)
                activeNotificationPill: root.activeNotificationPill
                notifAppName: root.notifAppName
                notifIcon: root.notifIcon
                notifSummary: root.notifSummary
                notifBody: root.notifBody
                activeBatteryPill: root.activeBatteryPill
                batteryIsCharging: root.batteryIsCharging
                showPillLyrics: root.showPillLyrics
                currentLyricLine: root.currentLyricLine
                currentDateString: root.currentDateString
                cfgClockFontSize: root.cfgClockFontSize
                cfgShowVisualizer: root.cfgShowVisualizer
                cfgShowCompactVisualizer: root.cfgShowCompactVisualizer

                sysCpuPct: root.sysCpuPct
                sysTemp: root.sysTemp
                sysRamPct: root.sysRamPct
                sysBatteryPct: root.sysBatteryPct
                sysBatteryCharging: root.sysBatteryCharging

                notificationHistory: root.notificationHistory

                trackTitle: root.trackTitle
                trackArtist: root.trackArtist
                trackAlbum: root.trackAlbum
                albumArtUrl: root.albumArtUrl
                trackPosition: root.estimatedTrackPosition
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
                onRequestClose: root.triggerCollapseSequence()
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
                onRequestCloseLyrics: root.showLyrics = false
                onRequestRetryLyrics: root.fetchLyrics(true)
                onRequestDemoLyrics: {
                    root.lyricsList = [
                        { time: 0, text: "Paper Sky - Lumen Coast" },
                        { time: 4, text: "Drifting slowly into the blue" },
                        { time: 8, text: "Fold the pages, make them new" },
                        { time: 14, text: "and send them through the sky" },
                        { time: 20, text: "to find you by the sea" },
                        { time: 26, text: "Where memories are waiting" },
                        { time: 32, text: "Listening to the waves call out" },
                        { time: 40, text: "Underneath the summer glow" }
                    ];
                    root.lyricsFound = true;
                    root.lyricsLoading = false;
                }
                onRequestClearAllNotifications: root.clearAllNotifications()
                onRequestRemoveNotification: (id) => root.removeNotification(id)

                onCollapseCompleted: {
                    console.log("[NOTCH] T=300ms: Buffer transparan ter-flush, dialog dimatikan dan notch panel dimunculkan.");
                    closeWatchdogTimer.stop();
                    root.dialogSurfaceOpen = false;
                }

                onCollapseFinished: {
                    closeWatchdogTimer.stop();
                    root.dialogSurfaceOpen = false;
                }
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

        showControlTab: root.cfgShowControlTab
        showMediaTab: root.cfgShowMediaTab
        showClipboardTab: root.cfgShowClipboardTab
        showNotificationTab: root.cfgShowNotificationTab

        cfgClockFontFamily: root.cfgClockFontFamily
        cfgClockFontBold: root.cfgClockFontBold
        cfgLyricsFontFamily: root.cfgLyricsFontFamily
        cfgLyricsFontSize: root.cfgLyricsFontSize
        cfgLyricsFontBold: root.cfgLyricsFontBold

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
        currentDateString: root.currentDateString
        cfgClockFontSize: root.cfgClockFontSize
        cfgShowVisualizer: root.cfgShowVisualizer
        cfgShowCompactVisualizer: root.cfgShowCompactVisualizer

        sysCpuPct: root.sysCpuPct
        sysTemp: root.sysTemp
        sysRamPct: root.sysRamPct
        sysBatteryPct: root.sysBatteryPct
        sysBatteryCharging: root.sysBatteryCharging

        notificationHistory: root.notificationHistory

        trackTitle: root.trackTitle
        trackArtist: root.trackArtist
        trackAlbum: root.trackAlbum
        albumArtUrl: root.albumArtUrl
        trackPosition: root.estimatedTrackPosition
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
        onRequestCloseLyrics: root.showLyrics = false
        onRequestRetryLyrics: root.fetchLyrics(true)
        onRequestDemoLyrics: {
            root.lyricsList = [
                { time: 0, text: "Paper Sky - Lumen Coast" },
                { time: 4, text: "Drifting slowly into the blue" },
                { time: 8, text: "Fold the pages, make them new" },
                { time: 14, text: "and send them through the sky" },
                { time: 20, text: "to find you by the sea" },
                { time: 26, text: "Where memories are waiting" },
                { time: 32, text: "Listening to the waves call out" },
                { time: 40, text: "Underneath the summer glow" }
            ];
            root.lyricsFound = true;
            root.lyricsLoading = false;
        }
        onRequestClearAllNotifications: root.clearAllNotifications()
        onRequestRemoveNotification: (id) => root.removeNotification(id)
    }
}

