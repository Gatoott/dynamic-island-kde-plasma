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
import org.kde.layershell as LayerShellQt
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
    readonly property int cfgNotchBottomRadius: Plasmoid.configuration.notchBottomRadius !== undefined 
        ? Plasmoid.configuration.notchBottomRadius 
        : (Plasmoid.configuration.notchCornerRadius !== undefined ? Plasmoid.configuration.notchCornerRadius : 14)
    readonly property int cfgNotchWingRadius: Plasmoid.configuration.notchWingRadius !== undefined 
        ? Plasmoid.configuration.notchWingRadius 
        : 14
    readonly property int cfgNotchCornerRadius: cfgNotchBottomRadius
    readonly property int cfgHorizontalOffset: Plasmoid.configuration.horizontalOffset !== undefined ? Plasmoid.configuration.horizontalOffset : 0
    readonly property int cfgClockFontSize: Plasmoid.configuration.clockFontSize || 13
    readonly property string cfgIslandShapeMode: Plasmoid.configuration.islandShapeMode || "notch"
    readonly property bool isFloatingStyle: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.notchStyle !== undefined) {
            return plasmoid.configuration.notchStyle === 1;
        }
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.notchStyle !== undefined) {
            return Plasmoid.configuration.notchStyle === 1;
        }
        return false;
    }
    readonly property int cfgNotchStyle: isFloatingStyle ? 1 : 0

    // Tetap baca nilai custom margin dari pengaturan plasmoid:
    property int cfgVerticalOffset: Plasmoid.configuration.verticalOffset !== undefined 
        ? Plasmoid.configuration.verticalOffset 
        : 0

    // Gunakan nilai konfigurasi secara langsung tanpa batasan buatan:
    readonly property int effectiveVerticalOffset: root.cfgVerticalOffset
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
    readonly property bool cfgAutoRetryLyrics: Plasmoid.configuration.autoRetryLyrics !== undefined ? Plasmoid.configuration.autoRetryLyrics : true
    readonly property int cfgExpandedBgStyle: Plasmoid.configuration.expandedBgStyle !== undefined ? Plasmoid.configuration.expandedBgStyle : 0
    readonly property int cfgMediaCardBgMode: Plasmoid.configuration.mediaBgStyle !== undefined ? Plasmoid.configuration.mediaBgStyle : (Plasmoid.configuration.mediaCardBgMode !== undefined ? Plasmoid.configuration.mediaCardBgMode : 2)
    readonly property int cfgLyricsBgMode: Plasmoid.configuration.lyricsBgMode !== undefined ? Plasmoid.configuration.lyricsBgMode : 1

    // Mini Music Icon (Left of Clock) Customization
    readonly property bool cfgMiniMusicIconEnabled: Plasmoid.configuration.miniMusicIconEnabled !== undefined ? Plasmoid.configuration.miniMusicIconEnabled : true
    readonly property int cfgMiniMusicIconSize: Plasmoid.configuration.miniMusicIconSize || 13
    readonly property int cfgMiniMusicIconWeight: Plasmoid.configuration.miniMusicIconWeight || 600
    readonly property int cfgMiniMusicIconColorMode: Plasmoid.configuration.miniMusicIconColorMode !== undefined ? Plasmoid.configuration.miniMusicIconColorMode : 0
    readonly property color cfgMiniMusicIconCustomColor: Qt.color(Plasmoid.configuration.miniMusicIconCustomColor || "#ffffff")

    // Mini Visualizer (Compact Pill) Customization
    readonly property int cfgMiniVisAlignment: Plasmoid.configuration.miniVisAlignment !== undefined ? Plasmoid.configuration.miniVisAlignment : 1
    readonly property int cfgMiniVisColorMode: Plasmoid.configuration.miniVisColorMode !== undefined ? Plasmoid.configuration.miniVisColorMode : 0
    readonly property color cfgMiniVisCustomColor: Qt.color(Plasmoid.configuration.miniVisCustomColor || "#38bdf8")
    readonly property int cfgMiniVisBarWidth: Plasmoid.configuration.miniVisBarWidth !== undefined ? Plasmoid.configuration.miniVisBarWidth : 2
    readonly property int cfgMiniVisSpacing: Plasmoid.configuration.miniVisSpacing !== undefined ? Plasmoid.configuration.miniVisSpacing : 2
    readonly property int cfgMiniVisHeight: {
        if (Plasmoid.configuration.miniVisHeight !== undefined) return Plasmoid.configuration.miniVisHeight;
        if (Plasmoid.configuration.miniVisMaxHeight !== undefined) return Plasmoid.configuration.miniVisMaxHeight;
        return 14;
    }
    readonly property int cfgMiniVisMaxHeight: cfgMiniVisHeight
    readonly property bool cfgMiniVisRounded: Plasmoid.configuration.miniVisRounded !== undefined ? Plasmoid.configuration.miniVisRounded : true

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
    property int currentExpandedTab: 0 // 0 = Media Player, 1 = Notifications, 2 = Control Center
    property int savedPanelHeight: 46

    readonly property bool showPillLyrics: root.showLyrics && root.isPlaying

    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge)

    readonly property real panelThickness: {
        if (!root.inPanel) return 0;
        if (typeof plasmoid !== "undefined" && plasmoid.containment && plasmoid.containment.height > 0) {
            return plasmoid.containment.height;
        }
        if (Plasmoid.containment && Plasmoid.containment.height > 0) {
            return Plasmoid.containment.height;
        }
        return root.savedPanelHeight > 0 ? root.savedPanelHeight : 36;
    }

    TextMetrics {
        id: notifMetrics
        font.pixelSize: 11
        font.bold: true
        font.family: "Inter, Roboto, sans-serif"
        text: {
            var isWA = (root.notifAppName || "").toLowerCase().indexOf("whatsapp") !== -1 ||
                       (root.notifSummary || "").toLowerCase().indexOf("whatsapp") !== -1;
            var sender = (root.notifSummary || "").trim();
            var msg = (root.notifBody || "").trim();
            if (isWA && (sender.toLowerCase() === "whatsapp" || sender === "")) {
                var colonIdx = msg.indexOf(":");
                if (colonIdx > 0 && colonIdx < 30) {
                    sender = msg.substring(0, colonIdx).trim();
                    msg = msg.substring(colonIdx + 1).trim();
                } else {
                    sender = "Pesan Baru";
                }
            } else if (!isWA && sender === "") {
                sender = root.notifAppName.length > 0 ? root.notifAppName : "Notification";
            }
            return (sender.length >= msg.length) ? sender : msg;
        }
    }

    readonly property int currentCompactWidth: {
        if (root.activeNotificationPill) {
            return Math.max(220, Math.min(360, Math.ceil(notifMetrics.advanceWidth) + 64));
        }
        if (root.activeBatteryPill) return 210;
        if (root.showPillLyrics) {
            // Tight auto-width hugging: 14 (music icon) + 8 (spacing) + text + (miniVisualizer if active) + 24 (left 12 + right 12)
            var iconW = 14;
            var gap = 8;
            var visW = root.cfgShowCompactVisualizer ? (root.cfgMiniVisBarWidth * 4 + root.cfgMiniVisSpacing * 3 + 8) : 0;
            var textW = Math.ceil(pillLyricsMetrics.advanceWidth);
            var padding = 24;
            var totalW = iconW + gap + textW + visW + padding;
            return Math.max(160, Math.min(540, totalW));
        }
        var miniVisW = (root.cfgShowVisualizer) ? (root.cfgMiniVisBarWidth * 4 + root.cfgMiniVisSpacing * 3 + 12) : 0;
        var musicIconExtraW = (root.cfgMiniMusicIconEnabled) ? Math.max(0, root.cfgMiniMusicIconSize - 12 + 6) : 0;
        return root.isPlaying ? root.cfgCompactWidth + miniVisW + musicIconExtraW : root.cfgCompactWidth;
    }

    readonly property int currentNotchWidth: {
        if (!root.isExpanded) {
            return root.currentCompactWidth;
        }
        if (root.showLyrics) {
            return 640;
        }
        return root.cfgExpandedWidth;
    }

    preferredRepresentation: compactRepresentation
    Layout.preferredWidth: (!root.inPanel) ? desktopLivingNotch.width : (root.currentCompactWidth + (root.isFloatingStyle ? 0 : 32))
    Layout.preferredHeight: (!root.inPanel) ? desktopLivingNotch.height : (root.cfgCompactHeight + (root.isFloatingStyle && root.effectiveVerticalOffset > 0 ? root.effectiveVerticalOffset : 0))
    Layout.minimumWidth: 100
    Layout.maximumHeight: root.inPanel ? (root.cfgCompactHeight + (root.isFloatingStyle && root.effectiveVerticalOffset > 0 ? root.effectiveVerticalOffset : 0)) : 10000
    implicitWidth: (!root.inPanel) ? desktopLivingNotch.width : (root.currentCompactWidth + (root.isFloatingStyle ? 0 : 32))
    implicitHeight: (!root.inPanel) ? desktopLivingNotch.height : (root.cfgCompactHeight + (root.isFloatingStyle && root.effectiveVerticalOffset > 0 ? root.effectiveVerticalOffset : 0))

    TextMetrics {
        id: pillLyricsMetrics
        font.pixelSize: root.cfgLyricsFontSize
        font.bold: root.cfgLyricsFontBold
        font.family: root.cfgLyricsFontFamily !== "" ? root.cfgLyricsFontFamily : "Inter, Roboto, sans-serif"
        text: root.currentLyricLine !== "" 
              ? root.currentLyricLine 
              : (root.trackTitle ? (root.trackTitle + (root.trackArtist ? " • " + root.trackArtist : "")) : "Tidak ada media")
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

    // --- Dynamic Color Extraction from Album Art for Mini Visualizer ---
    property color albumDominantColor: root.cfgAccentColor
    Behavior on albumDominantColor { ColorAnimation { duration: 400 } }

    Canvas {
        id: globalColorSamplerCanvas
        width: 16
        height: 16
        visible: false
        property string imageSource: root.albumArtUrl

        onImageSourceChanged: {
            if (imageSource && imageSource !== "") {
                loadImage(imageSource);
            } else {
                root.albumDominantColor = root.cfgAccentColor;
            }
        }

        onImageLoaded: {
            requestPaint();
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            try {
                ctx.drawImage(imageSource, 0, 0, width, height);
                var imgData = ctx.getImageData(0, 0, width, height);
                var data = imgData.data;
                var r = 0, g = 0, b = 0, count = 0;
                for (var i = 0; i < data.length; i += 4) {
                    var pr = data[i];
                    var pg = data[i+1];
                    var pb = data[i+2];
                    var brightness = (pr * 299 + pg * 587 + pb * 114) / 1000;
                    if (brightness > 30 && brightness < 235) {
                        r += pr;
                        g += pg;
                        b += pb;
                        count++;
                    }
                }
                if (count > 0) {
                    r = Math.round(r / count);
                    g = Math.round(g / count);
                    b = Math.round(b / count);
                    root.albumDominantColor = Qt.rgba(r / 255.0, g / 255.0, b / 255.0, 1.0);
                } else {
                    root.albumDominantColor = root.cfgAccentColor;
                }
            } catch (e) {
                root.albumDominantColor = root.cfgAccentColor;
            }
        }
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
    property string currentActiveTrackKey: ""

    // Auto-Retry Lyrics Engine
    property int retryCount: 0
    property int maxRetries: 4

    Timer {
        id: retryLyricsTimer
        interval: 3500
        repeat: false
        onTriggered: {
            if (root.cfgAutoRetryLyrics && root.isPlaying && root.retryCount < root.maxRetries) {
                root.retryCount++;
                console.log("[LYRICS] Auto-retrying fetch attempt:", root.retryCount, "of", root.maxRetries);
                root.fetchLyrics(true);
            }
        }
    }

    property real lastSyncPosition: 0
    property double lastSyncTimestamp: 0
    property real estimatedTrackPosition: 0

    // 1. One-shot timer dijadwalkan tepat ke timestamp baris lirik berikutnya
    Timer {
        id: nextLyricTimer
        repeat: false
        onTriggered: {
            if (!root.isPlaying) return;
            var estPos = root.getEstimatedTrackPosition();
            root.estimatedTrackPosition = estPos;
            root.updateLyricProgress(estPos);
        }
    }

    // 2. Timer update progress bar slider kartu media (HANYA saat dialog expanded terbuka)
    Timer {
        id: expandedProgressTimer
        interval: 250
        repeat: true
        running: root.isPlaying && root.isExpanded
        onTriggered: {
            var estPos = root.getEstimatedTrackPosition();
            root.estimatedTrackPosition = estPos;
        }
    }

    // 3. Safety net pasif (1000ms): Hanya aktif saat lagu berputar, mode lirik aktif, dan ada lirik.
    // Menjaga sinkronisasi tetap presisi jika ada drift waktu atau event player yang terlambat.
    Timer {
        id: lyricsSafetyNetTimer
        interval: 1000
        repeat: true
        running: root.isPlaying && root.showLyrics && (root.lyricsList && root.lyricsList.length > 0)
        onTriggered: {
            var estPos = root.getEstimatedTrackPosition();
            root.estimatedTrackPosition = estPos;
            root.updateLyricProgress(estPos);
        }
    }

    function getEstimatedTrackPosition() {
        if (!isPlaying || lastSyncTimestamp <= 0) {
            return lastSyncPosition;
        }
        var elapsedSec = (Date.now() - lastSyncTimestamp) / 1000.0;
        var estPos = lastSyncPosition + elapsedSec;
        if (trackLength > 0 && estPos > trackLength) {
            estPos = trackLength;
        }
        return estPos;
    }

    function syncLyrics() {
        if (!lyricsList || lyricsList.length === 0) {
            currentLyricIndex = -1;
            currentLyricLine = "";
            nextLyricTimer.stop();
            return;
        }
        var estPos = getEstimatedTrackPosition();
        estimatedTrackPosition = estPos;
        updateLyricProgress(estPos);
    }

    onLyricsListChanged: {
        currentLyricIndex = -1;
        currentLyricLine = "";
        syncLyrics();
    }

    onTrackTitleChanged: {
        currentLyricIndex = -1;
        currentLyricLine = "";
        lyricsList = [];
        lyricsFound = false;
        lastSyncPosition = trackPosition;
        lastSyncTimestamp = Date.now();
        estimatedTrackPosition = trackPosition;
        retryCount = 0;
        retryLyricsTimer.stop();
        nextLyricTimer.stop();
        if (trackTitle && trackTitle.length > 0) {
            fetchLyrics(true);
        }
    }

    onTrackArtistChanged: {
        currentLyricIndex = -1;
        currentLyricLine = "";
        lyricsList = [];
        lyricsFound = false;
        lastSyncPosition = trackPosition;
        lastSyncTimestamp = Date.now();
        estimatedTrackPosition = trackPosition;
        retryCount = 0;
        retryLyricsTimer.stop();
        nextLyricTimer.stop();
        if (trackTitle && trackTitle.length > 0) {
            fetchLyrics(true);
        }
    }

    onActivePlayerChanged: {
        lastSyncPosition = trackPosition;
        lastSyncTimestamp = Date.now();
        estimatedTrackPosition = trackPosition;
        if (trackTitle && trackTitle.length > 0) {
            fetchLyrics(true);
        } else {
            lyricsList = [];
            currentLyricIndex = -1;
            currentLyricLine = "";
            nextLyricTimer.stop();
        }
        syncLyrics();
    }

    onShowLyricsChanged: {
        if (showLyrics && (!lyricsList || lyricsList.length === 0)) {
            fetchLyrics(true);
        } else if (showLyrics) {
            syncLyrics();
        } else {
            nextLyricTimer.stop();
        }
    }

    onIsExpandedChanged: {
        if (isExpanded) {
            var estPos = getEstimatedTrackPosition();
            root.estimatedTrackPosition = estPos;
            updateLyricProgress(estPos);
        }
    }

    onTrackPositionChanged: {
        lastSyncPosition = trackPosition;
        lastSyncTimestamp = Date.now();
        estimatedTrackPosition = trackPosition;
        syncLyrics();
    }

    onIsPlayingChanged: {
        lastSyncPosition = trackPosition;
        lastSyncTimestamp = Date.now();
        estimatedTrackPosition = trackPosition;
        if (!isPlaying) {
            nextLyricTimer.stop();
        }
        syncLyrics();

        // Sinkronisasi status playback ke backend audio visualizer cava
        if (dbusVisSetPlaying && dbusVisSetPlaying.call) {
            dbusVisSetPlaying.call("SetPlaying", [root.isPlaying]);
        }
    }

    function updateLyricProgress(pos) {
        if (!lyricsList || lyricsList.length === 0) {
            nextLyricTimer.stop();
            return;
        }

        // Cari index baris lirik saat ini secara efisien
        var idx = -1;
        var startI = (currentLyricIndex >= 0 && currentLyricIndex < lyricsList.length && lyricsList[currentLyricIndex].time <= pos)
            ? currentLyricIndex : 0;

        for (var i = startI; i < lyricsList.length; i++) {
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

        // Jadwalkan timer sekali-jalan tepat pada waktu baris lirik berikutnya
        if (root.isPlaying && (root.isExpanded || root.showLyrics)) {
            var nextIdx = idx + 1;
            if (nextIdx < lyricsList.length) {
                var timeRemaining = lyricsList[nextIdx].time - pos;
                var delayMs = Math.max(25, Math.round(timeRemaining * 1000));
                if (!nextLyricTimer.running || Math.abs(nextLyricTimer.interval - delayMs) > 200) {
                    nextLyricTimer.interval = delayMs;
                    nextLyricTimer.restart();
                }
            } else {
                nextLyricTimer.stop();
            }
        } else {
            nextLyricTimer.stop();
        }
    }

    function cleanTrackTitle(title) {
        if (!title) return "";
        return title
            // Hapus teks di dalam kurung/siku: (feat. ...), [Official Video], (Remastered ...), dll.
            .replace(/\s*[\(\[][^\)\]]*(feat|ft|official|remaster|live|version|edit|audio|deluxe|bonus|explicit)[^\)\]]*[\)\]]/gi, "")
            // Hapus keterangan setelah strip: "Song Name - Remastered" -> "Song Name"
            .replace(/\s*-\s*(remastered|live|official video|radio edit|bonus track).*$/i, "")
            .trim();
    }

    function cleanArtistName(artist) {
        if (!artist) return "";
        // Jika ada beberapa artis dipisah koma, titik koma, atau "feat.", ambil artis utama saja
        return artist
            .split(/,|;|&|\bfeat\.?\b|\bft\.?\b/i)[0]
            .trim();
    }

    function selectBestLyricItem(items, durationSec) {
        if (!items || items.length === 0) return null;

        // 1. Kumpulkan item yang memiliki syncedLyrics valid
        var syncedItems = [];
        for (var i = 0; i < items.length; i++) {
            if (items[i].syncedLyrics && items[i].syncedLyrics.trim().length > 0) {
                syncedItems.push(items[i]);
            }
        }

        if (syncedItems.length > 0) {
            if (durationSec > 0) {
                var bestItem = null;
                var minDiff = 999999;
                for (var j = 0; j < syncedItems.length; j++) {
                    var it = syncedItems[j];
                    var itDur = (typeof it.duration === "number") ? it.duration : 0;
                    if (itDur > 0) {
                        var diff = Math.abs(durationSec - itDur);
                        if (diff < minDiff) {
                            minDiff = diff;
                            bestItem = it;
                        }
                    }
                }
                // Toleransi maksimal ±5 detik
                if (bestItem && minDiff <= 5) {
                    return bestItem;
                }
            }
            // Jika tidak ada yang cocok dalam toleransi durasi, gunakan hasil pertama yang memiliki syncedLyrics
            return syncedItems[0];
        }

        // 2. Fallback jika tidak ada syncedLyrics: cari plainLyrics
        var plainItems = [];
        for (var k = 0; k < items.length; k++) {
            if (items[k].plainLyrics && items[k].plainLyrics.trim().length > 0) {
                plainItems.push(items[k]);
            }
        }
        if (plainItems.length > 0) {
            if (durationSec > 0) {
                var bestPlain = null;
                var minPlainDiff = 999999;
                for (var m = 0; m < plainItems.length; m++) {
                    var pIt = plainItems[m];
                    var pDur = (typeof pIt.duration === "number") ? pIt.duration : 0;
                    if (pDur > 0) {
                        var pDiff = Math.abs(durationSec - pDur);
                        if (pDiff < minPlainDiff) {
                            minPlainDiff = pDiff;
                            bestPlain = pIt;
                        }
                    }
                }
                if (bestPlain && minPlainDiff <= 5) {
                    return bestPlain;
                }
            }
            return plainItems[0];
        }

        return null;
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
        if (!trackTitle || trackTitle.trim() === "") {
            lyricsList = [];
            lyricsFound = false;
            lyricsLoading = false;
            return;
        }

        var rawTitle = trackTitle.trim();
        var rawArtist = trackArtist ? trackArtist.trim() : "";

        // Tangani judul dari pemutar web/browser yang berformat "Artis - Judul"
        if ((!rawArtist || rawArtist === "Brave" || rawArtist === "Chromium" || rawArtist === "Firefox") && rawTitle.indexOf(" - ") !== -1) {
            var parts = rawTitle.split(" - ");
            rawArtist = parts[0].trim();
            rawTitle = parts.slice(1).join(" - ").trim();
        }

        var cleanTitle = cleanTrackTitle(rawTitle);
        if (!cleanTitle) cleanTitle = rawTitle;
        var cleanArtist = cleanArtistName(rawArtist);

        var durationSec = trackLength > 0 ? Math.round(trackLength) : 0;
        var trackKey = (cleanArtist ? cleanArtist : "Unknown") + " - " + cleanTitle;

        if (!force && trackKey === lastFetchedKey && lyricsList.length > 0) return;
        if (!force && trackKey === currentActiveTrackKey && lyricsLoading) return;

        currentActiveTrackKey = trackKey;
        lastFetchedKey = trackKey;
        lyricsLoading = true;
        lyricsFound = false;

        // Tahap 1: Coba Endpoint Exact Match (/api/get)
        fetchExactLyrics(cleanTitle, cleanArtist, durationSec, trackKey);
    }

    function fetchExactLyrics(cleanTitle, cleanArtist, durationSec, trackKey) {
        var url = "https://lrclib.net/api/get?track_name=" + encodeURIComponent(cleanTitle);
        if (cleanArtist && cleanArtist.length > 0) {
            url += "&artist_name=" + encodeURIComponent(cleanArtist);
        }
        if (trackAlbum && trackAlbum.trim().length > 0) {
            url += "&album_name=" + encodeURIComponent(trackAlbum.trim());
        }
        if (durationSec > 0) {
            url += "&duration=" + durationSec;
        }

        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", "PlasmaDynamicIsland/1.0");
        xhr.timeout = 6000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // Race condition protection: verifikasi lagu masih sama
                if (root.currentActiveTrackKey !== trackKey) {
                    console.log("[LYRICS] Request exact match diabaikan karena lagu sudah berganti:", trackKey);
                    return;
                }

                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        if (data.syncedLyrics && data.syncedLyrics.trim().length > 0) {
                            var parsed = root.parseLrc(data.syncedLyrics);
                            if (parsed.length > 0) {
                                root.lyricsList = parsed;
                                root.lyricsFound = true;
                                root.lyricsLoading = false;
                                root.retryCount = 0;
                                retryLyricsTimer.stop();
                                root.syncLyrics();
                                return;
                            }
                        }
                    } catch (e) {
                        console.error("[LYRICS] LRCLIB exact match parse error:", e);
                    }
                }

                // Jika exact match 404 atau tidak ada syncedLyrics, lanjut ke Tahap 2: Search dengan filter durasi
                fallbackSearchLyrics(cleanTitle, cleanArtist, durationSec, trackKey);
            }
        };
        xhr.ontimeout = function() {
            if (root.currentActiveTrackKey !== trackKey) return;
            fallbackSearchLyrics(cleanTitle, cleanArtist, durationSec, trackKey);
        };
        xhr.send();
    }

    function fallbackSearchLyrics(cleanTitle, cleanArtist, durationSec, trackKey) {
        var searchUrl = "https://lrclib.net/api/search?track_name=" + encodeURIComponent(cleanTitle);
        if (cleanArtist && cleanArtist.length > 0) {
            searchUrl += "&artist_name=" + encodeURIComponent(cleanArtist);
        }

        var xhr = new XMLHttpRequest();
        xhr.open("GET", searchUrl);
        xhr.setRequestHeader("User-Agent", "PlasmaDynamicIsland/1.0");
        xhr.timeout = 7000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // Race condition protection
                if (root.currentActiveTrackKey !== trackKey) {
                    console.log("[LYRICS] Fallback search diabaikan karena lagu sudah berganti:", trackKey);
                    return;
                }

                if (xhr.status === 200) {
                    try {
                        var items = JSON.parse(xhr.responseText);
                        if (Array.isArray(items) && items.length > 0) {
                            var best = root.selectBestLyricItem(items, durationSec);
                            if (best) {
                                if (best.syncedLyrics && best.syncedLyrics.trim().length > 0) {
                                    var parsed = root.parseLrc(best.syncedLyrics);
                                    if (parsed.length > 0) {
                                        root.lyricsList = parsed;
                                        root.lyricsFound = true;
                                        root.lyricsLoading = false;
                                        root.retryCount = 0;
                                        retryLyricsTimer.stop();
                                        root.syncLyrics();
                                        return;
                                    }
                                } else if (best.plainLyrics && best.plainLyrics.trim().length > 0) {
                                    var pLines = best.plainLyrics.split("\n");
                                    var plainParsed = [];
                                    for (var k = 0; k < pLines.length; k++) {
                                        if (pLines[k].trim()) plainParsed.push({ time: k * 3.5, text: pLines[k].trim() });
                                    }
                                    if (plainParsed.length > 0) {
                                        root.lyricsList = plainParsed;
                                        root.lyricsFound = true;
                                        root.lyricsLoading = false;
                                        root.retryCount = 0;
                                        retryLyricsTimer.stop();
                                        root.syncLyrics();
                                        return;
                                    }
                                }
                            }
                        }
                    } catch (e) {
                        console.error("[LYRICS] Search parse error:", e);
                    }
                }

                // Jika search spesifik track_name+artist_name tidak membuahkan hasil, coba query umum q=
                generalSearchLyrics(cleanTitle, cleanArtist, durationSec, trackKey);
            }
        };
        xhr.ontimeout = function() {
            if (root.currentActiveTrackKey !== trackKey) return;
            generalSearchLyrics(cleanTitle, cleanArtist, durationSec, trackKey);
        };
        xhr.send();
    }

    function generalSearchLyrics(cleanTitle, cleanArtist, durationSec, trackKey) {
        var query = cleanTitle;
        if (cleanArtist && cleanArtist.length > 0) {
            query += " " + cleanArtist;
        }
        var searchUrl = "https://lrclib.net/api/search?q=" + encodeURIComponent(query);

        var xhr = new XMLHttpRequest();
        xhr.open("GET", searchUrl);
        xhr.setRequestHeader("User-Agent", "PlasmaDynamicIsland/1.0");
        xhr.timeout = 7000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (root.currentActiveTrackKey !== trackKey) {
                    console.log("[LYRICS] General search diabaikan karena lagu sudah berganti:", trackKey);
                    return;
                }

                root.lyricsLoading = false;
                if (xhr.status === 200) {
                    try {
                        var items = JSON.parse(xhr.responseText);
                        if (Array.isArray(items) && items.length > 0) {
                            var best = root.selectBestLyricItem(items, durationSec);
                            if (best) {
                                if (best.syncedLyrics && best.syncedLyrics.trim().length > 0) {
                                    var parsed = root.parseLrc(best.syncedLyrics);
                                    if (parsed.length > 0) {
                                        root.lyricsList = parsed;
                                        root.lyricsFound = true;
                                        root.retryCount = 0;
                                        retryLyricsTimer.stop();
                                        root.syncLyrics();
                                        return;
                                    }
                                } else if (best.plainLyrics && best.plainLyrics.trim().length > 0) {
                                    var pLines = best.plainLyrics.split("\n");
                                    var plainParsed = [];
                                    for (var k = 0; k < pLines.length; k++) {
                                        if (pLines[k].trim()) plainParsed.push({ time: k * 3.5, text: pLines[k].trim() });
                                    }
                                    if (plainParsed.length > 0) {
                                        root.lyricsList = plainParsed;
                                        root.lyricsFound = true;
                                        root.retryCount = 0;
                                        retryLyricsTimer.stop();
                                        root.syncLyrics();
                                        return;
                                    }
                                }
                            }
                        }
                    } catch (e) {
                        console.error("[LYRICS] General search parse error:", e);
                    }
                }
                root.lyricsFound = false;
                if (root.cfgAutoRetryLyrics && root.isPlaying && root.retryCount < root.maxRetries) {
                    console.log("[LYRICS] Lirik belum ditemukan, auto-retry dijadwalkan dalam 3.5s (attempt " + (root.retryCount + 1) + "/" + root.maxRetries + ")");
                    retryLyricsTimer.restart();
                }
            }
        };
        xhr.ontimeout = function() {
            if (root.currentActiveTrackKey !== trackKey) return;
            root.lyricsLoading = false;
            root.lyricsFound = false;
            if (root.cfgAutoRetryLyrics && root.isPlaying && root.retryCount < root.maxRetries) {
                console.log("[LYRICS] Request timeout, auto-retry dijadwalkan dalam 3.5s (attempt " + (root.retryCount + 1) + "/" + root.maxRetries + ")");
                retryLyricsTimer.restart();
            }
        };
        xhr.send();
    }

    // --- Native KDE Plasma 6 System Sensors ---
    property bool initialSensorProbeDone: false
    Timer {
        id: initialSensorProbeTimer
        interval: 4000
        running: true
        repeat: false
        onTriggered: root.initialSensorProbeDone = true
    }

    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: 2000
        enabled: root.isExpanded || !root.initialSensorProbeDone
    }
    Sensors.Sensor {
        id: ramSensor
        sensorId: "memory/physical/usedPercent"
        updateRateLimit: 2000
        enabled: root.isExpanded || !root.initialSensorProbeDone
    }
    Sensors.Sensor {
        id: tempSensor
        sensorId: "cpu/all/averageTemperature"
        updateRateLimit: 2000
        enabled: root.isExpanded || !root.initialSensorProbeDone
    }

    property int lastKnownCpuPct: 14
    property int lastKnownRamPct: 45
    property int lastKnownTemp: 42

    readonly property int sysCpuPct: {
        if (typeof cpuSensor !== "undefined" && cpuSensor.value !== undefined && !isNaN(cpuSensor.value) && cpuSensor.value > 0) {
            root.lastKnownCpuPct = Math.round(cpuSensor.value);
        }
        return root.lastKnownCpuPct;
    }
    readonly property int sysRamPct: {
        if (typeof ramSensor !== "undefined" && ramSensor.value !== undefined && !isNaN(ramSensor.value) && ramSensor.value > 0) {
            root.lastKnownRamPct = Math.round(ramSensor.value);
        }
        return root.lastKnownRamPct;
    }
    readonly property int sysTemp: {
        if (typeof tempSensor !== "undefined" && tempSensor.value !== undefined && !isNaN(tempSensor.value) && tempSensor.value > 0) {
            root.lastKnownTemp = Math.round(tempSensor.value);
        }
        return root.lastKnownTemp;
    }
    property int sysBatteryPct: 100
    property bool sysBatteryCharging: false

    // --- Battery & Power Monitor with State Machine & Debounce Timer ---
    property bool activeBatteryPill: false
    property bool batteryIsCharging: false
    property int lastStabilizedPluggedState: -1 // -1 = uninitialized, 0 = unplugged/discharging, 1 = plugged/charging
    property int pendingPluggedState: -1

    // Debounce Timer (350ms): Menstabilkan fluktuasi sinyal transien ACPI / UPower saat colok/cabut charger
    Timer {
        id: powerDebounceTimer
        interval: 350
        repeat: false
        onTriggered: {
            var rawState = root.getCurrentAcPluggedState();
            var targetState = (rawState !== -1) ? rawState : root.pendingPluggedState;
            if (targetState === -1) return;

            // Inisialisasi awal saat login/boot: simpan status awal tanpa memunculkan notifikasi pop-up
            if (root.lastStabilizedPluggedState === -1) {
                root.lastStabilizedPluggedState = targetState;
                root.batteryIsCharging = (targetState === 1);
                root.sysBatteryCharging = (targetState === 1);
                return;
            }

            // HANYA picu notifikasi jika BENAR-BENAR terjadi perubahan status fisik stabil
            if (targetState !== root.lastStabilizedPluggedState) {
                root.lastStabilizedPluggedState = targetState;
                var isCharging = (targetState === 1);
                root.batteryIsCharging = isCharging;
                root.sysBatteryCharging = isCharging;

                // Picu notifikasi Dynamic Island (hanya sekali saat terjadi perubahan fisik)
                if (!root.isExpanded) {
                    root.activeBatteryPill = true;
                    batteryDismissTimer.restart();
                }
            }
        }
    }

    function queuePowerStateCheck(isPlugged) {
        root.pendingPluggedState = isPlugged ? 1 : 0;
        powerDebounceTimer.restart();
    }

    function getCurrentAcPluggedState() {
        if (typeof batteryModel !== "undefined" && batteryModel.hasBatteries && batteryModel.pluggedIn !== undefined) {
            return batteryModel.pluggedIn ? 1 : 0;
        }
        return root.pendingPluggedState;
    }

    Timer {
        id: batteryDismissTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.activeBatteryPill = false;
        }
    }

    // 1. Plasma Native Battery Control Model
    Battery.BatteryControlModel {
        id: batteryModel

        onPercentChanged: {
            // MURNI update angka persentase baterai saja, JANGAN PERNAH picu notifikasi di sini
            if (batteryModel.percent !== undefined && batteryModel.percent > 0) {
                root.sysBatteryPct = batteryModel.percent;
            }
        }

        onPluggedInChanged: {
            root.queuePowerStateCheck(batteryModel.pluggedIn);
        }

        Component.onCompleted: {
            if (batteryModel.percent !== undefined && batteryModel.percent > 0) {
                root.sysBatteryPct = batteryModel.percent;
            }
            if (batteryModel.pluggedIn !== undefined) {
                var initialPlugged = batteryModel.pluggedIn ? 1 : 0;
                root.lastStabilizedPluggedState = initialPlugged;
                root.batteryIsCharging = (initialPlugged === 1);
                root.sysBatteryCharging = (initialPlugged === 1);
            }
        }
    }

    // 2. UPower Daemon D-Bus Watcher (Global AC / OnBattery State)
    DBus.Properties {
        id: upowerDaemonProps
        busType: DBus.BusType.System
        service: "org.freedesktop.UPower"
        path: "/org/freedesktop/UPower"
        iface: "org.freedesktop.UPower"

        onPropertiesChanged: {
            if (typeof properties !== "undefined" && properties !== null && properties.OnBattery !== undefined) {
                // OnBattery === false berarti kabel AC tercolok (plugged in)
                root.queuePowerStateCheck(!properties.OnBattery);
            }
        }
    }

    // 3. UPower DisplayDevice D-Bus Reactive Properties (HANYA untuk persentase baterai)
    DBus.Properties {
        id: upowerDisplayDeviceProps
        busType: DBus.BusType.System
        service: "org.freedesktop.UPower"
        path: "/org/freedesktop/UPower/devices/DisplayDevice"
        iface: "org.freedesktop.UPower.Device"

        onPropertiesChanged: {
            if (typeof properties !== "undefined" && properties !== null) {
                if (properties.Percentage !== undefined) {
                    var p = Math.round(properties.Percentage);
                    if (!isNaN(p) && p > 0) {
                        root.sysBatteryPct = p;
                    }
                }
            }
        }
    }

    // 4. Periodic Polling & D-Bus Fallback (interval 60000ms - Safety net pasif santai)
    DBusCall {
        id: dbusBatteryGet
        busType: DBus.BusType.System
        service: "org.freedesktop.UPower"
        path: "/org/freedesktop/UPower/devices/DisplayDevice"
        iface: "org.freedesktop.DBus.Properties"
        member: "Get"
    }

    Timer {
        id: batteryPollTimer
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            root.refreshBatteryStatus();
        }
    }

    function refreshBatteryStatus() {
        if (typeof batteryModel !== "undefined" && batteryModel.hasBatteries && batteryModel.percent !== undefined && batteryModel.percent > 0) {
            root.sysBatteryPct = batteryModel.percent;
        }
        dbusBatteryGet.call("Get", ["org.freedesktop.UPower.Device", "Percentage"], (reply) => {
            if (reply && reply.value !== undefined) {
                var p = Math.round(reply.value);
                if (!isNaN(p) && p > 0) {
                    root.sysBatteryPct = p;
                }
            }
        });
    }

    // --- Real Audio Visualizer Client (cava D-Bus Provider) ---
    property var visualizerLevels: [0.0, 0.0, 0.0, 0.0]
    property bool visualizerServiceActive: false

    function handleVisualizerData(source) {
        if (!source) return;
        var lv = source["levels"] !== undefined ? source["levels"] : source.levels;
        if (lv !== undefined && lv !== null) {
            var actualLv = (typeof lv === "object" && lv.value !== undefined) ? lv.value : lv;
            if (actualLv && actualLv.length >= 4) {
                var clean = [];
                for (var i = 0; i < 4; i++) {
                    var item = actualLv[i];
                    var val = (typeof item === "object" && item !== null && item.value !== undefined) ? Number(item.value) : Number(item);
                    clean.push(isNaN(val) ? 0.0 : Math.max(0.0, Math.min(1.0, val)));
                }
                root.visualizerLevels = clean;
                root.visualizerServiceActive = true;
                visualizerHeartbeatTimer.restart();
            }
        }
        var act = source["active"] !== undefined ? source["active"] : source.active;
        if (act !== undefined && act !== null) {
            var actualAct = (typeof act === "object" && act.value !== undefined) ? act.value : act;
            root.visualizerServiceActive = Boolean(actualAct);
        }
    }

    DBus.SignalWatcher {
        id: visualizerSignalWatcher
        busType: DBus.BusType.Session
        service: "org.kde.plasma.dynamicisland.visualizer"
        path: "/Visualizer"
        iface: "org.kde.plasma.dynamicisland.visualizer"

        function dbusLevelsChanged(levels, active) {
            if (levels && levels.length >= 4) {
                var clean = [];
                for (var i = 0; i < 4; i++) {
                    var item = levels[i];
                    var val = (typeof item === "object" && item !== null && item.value !== undefined) ? Number(item.value) : Number(item);
                    clean.push(isNaN(val) ? 0.0 : Math.max(0.0, Math.min(1.0, val)));
                }
                root.visualizerLevels = clean;
                root.visualizerServiceActive = Boolean(active);
                visualizerHeartbeatTimer.restart();
            }
        }

        function dbusSetExpanded(expanded) {
            if (expanded) root.openNotch(0);
            else root.closeNotch();
        }

        function dbusSetLyrics(show) {
            root.showLyrics = Boolean(show);
        }
    }

    DBus.Properties {
        id: visualizerProps
        busType: DBus.BusType.Session
        service: "org.kde.plasma.dynamicisland.visualizer"
        path: "/Visualizer"
        iface: "org.kde.plasma.dynamicisland.visualizer"

        onPropertiesChanged: (ifaceName, changedProps, invalidated) => {
            root.handleVisualizerData(changedProps);
        }
        onRefreshed: {
            root.handleVisualizerData(properties);
        }
        Component.onCompleted: {
            updateAll();
        }
    }

    DBusCall {
        id: dbusVisSetPlaying
        busType: DBus.BusType.Session
        service: "org.kde.plasma.dynamicisland.visualizer"
        path: "/Visualizer"
        iface: "org.kde.plasma.dynamicisland.visualizer"
        member: "SetPlaying"
    }

    Timer {
        id: visualizerHeartbeatTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (root.visualizerServiceActive) {
                root.visualizerServiceActive = false;
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

    // Status keterlihatan kapsul standby di panel (Mencegah gap/kedip saat transisi window Wayland)
    property bool compactVisible: true

    // Timer Fallback Penutupan Dialog (Mencegah Deadlock):
    Timer {
        id: closeWatchdogTimer
        interval: 450 // Sedikit lebih lama dari durasi animasi close 220ms + handover 32ms
        repeat: false
        onTriggered: {
            if (!root.isExpanded || (expandedCardPanel && expandedCardPanel.isClosing)) {
                console.log("[NOTCH] Watchdog: Memastikan dialog tertutup dan notch panel aktif");
                root.compactVisible = true;
                if (expandedCardPanel) expandedCardPanel.isClosing = false;
                expandedDialog.visible = false;
                root.dialogSurfaceOpen = false;
                root.isExpanded = false;
            }
        }
    }

    // Timer Handover Frame: Memberi waktu compositor Wayland merender panel pill sebelum overlay window di-unmap
    Timer {
        id: closeHandoverTimer
        interval: 32 // ~2 frame pada 60Hz agar handover mulus tanpa kedip
        repeat: false
        onTriggered: {
            expandedDialog.visible = false;
            root.dialogSurfaceOpen = false;
            root.isExpanded = false;
            if (expandedCardPanel) {
                expandedCardPanel.isClosing = false;
                expandedCardPanel.resetGeometryAfterUnmap();
            }
        }
    }

    function openNotch(targetTabIndex) {
        if (closeWatchdogTimer.running) {
            closeWatchdogTimer.stop();
        }
        if (closeHandoverTimer.running) {
            closeHandoverTimer.stop();
        }
        var card = root.inPanel ? expandedCardPanel : desktopLivingNotch;
        if (card.isClosing) return;

        // Ambil dimensi kapsul standby saat ini persis sebelum tab/status notifikasi diubah
        var startW = (root.inPanel && panelCompactNotch.width > 0) ? panelCompactNotch.width : root.currentCompactWidth;
        var startH = root.cfgCompactHeight;

        // 1. Reset state penutup & pastikan tab aktif benar
        card.isClosing = false;
        var wasNotifPill = root.activeNotificationPill;

        root.activeNotificationPill = false;
        root.activeBatteryPill = false;

        if (targetTabIndex !== undefined) {
            root.currentExpandedTab = targetTabIndex;
        } else if (wasNotifPill) {
            root.currentExpandedTab = 1; // Direct jump to Notifications tab when opening from notification pill
        } else {
            root.currentExpandedTab = 0; // Default: Media Playing (Tab Utama)
        }

        if (root.inPanel) {
            // Set geometri awal persis sama dengan kapsul standby di panel
            card.targetW = startW;
            card.targetH = startH;
            card.expandedContentArea.opacity = 0.0;

            // Buka jendela surface dialog
            root.dialogSurfaceOpen = true;
            expandedDialog.visible = true;
            root.isExpanded = true;

            // Sembunyikan kapsul standby di panel (overlay menggantikan di posisi & ukuran yang sama)
            root.compactVisible = false;

            // Jalankan animasi morphing pembuka dengan start dimensions
            card.startExpand(startW, startH);
        } else {
            card.targetW = card.getTargetWidthForTab(root.currentExpandedTab, root.showLyrics);
            card.targetH = card.standardCardHeight;
            card.expandedContentArea.opacity = 1.0;
            root.isExpanded = true;
            desktopLivingNotch.startExpand(startW, startH);
        }
    }

    function expandNotch(targetTabIndex) {
        openNotch(targetTabIndex);
    }

    function closeNotch() {
        triggerCollapseSequence();
    }

    function collapseNotch() {
        triggerCollapseSequence();
    }

    function triggerCollapseSequence() {
        var card = root.inPanel ? expandedCardPanel : desktopLivingNotch;
        if (card.isClosing || !root.isExpanded) return;

        console.log("[NOTCH] Mulai penutupan atomik...");
        if (closeHandoverTimer.running) {
            closeHandoverTimer.stop();
        }
        closeWatchdogTimer.restart(); // Jalankan timer pengaman anti-deadlock
        card.startCollapse();
    }

    function toggleExpanded(targetTab) {
        var card = root.inPanel ? expandedCardPanel : desktopLivingNotch;
        if (card.isClosing || card.isOpening) return;

        if (!root.isExpanded) {
            openNotch(targetTab);
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
        visible: root.inPanel && (root.compactVisible || !root.isExpanded)
        width: panelCompactNotch.width
        height: root.cfgCompactHeight

        anchors.top: parent.top
        anchors.topMargin: root.effectiveVerticalOffset
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.cfgHorizontalOffset

        opacity: root.compactVisible ? 1.0 : 0.0
        enabled: root.compactVisible && !root.isExpanded && !(expandedCardPanel && expandedCardPanel.isClosing) && !(expandedCardPanel && expandedCardPanel.isOpening)

        CompactView {
            id: panelCompactNotch
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            notchW: root.currentCompactWidth
            notchH: root.cfgCompactHeight
            wingR: root.cfgNotchWingRadius
            cornerR: root.cfgNotchBottomRadius
            notchStyle: root.cfgNotchStyle
            islandShapeMode: root.cfgIslandShapeMode

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
            albumDominantColor: root.albumDominantColor

            miniVisBarWidth: root.cfgMiniVisBarWidth
            miniVisHeight: root.cfgMiniVisHeight
            miniVisSpacing: root.cfgMiniVisSpacing
            miniVisColorMode: root.cfgMiniVisColorMode
            miniVisCustomColor: root.cfgMiniVisCustomColor
            miniVisAlignment: root.cfgMiniVisAlignment
            miniVisRounded: root.cfgMiniVisRounded
            visualizerLevels: root.visualizerLevels
            visualizerServiceActive: root.visualizerServiceActive

            miniMusicIconEnabled: root.cfgMiniMusicIconEnabled
            miniMusicIconSize: root.cfgMiniMusicIconSize
            miniMusicIconWeight: root.cfgMiniMusicIconWeight
            miniMusicIconColorMode: root.cfgMiniMusicIconColorMode
            miniMusicIconCustomColor: root.cfgMiniMusicIconCustomColor

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
    // Ukuran window dialog statis (720x520) dengan NoBackground (tanpa frame & shadow)
    // Berada di bibir paling atas layar (y=0) sehingga siluet utuh yang melar
    // ==============================================================
    Window {
        id: expandedDialog
        width: 720
        height: 520
        color: "transparent"
        flags: Qt.FramelessWindowHint
        visible: root.dialogSurfaceOpen

        LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
        LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        LayerShellQt.Window.scope: "dynamic-island"
        LayerShellQt.Window.exclusionZone: -1
        LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand

        onActiveChanged: {
            if (!active && root.isExpanded && !expandedCardPanel.isClosing && !expandedCardPanel.isOpening) {
                console.log("[NOTCH] Focus lost terdeteksi, memicu triggerCollapseSequence()");
                root.triggerCollapseSequence();
            }
        }

        Item {
            id: fixedCanvas
            clip: false
            anchors.fill: parent
            width: 720
            height: 520

            // Klik di area kanvas transparan di luar livingNotch untuk menutup
            MouseArea {
                anchors.fill: parent
                enabled: root.dialogSurfaceOpen && root.isExpanded
                onClicked: {
                    if (!expandedCardPanel.isClosing && !expandedCardPanel.isOpening) {
                        root.triggerCollapseSequence();
                    }
                }
            }

            ExpandedNotchCard {
                id: expandedCardPanel
                visible: root.dialogSurfaceOpen
                enabled: root.dialogSurfaceOpen && root.isExpanded
                anchors.top: parent.top
                anchors.topMargin: root.isFloatingStyle ? root.effectiveVerticalOffset : 0
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: root.cfgHorizontalOffset
                isOverlayDialog: true
                compactWidth: root.currentCompactWidth
                compactHeight: root.cfgCompactHeight
                isExpanded: root.inPanel && root.isExpanded
                notchStyle: root.cfgNotchStyle
                islandShapeMode: root.cfgIslandShapeMode
                cfgNotchWingRadius: root.cfgNotchWingRadius
                cfgNotchBottomRadius: root.cfgNotchBottomRadius
                expandedBgStyle: root.cfgExpandedBgStyle
                mediaCardBgMode: root.cfgMediaCardBgMode
                lyricsBgMode: root.cfgLyricsBgMode

                cfgAccentColor: root.cfgAccentColor
                cfgBgColor: root.cfgBgColor
                cfgBorderColor: root.cfgBorderColor
                cfgExpandedWidth: root.cfgExpandedWidth
                cfgExpandedHeight: root.cfgExpandedHeight
                currentExpandedTab: root.currentExpandedTab
                showLyrics: root.showLyrics
                currentTimeString: root.currentTimeString

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
                albumDominantColor: root.albumDominantColor

                miniVisBarWidth: root.cfgMiniVisBarWidth
                miniVisHeight: root.cfgMiniVisHeight
                miniVisSpacing: root.cfgMiniVisSpacing
                miniVisColorMode: root.cfgMiniVisColorMode
                miniVisCustomColor: root.cfgMiniVisCustomColor
                miniVisAlignment: root.cfgMiniVisAlignment
                miniVisRounded: root.cfgMiniVisRounded
                visualizerLevels: root.visualizerLevels
                visualizerServiceActive: root.visualizerServiceActive

                miniMusicIconEnabled: root.cfgMiniMusicIconEnabled
                miniMusicIconSize: root.cfgMiniMusicIconSize
                miniMusicIconWeight: root.cfgMiniMusicIconWeight
                miniMusicIconColorMode: root.cfgMiniMusicIconColorMode
                miniMusicIconCustomColor: root.cfgMiniMusicIconCustomColor

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
                onRequestRetryLyrics: {
                    root.retryCount = 0;
                    retryLyricsTimer.stop();
                    root.fetchLyrics(true);
                }
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
                    root.syncLyrics();
                }
                onRequestClearAllNotifications: root.clearAllNotifications()
                onRequestRemoveNotification: (id) => root.removeNotification(id)

                onCollapseCompleted: {
                    // Sinyal kompatibilitas
                }

                onCollapseFinished: {
                    console.log("[NOTCH] Animasi ciut fisik selesai: handover ke standby pill lalu unmap dialog window.");
                    closeWatchdogTimer.stop();
                    // 1. Tampilkan standby pill di panel secara instan (0ms delay)
                    root.compactVisible = true;
                    // 2. Beri waktu Wayland compositor me-render standby pill sebelum overlay window di-unmap
                    closeHandoverTimer.restart();
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
        anchors.topMargin: root.effectiveVerticalOffset
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.cfgHorizontalOffset

        compactWidth: root.currentCompactWidth
        compactHeight: root.cfgCompactHeight
        isExpanded: (!root.inPanel) && root.isExpanded
        notchStyle: root.cfgNotchStyle
        islandShapeMode: root.cfgIslandShapeMode
        cfgNotchWingRadius: root.cfgNotchWingRadius
        cfgNotchBottomRadius: root.cfgNotchBottomRadius
        expandedBgStyle: root.cfgExpandedBgStyle
        mediaCardBgMode: root.cfgMediaCardBgMode
        lyricsBgMode: root.cfgLyricsBgMode

        cfgAccentColor: root.cfgAccentColor
        cfgBgColor: root.cfgBgColor
        cfgBorderColor: root.cfgBorderColor
        cfgExpandedWidth: root.cfgExpandedWidth
        cfgExpandedHeight: root.cfgExpandedHeight
        currentExpandedTab: root.currentExpandedTab
        showLyrics: root.showLyrics
        currentTimeString: root.currentTimeString

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
        albumDominantColor: root.albumDominantColor

        miniVisBarWidth: root.cfgMiniVisBarWidth
        miniVisHeight: root.cfgMiniVisHeight
        miniVisSpacing: root.cfgMiniVisSpacing
        miniVisColorMode: root.cfgMiniVisColorMode
        miniVisCustomColor: root.cfgMiniVisCustomColor
        miniVisAlignment: root.cfgMiniVisAlignment
        miniVisRounded: root.cfgMiniVisRounded
        visualizerLevels: root.visualizerLevels
        visualizerServiceActive: root.visualizerServiceActive

        miniMusicIconEnabled: root.cfgMiniMusicIconEnabled
        miniMusicIconSize: root.cfgMiniMusicIconSize
        miniMusicIconWeight: root.cfgMiniMusicIconWeight
        miniMusicIconColorMode: root.cfgMiniMusicIconColorMode
        miniMusicIconCustomColor: root.cfgMiniMusicIconCustomColor

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
        onRequestRetryLyrics: {
            root.retryCount = 0;
            retryLyricsTimer.stop();
            root.fetchLyrics(true);
        }
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
            root.syncLyrics();
        }
        onRequestClearAllNotifications: root.clearAllNotifications()
        onRequestRemoveNotification: (id) => root.removeNotification(id)
        onCollapseFinished: {
            root.isExpanded = false;
            desktopLivingNotch.isClosing = false;
            Qt.callLater(function() {
                desktopLivingNotch.resetGeometryAfterUnmap();
                desktopLivingNotch.expandedContentArea.opacity = 0.0;
            });
        }
    }
}

