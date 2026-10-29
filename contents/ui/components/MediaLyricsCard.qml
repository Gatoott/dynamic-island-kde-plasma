import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.volume as Vol

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
    property string currentTimeString: ""
    property string currentDateString: ""

    property bool showLyrics: false
    property var lyricsList: []
    property int currentLyricIndex: -1
    property bool lyricsLoading: false
    property bool lyricsFound: false

    property int activeTabIndex: 0 // 0: Media, 1: Control Center

    signal requestPlayPause()
    signal requestNext()
    signal requestPrevious()
    signal requestSeek(real positionSeconds)
    signal requestToggleLyrics()
    signal requestRetryLyrics()
    signal requestSwitchTab(int tabIndex)

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

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        anchors.topMargin: 8
        spacing: 16

        // LEFT COLUMN: Media Controls & Info (Gambar 3)
        ColumnLayout {
            Layout.fillWidth: !mediaCardRoot.showLyrics
            Layout.preferredWidth: mediaCardRoot.showLyrics ? 310 : -1
            Layout.fillHeight: true
            spacing: 10

            // 1. Top Header: Status (Date/Time) + Mini Visualizer
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                spacing: 8

                RowLayout {
                    spacing: 6
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: mediaCardRoot.isPlaying ? "#34c759" : Qt.rgba(1, 1, 1, 0.4)
                    }

                    Text {
                        text: (mediaCardRoot.currentDateString !== "" ? mediaCardRoot.currentDateString + " " : "") + mediaCardRoot.currentTimeString
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#c8ccd4"
                    }
                }

                Item { Layout.fillWidth: true }

                AudioVisualizer {
                    isPlaying: mediaCardRoot.isPlaying
                    barColor: mediaCardRoot.accentColor
                    barCount: 4
                    barWidth: 2.5
                    spacing: 2
                    maxHeight: 12
                }
            }

            // 2. Center: Album Art & Track Info (Gambar 3)
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // Album Art Thumbnail
                Rectangle {
                    id: artContainer
                    width: 64
                    height: 64
                    radius: 14
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    clip: true

                    Image {
                        id: albumArtImg
                        anchors.fill: parent
                        source: mediaCardRoot.albumArtUrl !== "" ? mediaCardRoot.albumArtUrl : ""
                        sourceSize.width: 128
                        sourceSize.height: 128
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready && source != ""
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "♫"
                        font.pixelSize: 26
                        color: Qt.rgba(1, 1, 1, 0.3)
                        visible: !albumArtImg.visible
                    }
                }

                // Track & Artist Texts
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: mediaCardRoot.trackTitle !== "" ? mediaCardRoot.trackTitle : i18n("Tidak Memutar Lagu")
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#ffffff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: mediaCardRoot.trackArtist !== "" ? mediaCardRoot.trackArtist : i18n("Buka Spotify atau pemutar musik")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#9aa0a6"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: mediaCardRoot.trackAlbum !== "" ? mediaCardRoot.trackAlbum : ""
                        font.pixelSize: 11
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#6e7580"
                        elide: Text.ElideRight
                        visible: mediaCardRoot.trackAlbum !== ""
                        Layout.fillWidth: true
                    }
                }
            }

            // 3. Seek Progress Bar (Gambar 3)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Item {
                    id: progressBarItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 14

                    Rectangle {
                        id: progressTrack
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 6
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.18)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: mediaCardRoot.trackLength > 0 ?
                                       Math.max(6, progressTrack.width * (mediaCardRoot.trackPosition / mediaCardRoot.trackLength)) : 0
                            radius: 3
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

                // Time labels: elapsed and remaining (Gambar 3: -1:17)
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: mediaCardRoot.formatTime(mediaCardRoot.trackPosition)
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#9aa0a6"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: mediaCardRoot.formatRemaining(mediaCardRoot.trackPosition, mediaCardRoot.trackLength)
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#9aa0a6"
                    }
                }
            }

            // 4. Playback Controls & Aux Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                spacing: 8

                // Volume button with hover slider
                Item {
                    id: volHoverContainer
                    implicitWidth: volHoverMa.containsMouse || volSliderRow.visible ? 110 : 36
                    implicitHeight: 36

                    Behavior on implicitWidth {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: volHoverMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: mediaCardRoot.currentVolumePct === 0 ? "🔇" : "🔉"
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Expanding mini slider
                            Item {
                                id: volSliderRow
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: volHoverContainer.implicitWidth > 60

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 5
                                    radius: 2.5
                                    color: Qt.rgba(1, 1, 1, 0.25)

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: Math.max(5, parent.width * (mediaCardRoot.currentVolumePct / 100))
                                        radius: 2.5
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
                        }
                    }

                    MouseArea {
                        id: volHoverMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }

                Item { Layout.fillWidth: true }

                // Previous Track
                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: prevMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "⏮"
                        font.pixelSize: 15
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

                // Play / Pause (Large Center Button)
                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: playMa.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.95)

                    Text {
                        anchors.centerIn: parent
                        text: mediaCardRoot.isPlaying ? "⏸" : "▶"
                        font.pixelSize: 18
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

                // Next Track
                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: nextMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "⏭"
                        font.pixelSize: 15
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

                // Lyrics Toggle Button (💬)
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: mediaCardRoot.showLyrics ? mediaCardRoot.accentColor : (lyricsToggleMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08))

                    Text {
                        anchors.centerIn: parent
                        text: "💬"
                        font.pixelSize: 15
                        color: mediaCardRoot.showLyrics ? "#ffffff" : Qt.rgba(1, 1, 1, 0.8)
                    }

                    MouseArea {
                        id: lyricsToggleMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaCardRoot.requestToggleLyrics()
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // 5. Bottom Pagination Dots (Gambar 3: ○ ●)
            Row {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                spacing: 8

                // Dot 0: Media Player
                Rectangle {
                    width: mediaCardRoot.activeTabIndex === 0 ? 18 : 6
                    height: 6
                    radius: 3
                    color: mediaCardRoot.activeTabIndex === 0 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.3)

                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaCardRoot.requestSwitchTab(0)
                    }
                }

                // Dot 1: Control Center
                Rectangle {
                    width: mediaCardRoot.activeTabIndex === 1 ? 18 : 6
                    height: 6
                    radius: 3
                    color: mediaCardRoot.activeTabIndex === 1 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.3)

                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaCardRoot.requestSwitchTab(1)
                    }
                }
            }
        }

        // RIGHT COLUMN: Synced Lyrics View (Gambar 2)
        Item {
            id: lyricsColumn
            visible: mediaCardRoot.showLyrics
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: Qt.rgba(0, 0, 0, 0.22)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)
                clip: true

                // Header in Lyrics column
                RowLayout {
                    id: lyricsHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: i18n("Lirik Sinkron")
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#d0d4dc"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "LRCLIB"
                        font.pixelSize: 10
                        font.family: "Inter, Roboto, sans-serif"
                        color: "#6e7580"
                    }
                }

                // Synced Lyrics List
                ListView {
                    id: lyricsListView
                    anchors.top: lyricsHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    clip: true
                    spacing: 8
                    model: mediaCardRoot.lyricsList

                    preferredHighlightBegin: height * 0.35
                    preferredHighlightEnd: height * 0.65
                    highlightRangeMode: ListView.ApplyRange
                    highlightMoveDuration: 250

                    currentIndex: mediaCardRoot.currentLyricIndex

                    delegate: Item {
                        id: lyricDelegate
                        required property int index
                        required property var modelData

                        readonly property bool isActive: index === mediaCardRoot.currentLyricIndex
                        width: lyricsListView.width
                        implicitHeight: Math.max(26, lyricLineText.implicitHeight + 8)

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
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
                            font.pixelSize: lyricDelegate.isActive ? 14 : 12
                            font.weight: lyricDelegate.isActive ? Font.Bold : Font.Normal
                            font.family: "Inter, Roboto, sans-serif"
                            color: lyricDelegate.isActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.45)
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignLeft

                            scale: lyricDelegate.isActive ? 1.03 : 1.0
                            transformOrigin: Item.Left

                            Behavior on color {
                                ColorAnimation { duration: 180 }
                            }
                            Behavior on scale {
                                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
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

                    // Fallback / Loading / Empty states
                    Item {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        height: 120
                        visible: lyricsListView.count === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: mediaCardRoot.lyricsLoading ? "⏳" : "🎵"
                                font.pixelSize: 22
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: {
                                    if (mediaCardRoot.lyricsLoading) return i18n("Mencari lirik...");
                                    if (!mediaCardRoot.lyricsFound) return i18n("Lirik tidak tersedia");
                                    return i18n("Tidak ada lirik sinkron");
                                }
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                font.family: "Inter, Roboto, sans-serif"
                                color: "#ffffff"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: mediaCardRoot.lyricsLoading ? i18n("Mengambil dari LRCLIB database...") : i18n("Coba cari lagu lain atau segarkan lirik")
                                font.pixelSize: 11
                                font.family: "Inter, Roboto, sans-serif"
                                color: "#8e95a0"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 100
                                Layout.preferredHeight: 28
                                radius: 14
                                color: Qt.rgba(1, 1, 1, 0.14)
                                visible: !mediaCardRoot.lyricsLoading

                                Text {
                                    anchors.centerIn: parent
                                    text: i18n("Coba Lagi")
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#ffffff"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mediaCardRoot.requestRetryLyrics()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
