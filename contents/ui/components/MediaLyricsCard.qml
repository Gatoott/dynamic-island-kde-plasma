import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.volume as Vol
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

    readonly property var sink: (typeof Vol !== "undefined" && Vol.PreferredDevice) ? Vol.PreferredDevice.sink : null
    readonly property int currentVolumePct: sink ? Math.round(sink.volume / Vol.PulseAudio.NormalVolume * 100) : 70

    function setVolumePercent(val) {
        if (!sink) return;
        const clamped = Math.max(0, Math.min(100, Math.round(val)));
        sink.volume = Math.round(clamped * Vol.PulseAudio.NormalVolume / 100);
        if (sink.muted && clamped > 0) {
            sink.muted = false;
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

    // --- Rounded Adaptive Background ("Lyrics in your album's colors") ---
    Rectangle {
        id: albumTintBackground
        anchors.fill: parent
        topLeftRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
        topRightRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
        bottomLeftRadius: 22
        bottomRightRadius: 22
        clip: true
        color: "#0a0c10"

        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            opacity: mediaCardRoot.showLyrics ? 0.92 : 0.70
            Behavior on opacity { NumberAnimation { duration: 250 } }

            ShapePath {
                strokeWidth: 0
                fillGradient: RadialGradient {
                    centerX: mediaCardRoot.width * 0.25
                    centerY: mediaCardRoot.height * 0.5
                    centerRadius: mediaCardRoot.width * 0.75
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(mediaCardRoot.albumDominantColor.r, mediaCardRoot.albumDominantColor.g, mediaCardRoot.albumDominantColor.b, 0.45)
                    }
                    GradientStop {
                        position: 0.65
                        color: Qt.rgba(mediaCardRoot.albumDominantColor.r * 0.25, mediaCardRoot.albumDominantColor.g * 0.25, mediaCardRoot.albumDominantColor.b * 0.25, 0.12)
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
                PathRectangle {
                    x: 0
                    y: 0
                    width: albumTintBackground.width
                    height: albumTintBackground.height
                    topLeftRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
                    topRightRadius: mediaCardRoot.isFloatingStyle ? 22 : 0
                    bottomLeftRadius: 22
                    bottomRightRadius: 22
                }
            }
        }
    }

    // --------------------------------------------------------------
    // 1. CENTERED NOTCH-STYLE CLOCK HEADER (Shared across both modes)
    // --------------------------------------------------------------
    Item {
        id: headerClockContainer
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        height: headerClockColumn.implicitHeight
        z: 5

        Column {
            id: headerClockColumn
            anchors.centerIn: parent
            spacing: 1

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                // Status dot hijau saat playing
                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: "#22c55e"
                    anchors.verticalCenter: parent.verticalCenter
                    visible: mediaCardRoot.isPlaying
                }

                // Teks Jam Utama: Ukuran lebih besar & bold ala Notch
                Text {
                    id: headerClockText
                    text: mediaCardRoot.currentTimeString !== "" ? mediaCardRoot.currentTimeString : "00:00"
                    color: "#ffffff"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: mediaCardRoot.clockFontFamily !== "" ? mediaCardRoot.clockFontFamily : "Inter, Roboto, sans-serif"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Teks Tanggal di bawah jam
            Text {
                id: headerDateText
                text: mediaCardRoot.currentDateString !== "" ? mediaCardRoot.currentDateString : ""
                color: Qt.rgba(1, 1, 1, 0.65)
                font.pixelSize: 10
                font.family: mediaCardRoot.clockFontFamily !== "" ? mediaCardRoot.clockFontFamily : "Inter, Roboto, sans-serif"
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
            }
        }
    }

    // Audio Visualizer on the right in Mode A
    AudioVisualizer {
        id: modeAVisualizer
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: headerClockContainer.verticalCenter
        visible: !mediaCardRoot.showLyrics
        isPlaying: mediaCardRoot.isPlaying
        barColor: mediaCardRoot.accentColor
        barCount: 4
        barWidth: 2
        spacing: 2
        maxHeight: 10
        z: 5
    }

    // ==============================================================
    // MODE A: STANDARD MEDIA PLAYER (Landscape Card 540x210 - Gambar 4)
    // ==============================================================
    Item {
        id: standardMediaView
        anchors.top: headerClockContainer.bottom
        anchors.topMargin: 4
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24 // Sisakan ruang untuk pagination dots di bawah
        anchors.left: parent.left
        anchors.leftMargin: 44   // Internal padding agar kontrol/artwork tidak tertabrak tombol panah melayang
        anchors.right: parent.right
        anchors.rightMargin: 44  // Internal padding agar slider volume tidak tertabrak tombol panah melayang
        visible: !mediaCardRoot.showLyrics

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            // 1. Middle Row: Album Art + Track Title & Artist (Gambar 4)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Left: Album Art (Rounded square)
                Rectangle {
                    width: 52
                    height: 52
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.14)
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

                // Right of Album Art: Title + Artist/Album
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // Track Title (Bold)
                    Text {
                        text: mediaCardRoot.trackTitle !== "" ? mediaCardRoot.trackTitle : i18n("No Media Playing")
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#ffffff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Artist & Album
                    Text {
                        text: {
                            var a = mediaCardRoot.trackArtist !== "" ? mediaCardRoot.trackArtist : i18n("Play music from Spotify or browser");
                            if (mediaCardRoot.trackAlbum !== "") a += " - " + mediaCardRoot.trackAlbum;
                            return a;
                        }
                        font.pixelSize: 11
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#9aa0a6"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // 2. Full-Width Timeline Progress Slider Row (Gambar 4: 2:59 [-------] -1:17)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: mediaCardRoot.formatTime(mediaCardRoot.trackPosition)
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.family: "Inter, Roboto, sans-serif"
                    color: "#9aa0a6"
                }

                Item {
                    id: mainProgressBarItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 12

                    Rectangle {
                        id: mainProgressTrack
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.2)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: mediaCardRoot.trackLength > 0 ?
                                       Math.max(4, mainProgressTrack.width * (mediaCardRoot.trackPosition / mediaCardRoot.trackLength)) : 0
                            radius: 2
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
                    font.weight: Font.DemiBold
                    font.family: "Inter, Roboto, sans-serif"
                    color: "#9aa0a6"
                }
            }

            // 3. Transport Controls Bar (Gambar 4)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                spacing: 8

                // Lyrics Button (Left side: bubble dialog icon - Two-way toggle)
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: mediaCardRoot.showLyrics ? "#ffffff" : (lyricsToggleMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1
                    border.color: mediaCardRoot.showLyrics ? "#ffffff" : Qt.rgba(1, 1, 1, 0.1)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: "dialog-messages"
                        color: mediaCardRoot.showLyrics ? "#111418" : "#ffffff"
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

                Item { Layout.fillWidth: true }

                // Previous Button
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: prevMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 15
                        height: 15
                        source: "media-skip-backward"
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

                // Play / Pause Button (Contrasting white circular button)
                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: playMa.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.95)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: mediaCardRoot.isPlaying ? "media-playback-pause" : "media-playback-start"
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

                // Next Button
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: nextMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 15
                        height: 15
                        source: "media-skip-forward"
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

                Item { Layout.fillWidth: true }

                // Volume Button with Hover Slider (Right side: Gambar 4)
                Item {
                    id: volHoverContainer
                    implicitWidth: volHoverMa.containsMouse || volSliderRow.visible ? 116 : 36
                    implicitHeight: 36

                    Behavior on implicitWidth {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: volHoverMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.1)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            // Expanding mini volume slider
                            Item {
                                id: volSliderRow
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: volHoverContainer.implicitWidth > 60

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 4
                                    radius: 2
                                    color: Qt.rgba(1, 1, 1, 0.25)

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: Math.max(4, parent.width * (mediaCardRoot.currentVolumePct / 100))
                                        radius: 2
                                        color: "#ffffff"
                                    }
                                }

                                MouseArea {
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
                                }
                            }

                            Kirigami.Icon {
                                width: 16
                                height: 16
                                source: mediaCardRoot.currentVolumePct === 0 ? "audio-volume-muted" : "audio-volume-high"
                                color: "#ffffff"
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }

                    MouseArea {
                        id: volHoverMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
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
        anchors.top: headerClockContainer.bottom
        anchors.topMargin: 4
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24 // Sisakan ruang untuk pagination dots di bawah
        anchors.left: parent.left
        anchors.leftMargin: 44   // Internal padding agar kontrol tidak tertabrak tombol panah melayang
        anchors.right: parent.right
        anchors.rightMargin: 44  // Internal padding agar teks lirik tidak tertabrak tombol panah melayang
        visible: mediaCardRoot.showLyrics
        clip: true

        // --- KOLOM KIRI (Mini Media Controls, ~38% lebar) ---
        Item {
            id: leftPlayerColumn
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width * 0.38

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                // Cover art mini, judul lagu, artis
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 46
                        height: 46
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.14)
                        clip: true

                        Image {
                            id: miniAlbumArtImg
                            anchors.fill: parent
                            source: mediaCardRoot.albumArtUrl !== "" ? mediaCardRoot.albumArtUrl : ""
                            sourceSize.width: 92
                            sourceSize.height: 92
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
                        spacing: 1

                        Text {
                            text: mediaCardRoot.trackTitle !== "" ? mediaCardRoot.trackTitle : i18n("No Media Playing")
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#ffffff"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: mediaCardRoot.trackArtist !== "" ? mediaCardRoot.trackArtist : ""
                            font.pixelSize: 10
                            font.family: "Inter, Roboto, sans-serif"
                            color: "#9aa0a6"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                // Mini Timeline
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: mediaCardRoot.formatTime(mediaCardRoot.trackPosition)
                        font.pixelSize: 9
                        color: "#9aa0a6"
                    }

                    Item {
                        id: miniProgressBarItem
                        Layout.fillWidth: true
                        Layout.preferredHeight: 10

                        Rectangle {
                            id: miniProgressTrack
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 3
                            radius: 1.5
                            color: Qt.rgba(1, 1, 1, 0.2)

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
                        font.pixelSize: 9
                        color: "#9aa0a6"
                    }
                }

                // Mini Controls
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Active lyrics bubble button (two-way toggle: clicking exits lyrics mode)
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: "#ffffff"
                        border.width: 1
                        border.color: "#ffffff"

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: "dialog-messages"
                            color: "#111418"
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mediaCardRoot.closeLyrics()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: prevMiniMa.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.08)

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            source: "media-skip-backward"
                            color: "#ffffff"
                        }

                        MouseArea {
                            id: prevMiniMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mediaCardRoot.requestPrevious()
                        }
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: "#ffffff"

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: mediaCardRoot.isPlaying ? "media-playback-pause" : "media-playback-start"
                            color: "#111418"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mediaCardRoot.requestPlayPause()
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: nextMiniMa.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.08)

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            source: "media-skip-forward"
                            color: "#ffffff"
                        }

                        MouseArea {
                            id: nextMiniMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mediaCardRoot.requestNext()
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // Garis Pemisah Halus Antar Kolom (Divider)
        Rectangle {
            anchors.left: leftPlayerColumn.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            width: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        // --- KOLOM KANAN (Daftar Lirik Tersinkronisasi, ~62% lebar) ---
        Item {
            id: rightLyricsColumn
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: leftPlayerColumn.right
            anchors.leftMargin: 16
            anchors.right: parent.right
            clip: true

            // Header baris lirik & tombol tutup mode lirik
            Item {
                id: lyricsHeaderRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 20

                Text {
                    text: i18n("Synced Lyrics")
                    font.pixelSize: 11
                    font.bold: true
                    color: Qt.rgba(1, 1, 1, 0.45)
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Tombol kembali ke mode media player biasa (✕)
                MouseArea {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: mediaCardRoot.closeLyrics()

                    Rectangle {
                        anchors.fill: parent
                        radius: 11
                        color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Qt.rgba(1, 1, 1, 0.8)
                            font.pixelSize: 11
                        }
                    }
                }
            }

            // ListView Lirik Berjalan
            ListView {
                id: lyricsListView
                anchors.top: lyricsHeaderRow.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                clip: true
                spacing: 6
                model: mediaCardRoot.lyricsList
                currentIndex: mediaCardRoot.currentLyricIndex
                preferredHighlightBegin: height * 0.35
                preferredHighlightEnd: height * 0.55
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
                    height: lyricText.implicitHeight + 10

                    Text {
                        id: lyricText
                        width: parent.width
                        text: (modelData && modelData.text !== undefined) ? modelData.text : (modelData || "")
                        wrapMode: Text.WordWrap
                        font.pixelSize: index === mediaCardRoot.currentLyricIndex ? 15 : 13
                        font.bold: index === mediaCardRoot.currentLyricIndex
                        font.family: mediaCardRoot.lyricsFontFamily !== "" ? mediaCardRoot.lyricsFontFamily : "Inter, Roboto, sans-serif"
                        color: index === mediaCardRoot.currentLyricIndex ? "#ffffff" : Qt.rgba(1, 1, 1, 0.35)
                        horizontalAlignment: Text.AlignLeft
                        scale: index === mediaCardRoot.currentLyricIndex ? 1.02 : 1.0
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
