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
    property string currentTimeString: "00:00"
    property string currentDateString: "Sat 18 Oct"

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
        topLeftRadius: 0
        topRightRadius: 0
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
                    topLeftRadius: 0
                    topRightRadius: 0
                    bottomLeftRadius: 22
                    bottomRightRadius: 22
                }
            }
        }
    }

    // ==============================================================
    // MODE A: STANDARD MEDIA PLAYER (Landscape Card 540x210 - Gambar 4)
    // ==============================================================
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 38
        anchors.rightMargin: 38
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 8
        visible: !mediaCardRoot.showLyrics

        // 1. Header Row (Jam/Tanggal + Status Dot + Sound Waves / Equalizer)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            spacing: 6

            // Status indicator dot
            Rectangle {
                width: 7
                height: 7
                radius: 3.5
                color: mediaCardRoot.isPlaying ? "#34c759" : Qt.rgba(1, 1, 1, 0.35)
                Layout.alignment: Qt.AlignVCenter
            }

            // Date & Time
            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: mediaCardRoot.currentDateString !== "" ? mediaCardRoot.currentDateString : "Sat 18 Oct"
                    font.pixelSize: 11
                    font.family: "Inter, Roboto, sans-serif"
                    color: "#9aa0a6"
                }

                Text {
                    text: mediaCardRoot.currentTimeString !== "" ? mediaCardRoot.currentTimeString : "9:41"
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Inter, Roboto, sans-serif"
                    color: "#ffffff"
                }
            }

            Item { Layout.fillWidth: true }

            // Audio Visualizer Equalizer icon
            AudioVisualizer {
                isPlaying: mediaCardRoot.isPlaying
                barColor: mediaCardRoot.accentColor
                barCount: 4
                barWidth: 2
                spacing: 2
                maxHeight: 10
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // 2. Middle Row: Album Art + Track Title & Artist (Gambar 4)
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

        // 3. Full-Width Timeline Progress Slider Row (Gambar 4: 2:59 [-------] -1:17)
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

    // ==============================================================
    // MODE B: SYNCED LYRICS SPLIT CARD (Landscape Card 620x220 - Gambar 3 & 5)
    // ==============================================================
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 38
        anchors.rightMargin: 38
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 14
        visible: mediaCardRoot.showLyrics

        // COLUMN 1: Compact Media Summary (~38% width, Gambar 3 & 5 - Left side)
        ColumnLayout {
            Layout.preferredWidth: 210
            Layout.fillHeight: true
            spacing: 6

            // Header Row (Jam/Tanggal + Status Dot)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                spacing: 6

                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: mediaCardRoot.isPlaying ? "#34c759" : Qt.rgba(1, 1, 1, 0.35)
                }

                Text {
                    text: (mediaCardRoot.currentDateString !== "" ? mediaCardRoot.currentDateString + " " : "") + mediaCardRoot.currentTimeString
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.family: "Inter, Roboto, sans-serif"
                    color: "#9aa0a6"
                }

                Item { Layout.fillWidth: true }
            }

            // Album Art Thumbnail & Metadata
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 52
                    height: 52
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    clip: true

                    Image {
                        id: miniAlbumArtImg
                        anchors.fill: parent
                        source: mediaCardRoot.albumArtUrl !== "" ? mediaCardRoot.albumArtUrl : ""
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

            // Mini seek slider
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8

                    Rectangle {
                        id: miniTrack
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
                                       Math.max(3, miniTrack.width * (mediaCardRoot.trackPosition / mediaCardRoot.trackLength)) : 0
                            radius: 1.5
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mediaCardRoot.trackLength > 0 && width > 0) {
                                mediaCardRoot.requestSeek((mouse.x / width) * mediaCardRoot.trackLength);
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: mediaCardRoot.formatTime(mediaCardRoot.trackPosition)
                        font.pixelSize: 9
                        color: "#9aa0a6"
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: mediaCardRoot.formatRemaining(mediaCardRoot.trackPosition, mediaCardRoot.trackLength)
                        font.pixelSize: 9
                        color: "#9aa0a6"
                    }
                }
            }

            // Mini transport controls (Gambar 3 & 5: Prev, Play/Pause, Next + Lyrics toggle)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Active lyrics bubble button (two-way toggle: clicking exits lyrics mode)
                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
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
                    width: 30
                    height: 30
                    radius: 15
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        source: "media-skip-backward"
                        color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaCardRoot.requestPrevious()
                    }
                }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: "#ffffff"

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 15
                        height: 15
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
                    width: 30
                    height: 30
                    radius: 15
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        source: "media-skip-forward"
                        color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaCardRoot.requestNext()
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Item { Layout.fillHeight: true }
        }

        // Vertical divider line
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: Qt.rgba(1, 1, 1, 0.1)
        }

        // COLUMN 2: Synced Lyrics View (~62% width, Gambar 3 & 5 - Right side)
        Item {
            id: lyricsColumn
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Top Header Row with Title and Dedicated Back Button
            RowLayout {
                id: lyricsHeaderRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 24
                z: 10

                Text {
                    text: i18n("Synced Lyrics")
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Inter, Roboto, sans-serif"
                    color: "#9aa0a6"
                }

                Item { Layout.fillWidth: true }

                // Dedicated Back Arrow / Exit Button (Gambar 3 & 5)
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: backBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        source: "go-previous"
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: backBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaCardRoot.closeLyrics()
                    }
                }
            }

            // Synced Lyrics ListView
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

                preferredHighlightBegin: height * 0.4
                preferredHighlightEnd: height * 0.6
                highlightRangeMode: ListView.StrictlyEnforceRange
                highlightMoveDuration: 280

                currentIndex: mediaCardRoot.currentLyricIndex

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
                    id: lyricDelegate
                    required property int index
                    required property var modelData

                    readonly property bool isActive: index === mediaCardRoot.currentLyricIndex
                    width: lyricsListView.width
                    implicitHeight: Math.max(26, lyricLineText.implicitHeight + 6)

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: lyricDelegate.isActive ? Qt.rgba(1, 1, 1, 0.08) : (lineHoverMa.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")
                    }

                    Text {
                        id: lyricLineText
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData && modelData.text !== undefined ? modelData.text : ""
                        font.pixelSize: lyricDelegate.isActive ? 15 : 13
                        font.bold: lyricDelegate.isActive
                        font.weight: lyricDelegate.isActive ? Font.Bold : Font.Normal
                        font.family: mediaCardRoot.lyricsFontFamily !== "" ? mediaCardRoot.lyricsFontFamily : "Inter, Roboto, sans-serif"
                        color: lyricDelegate.isActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.35)
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignLeft

                        scale: lyricDelegate.isActive ? 1.02 : 1.0
                        transformOrigin: Item.Left

                        Behavior on color {
                            ColorAnimation { duration: 180 }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                        Behavior on font.pixelSize {
                            NumberAnimation { duration: 180 }
                        }
                    }

                    MouseArea {
                        id: lineHoverMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData && modelData.time !== undefined) {
                                mediaCardRoot.requestSeek(modelData.time);
                            }
                        }
                    }
                }
            }

            // Fallback / Loading / Empty states (Proper sibling overlay, outside ListView)
            Item {
                id: emptyLyricsOverlay
                anchors.centerIn: lyricsListView
                width: lyricsColumn.width - 20
                height: 120
                visible: lyricsListView.count === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        width: 24
                        height: 24
                        source: mediaCardRoot.lyricsLoading ? "view-refresh" : "dialog-messages"
                        color: Qt.rgba(1, 1, 1, 0.4)
                    }

                    Text {
                        text: {
                            if (mediaCardRoot.lyricsLoading) return i18n("Mencari lirik...");
                            if (!mediaCardRoot.lyricsFound) return i18n("Lirik tidak tersedia");
                            return i18n("Tidak ada lirik sinkron");
                        }
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#ffffff"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: mediaCardRoot.lyricsLoading ? i18n("Mengambil dari LRCLIB...") : i18n("Putar lagu Spotify atau coba pratinjau demo")
                        font.pixelSize: 10
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#8e95a0"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        visible: !mediaCardRoot.lyricsLoading

                        Rectangle {
                            Layout.preferredWidth: 84
                            Layout.preferredHeight: 24
                            radius: 12
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
                            Layout.preferredWidth: 96
                            Layout.preferredHeight: 24
                            radius: 12
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
