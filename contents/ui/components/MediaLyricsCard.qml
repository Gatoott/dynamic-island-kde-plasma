import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Shapes
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
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.mediaCardBgMode !== undefined) return plasmoid.configuration.mediaCardBgMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.mediaCardBgMode !== undefined) return Plasmoid.configuration.mediaCardBgMode;
        return 0;
    }
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

        // Mode 0: Adaptive Album Tint (base color selaras dengan bodi dan sayap notch)
        // Mode 1: Glassy Translucent (Qt.rgba(0.08, 0.08, 0.12, 0.65))
        // Mode 2: Pure Pitch Dark (#09090b)
        color: {
            if (mediaCardRoot.showLyrics) {
                return "#09090b";
            }
            if (mediaCardRoot.mediaCardBgMode === 1) {
                return Qt.rgba(0.08, 0.08, 0.12, 0.65);
            } else if (mediaCardRoot.mediaCardBgMode === 2) {
                return "#09090b";
            } else {
                return (mediaCardRoot.albumArtUrl !== "")
                    ? Qt.darker(mediaCardRoot.albumDominantColor || "#121214", 2.5)
                    : "#09090b";
            }
        }
        Behavior on color { ColorAnimation { duration: 300 } }

        // Inner border highlight untuk efek glassy kaca (ditiadakan agar sisi samping & bawah bersih)
        border.width: 0

        // Mode 0 Media Player: Rona Adaptif Gradien dari Album Cover (Pusat Cahaya Album Art)
        Shape {
            anchors.fill: parent
            visible: !mediaCardRoot.showLyrics && mediaCardRoot.mediaCardBgMode === 0 && mediaCardRoot.albumArtUrl !== ""
            layer.enabled: visible
            layer.samples: 4
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

        // Mode 0 Ambient Bottom Blend: Mengalirkan gradasi halus rona album ke seluruh lengkungan bawah (Anti-Bocor Sudut)
        Rectangle {
            anchors.fill: parent
            visible: !mediaCardRoot.showLyrics && mediaCardRoot.mediaCardBgMode === 0 && mediaCardRoot.albumArtUrl !== ""
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
        anchors.bottomMargin: 24
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
                Item {
                    id: volHoverContainer
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: volHoverMa.containsMouse || volSliderMa.pressed || (typeof speakerIconMa !== "undefined" && speakerIconMa.containsMouse) ? 104 : 32
                    implicitHeight: 32

                    Behavior on implicitWidth {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: volHoverMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.10)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Item {
                                id: volSliderRow
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: volHoverContainer.implicitWidth > 60

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 3
                                    radius: 1.5
                                    color: Qt.rgba(1, 1, 1, 0.25)

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: Math.max(3, parent.width * (mediaCardRoot.currentVolumePercent / 100))
                                        radius: 1.5
                                        color: mediaCardRoot.isMuted ? Qt.rgba(1, 1, 1, 0.45) : "#ffffff"
                                    }
                                }

                                MouseArea {
                                    id: volSliderMa
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    preventStealing: true

                                    function updateMiniVol(mouse) {
                                        const pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)));
                                        mediaCardRoot.setVolumePercent(pct);
                                    }

                                    onPressed: (mouse) => updateMiniVol(mouse)
                                    onPositionChanged: (mouse) => {
                                        if (pressed) updateMiniVol(mouse);
                                    }
                                    onWheel: (wheel) => mediaCardRoot.adjustVolumeWheel(wheel)
                                }
                            }

                            Item {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Layout.alignment: Qt.AlignVCenter

                                SFSymbolIcon {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    name: (mediaCardRoot.isMuted || mediaCardRoot.currentVolumePercent === 0)
                                        ? "speaker.slash.fill"
                                        : (mediaCardRoot.currentVolumePercent < 50 ? "speaker.wave.1.fill" : "speaker.wave.2.fill")
                                    color: mediaCardRoot.isMuted ? Qt.rgba(1, 1, 1, 0.5) : "#ffffff"
                                }

                                MouseArea {
                                    id: speakerIconMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mediaCardRoot.toggleMute()
                                    onWheel: (wheel) => mediaCardRoot.adjustVolumeWheel(wheel)
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: volHoverMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        onWheel: (wheel) => mediaCardRoot.adjustVolumeWheel(wheel)
                    }
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
        anchors.leftMargin: 38
        anchors.rightMargin: 38
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

                // Baris 3: Tombol kontrol ringkas berjejer di tengah (<<, Play/Pause, >>)
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 22

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
                cacheBuffer: 80
                currentIndex: mediaCardRoot.currentLyricIndex
                preferredHighlightBegin: height * 0.5 - 12
                preferredHighlightEnd: height * 0.5 + 12
                highlightRangeMode: ListView.StrictlyEnforceRange
                highlightMoveDuration: 220

                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < count) {
                        positionViewAtIndex(currentIndex, ListView.Center);
                    }
                }
                onCountChanged: {
                    if (currentIndex >= 0 && currentIndex < count) {
                        positionViewAtIndex(currentIndex, ListView.Center);
                    }
                }

                delegate: Item {
                    width: ListView.view.width
                    height: lyricText.implicitHeight + 8

                    readonly property bool isCurrent: index === mediaCardRoot.currentLyricIndex

                    Text {
                        id: lyricText
                        width: parent.width
                        text: (modelData && modelData.text !== undefined) ? modelData.text : (modelData || "")
                        wrapMode: Text.WordWrap
                        font.pixelSize: isCurrent ? 15 : 13
                        font.bold: isCurrent
                        font.family: mediaCardRoot.lyricsFontFamily !== "" ? mediaCardRoot.lyricsFontFamily : "Inter, Roboto, sans-serif"
                        color: isCurrent ? "#ffffff" : Qt.rgba(1, 1, 1, 0.35)
                        horizontalAlignment: Text.AlignLeft
                        scale: isCurrent ? 1.02 : 1.0
                        transformOrigin: Item.Left

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150 } }
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
