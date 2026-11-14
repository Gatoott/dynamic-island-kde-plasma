import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.volume as PlasmaAudio
import "."

Item {
    id: mediaCardRoot

    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property string albumArtUrl: ""
    property real trackPosition: 0 // in seconds
    property real trackLength: 0   // in seconds
    property bool isPlaying: false
    property bool canControl: true
    property bool canGoPrevious: true
    property bool canGoNext: true

    property color accentColor: "#3daee9"
    property bool isFloatingStyle: false
    property string currentTimeString: "00:00"
    property string currentDateString: "Sat 18 Oct"
    property string clockFontFamily: ""

    property int mediaCardBgMode: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
            if (plasmoid.configuration.mediaBgStyle !== undefined) return plasmoid.configuration.mediaBgStyle;
            if (plasmoid.configuration.mediaCardBgMode !== undefined) return plasmoid.configuration.mediaCardBgMode;
        }
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration) {
            if (Plasmoid.configuration.mediaBgStyle !== undefined) return Plasmoid.configuration.mediaBgStyle;
            if (Plasmoid.configuration.mediaCardBgMode !== undefined) return Plasmoid.configuration.mediaCardBgMode;
        }
        return 2;
    }
    readonly property color currentAlbumColor: (albumDominantColor !== undefined && albumDominantColor != "" && albumDominantColor != "transparent") ? albumDominantColor : Qt.color("#3daee9")
    property int expandedBgStyle: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.expandedBgStyle !== undefined) return plasmoid.configuration.expandedBgStyle;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.expandedBgStyle !== undefined) return Plasmoid.configuration.expandedBgStyle;
        return 0;
    }
    property int lyricsBgMode: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.lyricsBgMode !== undefined) return plasmoid.configuration.lyricsBgMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.lyricsBgMode !== undefined) return Plasmoid.configuration.lyricsBgMode;
        return 1;
    }

    property bool showLyrics: false
    property var visualizerLevels: []
    property bool visualizerServiceActive: false
    property var lyricsList: []
    property int currentLyricIndex: -1
    property bool lyricsLoading: false
    property bool lyricsFound: false

    property int activeTabIndex: 0
    property string lyricsFontFamily: ""
    property int lyricsFontSize: 13
    property bool lyricsFontBold: true

    // Dynamic dominant color extracted from album art
    property color albumDominantColor: Qt.color("#1a2b3c")
    Behavior on albumDominantColor { ColorAnimation { duration: 400 } }

    readonly property bool isDragging: {
        if (typeof seekMouseArea !== "undefined" && seekMouseArea.pressed) return true;
        if (typeof miniSeekMouseArea !== "undefined" && miniSeekMouseArea.pressed) return true;
        if (typeof mainVolumeControl !== "undefined" && mainVolumeControl.isPressed) return true;
        if (typeof miniVolumeControl !== "undefined" && miniVolumeControl.isPressed) return true;
        if (typeof lyricsListView !== "undefined" && (lyricsListView.dragging || lyricsListView.flicking)) return true;
        return false;
    }

    signal requestPlayPause()
    signal requestNext()
    signal requestPrevious()
    signal requestSeek(real positionSeconds)
    signal requestToggleLyrics()
    signal requestCloseLyrics()
    signal requestRetryLyrics()
    signal requestDemoLyrics()
    signal requestSwitchTab(int tabIndex)

    function closeLyrics() {
        mediaCardRoot.showLyrics = false;
        mediaCardRoot.requestCloseLyrics();
    }

    // -------------------------------------------------------------
    // Audio Backend (Plasma 6 Native PulseAudio / PipeWire)
    // -------------------------------------------------------------
    PlasmaAudio.SinkModel {
        id: sinkModel
        readonly property var preferredSink: mediaCardRoot.defaultSink
        onDataChanged: mediaCardRoot.updateDefaultSink()
        onRowsInserted: mediaCardRoot.updateDefaultSink()
        onRowsRemoved: mediaCardRoot.updateDefaultSink()
        onModelReset: mediaCardRoot.updateDefaultSink()
        onCountChanged: mediaCardRoot.updateDefaultSink()
        Component.onCompleted: mediaCardRoot.updateDefaultSink()
    }

    property var defaultSink: null

    function updateDefaultSink() {
        if (!sinkModel || sinkModel.count === 0) return;
        var defaultRole = sinkModel.role("Default");
        var pulseObjectRole = sinkModel.role("PulseObject");
        for (var i = 0; i < sinkModel.count; ++i) {
            var idx = sinkModel.index(i, 0);
            var isDef = (defaultRole !== -1) ? sinkModel.data(idx, defaultRole) : false;
            if (isDef === true || isDef === 1 || isDef === "true") {
                defaultSink = (pulseObjectRole !== -1) ? sinkModel.data(idx, pulseObjectRole) : null;
                return;
            }
        }
        if (sinkModel.count > 0 && !defaultSink && pulseObjectRole !== -1) {
            defaultSink = sinkModel.data(sinkModel.index(0, 0), pulseObjectRole);
        }
    }

    readonly property real normalVolume: (defaultSink && defaultSink.baseVolume > 0) ? defaultSink.baseVolume : 65536
    readonly property real currentVolumePercent: defaultSink 
        ? Math.round((defaultSink.volume / normalVolume) * 100) 
        : 0
    readonly property int currentVolumePct: currentVolumePercent
    readonly property bool isMuted: defaultSink ? defaultSink.muted : false

    function setVolumePercent(val) {
        if (!defaultSink) return;
        const clamped = Math.max(0, Math.min(100, Math.round(val)));
        defaultSink.volume = Math.round((clamped / 100) * normalVolume);
        if (defaultSink.muted && clamped > 0) {
            defaultSink.muted = false;
        }
    }

    function toggleMute() {
        if (!defaultSink) return;
        defaultSink.muted = !defaultSink.muted;
    }

    function adjustVolumeWheel(wheel) {
        if (!defaultSink) return;
        var step = normalVolume * 0.05;
        if (wheel.angleDelta.y > 0) {
            defaultSink.volume = Math.min(defaultSink.volume + step, normalVolume);
            if (defaultSink.muted) defaultSink.muted = false;
        } else {
            defaultSink.volume = Math.max(defaultSink.volume - step, 0);
        }
    }

    function formatTime(totalSeconds) {
        if (isNaN(totalSeconds) || totalSeconds < 0) return "0:00";
        const m = Math.floor(totalSeconds / 60);
        const s = Math.floor(totalSeconds % 60);
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    function formatRemaining(elapsed, total) {
        if (isNaN(total) || total <= 0) return "-0:00";
        const rem = Math.max(0, total - elapsed);
        const m = Math.floor(rem / 60);
        const s = Math.floor(rem % 60);
        return "-" + m + ":" + (s < 10 ? "0" + s : s);
    }

    // --- Dynamic Color Extraction from Album Art ---
    Canvas {
        id: colorSamplerCanvas
        width: 16
        height: 16
        visible: false
        property string imageSource: mediaCardRoot.albumArtUrl

        onImageSourceChanged: {
            if (imageSource && imageSource !== "") {
                loadImage(imageSource);
            } else {
                mediaCardRoot.albumDominantColor = Qt.color("#1a2b3c");
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
                    if (brightness > 20 && brightness < 235) {
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
                    mediaCardRoot.albumDominantColor = Qt.rgba(r / 255.0, g / 255.0, b / 255.0, 1.0);
                } else {
                    mediaCardRoot.albumDominantColor = Qt.color("#1d2a3a");
                }
            } catch (e) {
                mediaCardRoot.albumDominantColor = Qt.color("#1d2a3a");
            }
        }
    }

    // --- 1. LAYER BACKGROUND MULTI-MODE ---
    Rectangle {
        id: mediaCardBackground
        anchors.fill: parent
        topLeftRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
        topRightRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
        bottomLeftRadius: 22
        bottomRightRadius: 22
        clip: true

        // Mode 0: Pure Dark (#09090b)
        // Mode 1: Full Adaptive Tint (base color selaras dengan rona album)
        // Mode 2: Album Bottom Gradient (Atas #09090b -> Bawah Warna Cover Album)
        // Mode 3: Glassy Acrylic Blur / Translucent (Qt.rgba(0.08, 0.08, 0.12, 0.65))
        color: {
            if (mediaCardRoot.showLyrics) {
                return "#09090b";
            }
            if (mediaCardRoot.mediaCardBgMode === 3) {
                return Qt.rgba(0.08, 0.08, 0.12, 0.65);
            } else if (mediaCardRoot.mediaCardBgMode === 1) {
                return (mediaCardRoot.albumArtUrl !== "")
                    ? Qt.darker(mediaCardRoot.currentAlbumColor, 2.5)
                    : "#09090b";
            } else {
                return "#09090b";
            }
        }
        Behavior on color { ColorAnimation { duration: 300 } }

        // Inner border highlight untuk efek glassy kaca (ditiadakan agar sisi samping & bawah bersih)
        border.width: 0

        // Mode 1 Media Player: Rona Adaptif Gradien dari Album Cover (Pusat Cahaya Album Art)
        Shape {
            anchors.fill: parent
            visible: !mediaCardRoot.showLyrics && mediaCardRoot.mediaCardBgMode === 1 && mediaCardRoot.albumArtUrl !== ""
            opacity: 0.75

            ShapePath {
                strokeWidth: 0
                fillGradient: RadialGradient {
                    centerX: mediaCardBackground.width * 0.25
                    centerY: mediaCardBackground.height * 0.5
                    centerRadius: mediaCardBackground.width * 0.75
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(mediaCardRoot.albumDominantColor.r, mediaCardRoot.albumDominantColor.g, mediaCardRoot.albumDominantColor.b, 0.48)
                    }
                    GradientStop {
                        position: 0.65
                        color: Qt.rgba(mediaCardRoot.albumDominantColor.r * 0.25, mediaCardRoot.albumDominantColor.g * 0.25, mediaCardRoot.albumDominantColor.b * 0.25, 0.14)
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
                PathRectangle {
                    x: 0
                    y: 0
                    width: mediaCardBackground.width
                    height: mediaCardBackground.height
                    topLeftRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
                    topRightRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
                    bottomLeftRadius: 22
                    bottomRightRadius: 22
                }
            }
        }

        // Mode 1 Ambient Bottom Blend: Mengalirkan gradasi halus rona album ke seluruh lengkungan bawah (Anti-Bocor Sudut)
        Rectangle {
            anchors.fill: parent
            visible: !mediaCardRoot.showLyrics && mediaCardRoot.mediaCardBgMode === 1 && mediaCardRoot.albumArtUrl !== ""
            topLeftRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
            topRightRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
            bottomLeftRadius: 22
            bottomRightRadius: 22
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.40; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(mediaCardRoot.albumDominantColor.r, mediaCardRoot.albumDominantColor.g, mediaCardRoot.albumDominantColor.b, 0.22) }
            }
        }

        // Mode 2 Media Player: Layer Gradasi Vertikal (Atas Hitam Pekat -> Bawah Warna Cover Album)
        Rectangle {
            id: bottomGradientLayer
            anchors.fill: parent
            visible: !mediaCardRoot.showLyrics && mediaCardRoot.mediaCardBgMode === 2 && mediaCardRoot.albumArtUrl !== ""
            topLeftRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
            topRightRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
            bottomLeftRadius: 22
            bottomRightRadius: 22
            clip: true

            gradient: Gradient {
                // Posisi 0.0 (Paling Atas): Hitam pekat agar menyatu dengan notch/panel
                GradientStop { 
                    position: 0.0 
                    color: "#09090b" 
                }
                // Transisi halus di tengah
                GradientStop { 
                    position: 0.45 
                    color: Qt.darker(mediaCardRoot.currentAlbumColor, 2.4) 
                }
                // Posisi 1.0 (Paling Bawah): Warna cover album aktif
                GradientStop { 
                    position: 1.0 
                    color: Qt.rgba(mediaCardRoot.currentAlbumColor.r, mediaCardRoot.currentAlbumColor.g, mediaCardRoot.currentAlbumColor.b, 0.75) 
                }
            }
        }

        // Mode Lirik: Gradasi Rona Album di Bawah (Aktif jika showLyrics && lyricsBgMode === 1)
        Rectangle {
            anchors.fill: parent
            visible: mediaCardRoot.showLyrics && mediaCardRoot.lyricsBgMode === 1
            topLeftRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
            topRightRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
            bottomLeftRadius: 22
            bottomRightRadius: 22
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.35; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(mediaCardRoot.albumDominantColor.r, mediaCardRoot.albumDominantColor.g, mediaCardRoot.albumDominantColor.b, 0.45) }
            }
        }
    }

    // ==============================================================
    // MODE A: CANOPY / MACOS ISLAND MEDIA PLAYER
    // ==============================================================
    Item {
        id: standardMediaView
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 38
        anchors.leftMargin: 46
        anchors.rightMargin: 46
        visible: !mediaCardRoot.showLyrics

        ColumnLayout {
            anchors.fill: parent
            spacing: 6

            // A. Baris Atas: Album Art + Detail Lagu + Visualizer Wave
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Cover Album Rounded (46x46, radius: 10)
                Rectangle {
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 46
                    radius: 10
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    clip: true

                    Image {
                        id: albumArtImg
                        anchors.fill: parent
                        source: mediaCardRoot.albumArtUrl !== "" ? mediaCardRoot.albumArtUrl : ""
                        sourceSize.width: 104
                        sourceSize.height: 104
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready && source != ""
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: "media-optical-audio"
                        color: Qt.rgba(1, 1, 1, 0.35)
                        visible: !albumArtImg.visible
                    }
                }

                // Teks Lagu, Badge & Artis
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true

                        Text {
                            text: mediaCardRoot.trackTitle !== "" ? mediaCardRoot.trackTitle : i18n("No Media Playing")
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.bold: true
                            font.family: "Inter, Roboto, sans-serif"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: {
                            var a = mediaCardRoot.trackArtist !== "" ? mediaCardRoot.trackArtist : i18n("Play music from Spotify or browser");
                            if (mediaCardRoot.trackAlbum !== "" && mediaCardRoot.trackAlbum !== mediaCardRoot.trackTitle) {
                                a += " • " + mediaCardRoot.trackAlbum;
                            }
                            return a;
                        }
                        color: Qt.rgba(1, 1, 1, 0.65)
                        font.pixelSize: 12
                        font.family: "Inter, Roboto, sans-serif"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Audio Visualizer Wave Mini di Kanan
                AudioVisualizer {
                    id: canopyVisualizer
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    isPlaying: mediaCardRoot.isPlaying
                    barColor: "#ffffff"
                    barCount: 4
                    barWidth: 2.5
                    spacing: 2.5
                    maxHeight: 16
                    levels: mediaCardRoot.visualizerLevels
                    realAudioActive: mediaCardRoot.visualizerServiceActive
                }
            }

            // B. Baris Tengah: Full Width Progress Bar & Durasi
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                // Slider / Progress Track
                Item {
                    id: mainProgressBarItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10

                    Rectangle {
                        id: mainProgressTrack
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 3
                        radius: 1.5
                        color: Qt.rgba(1, 1, 1, 0.20)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: mediaCardRoot.trackLength > 0 ?
                                       Math.max(3, mainProgressTrack.width * (mediaCardRoot.trackPosition / mediaCardRoot.trackLength)) : 0
                            radius: 1.5
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        id: seekMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true

                        function seek(mouse) {
                            if (mediaCardRoot.trackLength > 0 && width > 0) {
                                const ratio = Math.max(0, Math.min(1, mouse.x / width));
                                mediaCardRoot.requestSeek(ratio * mediaCardRoot.trackLength);
                            }
                        }

                        onClicked: (mouse) => seek(mouse)
                        onPositionChanged: (mouse) => {
                            if (pressed) seek(mouse);
                        }
                    }
                }

                // Waktu Berjalan vs Sisa Durasi
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: mediaCardRoot.formatTime(mediaCardRoot.trackPosition)
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: 10
                        font.family: "Inter, Roboto, sans-serif"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: mediaCardRoot.formatRemaining(mediaCardRoot.trackPosition, mediaCardRoot.trackLength)
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: 10
                        font.family: "Inter, Roboto, sans-serif"
                    }
                }
            }

            // C. Baris Bawah: Tombol Kontrol Media Terpusat
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 38

                // Volume Button with Hover Slider on Left side
                VolumeHoverControl {
                    id: mainVolumeControl
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    controlHeight: 32
                    collapsedWidth: 32
                    expandedWidth: 104
                    iconSize: 14
                    currentVolumePercent: mediaCardRoot.currentVolumePercent
                    isMuted: mediaCardRoot.isMuted
                    onRequestSetVolume: (pct) => mediaCardRoot.setVolumePercent(pct)
                    onRequestToggleMute: () => mediaCardRoot.toggleMute()
                    onRequestAdjustVolume: (wheel) => mediaCardRoot.adjustVolumeWheel(wheel)
                }

                // Centered Transport Controls (Prev, Play/Pause White Pill, Next)
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 18

                    // Previous Button (<<)
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: prevMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : "transparent"

                        SFSymbolIcon {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            name: "backward.fill"
                            color: "#ffffff"
                            opacity: mediaCardRoot.canGoPrevious ? 1.0 : 0.4
                        }

                        MouseArea {
                            id: prevMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: mediaCardRoot.canGoPrevious
                            onClicked: mediaCardRoot.requestPrevious()
                        }
                    }

                    // Play / Pause Button (Bulat / Pill Elegan Putih Kontras)
                    Rectangle {
                        width: 38
                        height: 38
                        radius: 19
                        color: playMa.containsMouse ? "#f0f0f0" : "#ffffff"

                        SFSymbolIcon {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            name: mediaCardRoot.isPlaying ? "pause.fill" : "play.fill"
                            color: "#111418"
                        }

                        MouseArea {
                            id: playMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: mediaCardRoot.canControl
                            onClicked: mediaCardRoot.requestPlayPause()
                        }
                    }

                    // Next Button (>>)
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: nextMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : "transparent"

                        SFSymbolIcon {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            name: "forward.fill"
                            color: "#ffffff"
                            opacity: mediaCardRoot.canGoNext ? 1.0 : 0.4
                        }

                        MouseArea {
                            id: nextMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: mediaCardRoot.canGoNext
                            onClicked: mediaCardRoot.requestNext()
                        }
                    }
                }

                // Output / Lyrics Switch Toggle Button in Right Corner
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    radius: 16
                    color: lyricsToggleMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)

                    SFSymbolIcon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        name: "quote.bubble.fill"
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: lyricsToggleMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaCardRoot.showLyrics) {
                                mediaCardRoot.closeLyrics();
                            } else {
                                mediaCardRoot.requestToggleLyrics();
                            }
                        }
                    }
                }
            }
        }
    }

    // ==============================================================
    // MODE B: SYNCED LYRICS SPLIT CARD (Landscape Split 640x220 - Gambar 3)
    // ==============================================================
    Item {
        id: lyricsSplitView
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        visible: mediaCardRoot.showLyrics
        clip: true

        // Jam & Tanggal Rata Kiri di Pojok Kiri Atas Mode Lirik
        ColumnLayout {
            id: lyricsClockContainer
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 4
            spacing: 1
            z: 10

            Text {
                text: mediaCardRoot.currentTimeString !== "" ? mediaCardRoot.currentTimeString : "00:00"
                font.bold: true
                font.pixelSize: 13
                font.family: mediaCardRoot.clockFontFamily !== "" ? mediaCardRoot.clockFontFamily : "Inter, Roboto, sans-serif"
                color: "#ffffff"
                horizontalAlignment: Text.AlignLeft
            }

            Text {
                text: mediaCardRoot.currentDateString !== "" ? mediaCardRoot.currentDateString : ""
                font.pixelSize: 10
                font.family: mediaCardRoot.clockFontFamily !== "" ? mediaCardRoot.clockFontFamily : "Inter, Roboto, sans-serif"
                color: Qt.rgba(1, 1, 1, 0.65)
                horizontalAlignment: Text.AlignLeft
                visible: text !== ""
            }
        }

        // --- KOLOM KIRI (Mini Media Controls, ~44% lebar) ---
        Item {
            id: leftPlayerColumn
            anchors.top: parent.top
            anchors.topMargin: 30 // Ruang aman agar tidak bertumpukan dengan jam di pojok kiri atas
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width * 0.44

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Baris 1: Cover album mini (42x42 rounded 10), judul lagu (bold), artis
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        clip: true

                        Image {
                            id: miniAlbumArtImg
                            anchors.fill: parent
                            source: mediaCardRoot.albumArtUrl !== "" ? mediaCardRoot.albumArtUrl : ""
                            sourceSize.width: 84
                            sourceSize.height: 84
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready && source != ""
                        }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            source: "media-optical-audio"
                            color: Qt.rgba(1, 1, 1, 0.35)
                            visible: !miniAlbumArtImg.visible
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: mediaCardRoot.trackTitle !== "" ? mediaCardRoot.trackTitle : i18n("No Media Playing")
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#ffffff"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: mediaCardRoot.trackArtist !== "" ? mediaCardRoot.trackArtist : i18n("Unknown Artist")
                            font.pixelSize: 11
                            font.family: "Inter, Roboto, sans-serif"
                            color: Qt.rgba(1, 1, 1, 0.65)
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                // Baris 2: Mini Timeline (Elapsed, Progress Bar, Remaining)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: mediaCardRoot.formatTime(mediaCardRoot.trackPosition)
                        font.pixelSize: 10
                        font.family: "Inter, Roboto, sans-serif"
                        color: Qt.rgba(1, 1, 1, 0.65)
                    }

                    Item {
                        id: miniProgressBarItem
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12

                        Rectangle {
                            id: miniProgressTrack
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 3
                            radius: 1.5
                            color: Qt.rgba(1, 1, 1, 0.20)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: mediaCardRoot.trackLength > 0 ?
                                           Math.max(3, miniProgressTrack.width * (mediaCardRoot.trackPosition / mediaCardRoot.trackLength)) : 0
                                radius: 1.5
                                color: "#ffffff"
                            }
                        }

                        MouseArea {
                            id: miniSeekMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true

                            function seek(mouse) {
                                if (mediaCardRoot.trackLength > 0 && width > 0) {
                                    const ratio = Math.max(0, Math.min(1, mouse.x / width));
                                    mediaCardRoot.requestSeek(ratio * mediaCardRoot.trackLength);
                                }
                            }

                            onClicked: (mouse) => seek(mouse)
                            onPositionChanged: (mouse) => {
                                if (pressed) seek(mouse);
                            }
                        }
                    }

                    Text {
                        text: mediaCardRoot.formatRemaining(mediaCardRoot.trackPosition, mediaCardRoot.trackLength)
                        font.pixelSize: 10
                        font.family: "Inter, Roboto, sans-serif"
                        color: Qt.rgba(1, 1, 1, 0.65)
                    }
                }

                // Baris 3: Tombol kontrol ringkas (<<, Play/Pause, >>) + Volume
                Item {
                    id: miniControlsContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    RowLayout {
                        id: miniTransportRow
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        spacing: 14

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: prevMiniMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

                            SFSymbolIcon {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                name: "backward.fill"
                                color: "#ffffff"
                                opacity: mediaCardRoot.canGoPrevious ? 1.0 : 0.4
                            }

                            MouseArea {
                                id: prevMiniMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: mediaCardRoot.canGoPrevious
                                onClicked: mediaCardRoot.requestPrevious()
                            }
                        }

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: playMiniMa.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"

                            SFSymbolIcon {
                                anchors.centerIn: parent
                                width: 17
                                height: 17
                                name: mediaCardRoot.isPlaying ? "pause.fill" : "play.fill"
                                color: "#ffffff"
                            }

                            MouseArea {
                                id: playMiniMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: mediaCardRoot.canControl
                                onClicked: mediaCardRoot.requestPlayPause()
                            }
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: nextMiniMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

                            SFSymbolIcon {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                name: "forward.fill"
                                color: "#ffffff"
                                opacity: mediaCardRoot.canGoNext ? 1.0 : 0.4
                            }

                            MouseArea {
                                id: nextMiniMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: mediaCardRoot.canGoNext
                                onClicked: mediaCardRoot.requestNext()
                            }
                        }
                    }

                    // Volume Hover Control di mode lirik
                    VolumeHoverControl {
                        id: miniVolumeControl
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        controlHeight: 28
                        collapsedWidth: 28
                        expandedWidth: 84
                        iconSize: 13
                        currentVolumePercent: mediaCardRoot.currentVolumePercent
                        isMuted: mediaCardRoot.isMuted
                        onRequestSetVolume: (pct) => mediaCardRoot.setVolumePercent(pct)
                        onRequestToggleMute: () => mediaCardRoot.toggleMute()
                        onRequestAdjustVolume: (wheel) => mediaCardRoot.adjustVolumeWheel(wheel)
                    }
                }
            }
        }

        // --- KOLOM KANAN (Daftar Lirik Tersinkronisasi, ~56% lebar, tanpa border vertikal) ---
        Item {
            id: rightLyricsColumn
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: leftPlayerColumn.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            clip: true

            // Tombol kembali ke mode media player biasa (✕) floating di sudut kanan atas
            MouseArea {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -2
                width: 22
                height: 22
                z: 10
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: mediaCardRoot.closeLyrics()

                Rectangle {
                    anchors.fill: parent
                    radius: 11
                    color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.06)

                    SFSymbolIcon {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        name: "xmark"
                        color: parent.parent.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6)
                    }
                }
            }

            // ListView Lirik Berjalan (Pusat vertikal di tengah, auto-scroll halus)
            ListView {
                id: lyricsListView
                anchors.fill: parent
                clip: true
                spacing: 6
                model: mediaCardRoot.lyricsList
                reuseItems: true
                cacheBuffer: 240
                currentIndex: mediaCardRoot.currentLyricIndex
                highlightRangeMode: ListView.NoHighlightRange
                highlightMoveDuration: 0
                topMargin: Math.round(height * 0.5 - 14)
                bottomMargin: Math.round(height * 0.5 - 14)

                property int lastLyricIndex: -1

                NumberAnimation {
                    id: scrollAnimation
                    target: lyricsListView
                    property: "contentY"
                    duration: 380
                    easing.type: Easing.OutCubic
                }

                function scrollToCurrentIndex(newIdx) {
                    if (newIdx < 0 || newIdx >= count) return;
                    if (lyricsListView.dragging || lyricsListView.flicking) return;

                    var prevIdx = lastLyricIndex;
                    lastLyricIndex = newIdx;

                    // Pindah banyak baris sekaligus (seek, klik baris, ganti lagu) atau inisialisasi awal
                    if (prevIdx < 0 || Math.abs(newIdx - prevIdx) > 3) {
                        scrollAnimation.stop();
                        positionViewAtIndex(newIdx, ListView.Center);
                        return;
                    }

                    // Pindah baris berdekatan (playback normal): scroll mulus ala Apple Music
                    var it = itemAtIndex(newIdx);
                    if (!it) {
                        scrollAnimation.stop();
                        positionViewAtIndex(newIdx, ListView.Center);
                        return;
                    }

                    var rawTargetY = it.y + (it.height / 2) - (height / 2);
                    var minY = -topMargin;
                    var maxY = Math.max(minY, contentHeight + bottomMargin - height);
                    var targetY = Math.max(minY, Math.min(maxY, rawTargetY));

                    if (Math.abs(targetY - contentY) < 0.5) return;

                    scrollAnimation.stop();
                    scrollAnimation.from = contentY;
                    scrollAnimation.to = targetY;
                    scrollAnimation.restart();
                }

                onCurrentIndexChanged: {
                    scrollToCurrentIndex(currentIndex);
                }

                onCountChanged: {
                    scrollAnimation.stop();
                    lastLyricIndex = currentIndex;
                    if (currentIndex >= 0 && currentIndex < count) {
                        positionViewAtIndex(currentIndex, ListView.Center);
                    }
                }

                Connections {
                    target: mediaCardRoot
                    function onShowLyricsChanged() {
                        if (mediaCardRoot.showLyrics) {
                            scrollAnimation.stop();
                            lyricsListView.lastLyricIndex = -1;
                            if (lyricsListView.currentIndex >= 0 && lyricsListView.currentIndex < lyricsListView.count) {
                                lyricsListView.positionViewAtIndex(lyricsListView.currentIndex, ListView.Center);
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    Qt.callLater(() => {
                        if (currentIndex >= 0 && currentIndex < count) {
                            positionViewAtIndex(currentIndex, ListView.Center);
                        }
                    });
                }

                delegate: Item {
                    id: lyricDelegate
                    width: ListView.view.width
                    height: lyricText.implicitHeight + 8

                    readonly property int lineDiff: mediaCardRoot.currentLyricIndex >= 0 ? (index - mediaCardRoot.currentLyricIndex) : 0
                    readonly property int dist: mediaCardRoot.currentLyricIndex >= 0 ? Math.abs(index - mediaCardRoot.currentLyricIndex) : 0
                    readonly property bool isCurrent: mediaCardRoot.currentLyricIndex >= 0 && dist === 0

                    // Blur simetris bertingkat gaya Apple Music: baris aktif tajam,
                    // baris lampau (di atas) dan mendatang (di bawah) makin jauh makin blur
                    readonly property real rawBlur: {
                        if (mediaCardRoot.currentLyricIndex < 0 || dist === 0) return 0.0;
                        if (dist === 1) return 0.20;
                        if (dist === 2) return 0.42;
                        if (dist === 3) return 0.65;
                        return 0.85;
                    }
                    property real animatedBlur: rawBlur
                    Behavior on animatedBlur {
                        NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
                    }

                    // Warna redup simetris: baris aktif #ffffff,
                    // makin jauh dari baris aktif (atas & bawah) makin redup
                    readonly property color targetColor: {
                        if (mediaCardRoot.currentLyricIndex < 0 || dist === 0) return "#ffffff";
                        if (dist === 1) return Qt.rgba(1, 1, 1, 0.65);
                        if (dist === 2) return Qt.rgba(1, 1, 1, 0.45);
                        if (dist === 3) return Qt.rgba(1, 1, 1, 0.28);
                        return Qt.rgba(1, 1, 1, 0.15);
                    }

                    Text {
                        id: lyricText
                        width: parent.width
                        text: (modelData && modelData.text !== undefined) ? modelData.text : (modelData || "")
                        wrapMode: Text.WordWrap
                        font.pixelSize: mediaCardRoot.lyricsFontSize > 0 ? mediaCardRoot.lyricsFontSize : 13
                        font.bold: mediaCardRoot.lyricsFontBold
                        font.family: mediaCardRoot.lyricsFontFamily !== "" ? mediaCardRoot.lyricsFontFamily : "Inter, Roboto, sans-serif"
                        color: lyricDelegate.targetColor
                        horizontalAlignment: Text.AlignLeft
                        scale: lyricDelegate.isCurrent ? 1.05 : 1.0
                        transformOrigin: Item.Left

                        // GPU Shader blur hanya aktif saat baris memiliki blur (> 0.01)
                        layer.enabled: lyricDelegate.animatedBlur > 0.01
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: lyricDelegate.animatedBlur
                            blurMax: 16
                        }

                        Behavior on color { ColorAnimation { duration: 380; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData && modelData.time !== undefined) {
                                mediaCardRoot.requestSeek(modelData.time);
                            } else if (modelData && modelData.timeMs !== undefined) {
                                mediaCardRoot.requestSeek(modelData.timeMs / 1000.0);
                            }
                        }
                    }
                }

                // Pesan jika lirik belum tersedia
                Item {
                    anchors.centerIn: parent
                    width: parent.width - 20
                    height: 80
                    visible: lyricsListView.count === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: mediaCardRoot.lyricsLoading ? i18n("Memuat lirik...") : (mediaCardRoot.lyricsFound ? i18n("Tidak ada lirik sinkron") : i18n("Lirik tidak ditemukan"))
                            color: Qt.rgba(1, 1, 1, 0.7)
                            font.pixelSize: 12
                            font.bold: true
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8
                            visible: !mediaCardRoot.lyricsLoading

                            Rectangle {
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 22
                                radius: 11
                                color: Qt.rgba(1, 1, 1, 0.14)

                                Text {
                                    anchors.centerIn: parent
                                    text: i18n("Coba Lagi")
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#ffffff"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mediaCardRoot.requestRetryLyrics()
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 90
                                Layout.preferredHeight: 22
                                radius: 11
                                color: Qt.rgba(1, 1, 1, 0.14)

                                Text {
                                    anchors.centerIn: parent
                                    text: i18n("Contoh Lirik")
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#ffffff"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mediaCardRoot.requestDemoLyrics()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
