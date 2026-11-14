import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../components"

Item {
    id: lyricsPillRoot

    property string currentLyricLine: ""
    property string trackTitle: ""
    property string trackArtist: ""
    property color accentColor: "#3daee9"
    property color albumColor: accentColor
    property int fontSize: 13
    property string lyricsFontFamily: ""
    property bool lyricsFontBold: true
    property bool showCompactVisualizer: false
    property bool isPlaying: true

    // Mini Music Icon Customization
    property bool miniMusicIconEnabled: true
    property int miniMusicIconSize: 13
    property int miniMusicIconWeight: 600
    property int miniMusicIconColorMode: 0
    property color miniMusicIconCustomColor: "#ffffff"

    // Mini Visualizer properties
    property int miniVisBarWidth: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniVisBarWidth !== undefined) return plasmoid.configuration.miniVisBarWidth;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniVisBarWidth !== undefined) return Plasmoid.configuration.miniVisBarWidth;
        return 2;
    }
    property int miniVisHeight: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration) {
            if (plasmoid.configuration.miniVisHeight !== undefined) return plasmoid.configuration.miniVisHeight;
            if (plasmoid.configuration.miniVisMaxHeight !== undefined) return plasmoid.configuration.miniVisMaxHeight;
        }
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration) {
            if (Plasmoid.configuration.miniVisHeight !== undefined) return Plasmoid.configuration.miniVisHeight;
            if (Plasmoid.configuration.miniVisMaxHeight !== undefined) return Plasmoid.configuration.miniVisMaxHeight;
        }
        return 14;
    }
    property int miniVisSpacing: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniVisSpacing !== undefined) return plasmoid.configuration.miniVisSpacing;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniVisSpacing !== undefined) return Plasmoid.configuration.miniVisSpacing;
        return 2;
    }
    property int miniVisColorMode: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniVisColorMode !== undefined) return plasmoid.configuration.miniVisColorMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniVisColorMode !== undefined) return Plasmoid.configuration.miniVisColorMode;
        return 0;
    }
    property color miniVisCustomColor: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniVisCustomColor) return Qt.color(plasmoid.configuration.miniVisCustomColor);
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniVisCustomColor) return Qt.color(Plasmoid.configuration.miniVisCustomColor);
        return Qt.color("#38bdf8");
    }
    property int miniVisAlignment: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniVisAlignment !== undefined) return plasmoid.configuration.miniVisAlignment;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniVisAlignment !== undefined) return Plasmoid.configuration.miniVisAlignment;
        return 1;
    }
    property bool miniVisRounded: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniVisRounded !== undefined) return plasmoid.configuration.miniVisRounded;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniVisRounded !== undefined) return Plasmoid.configuration.miniVisRounded;
        return true;
    }
    property var visualizerLevels: []
    property bool visualizerServiceActive: false

    implicitHeight: 34

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 2
        spacing: 8

        // Music note icon (♫) on the left of lyrics (Synchronized with StandbyView)
        Text {
            id: standbyLyricsMusicIcon
            text: "♫"
            visible: lyricsPillRoot.miniMusicIconEnabled && lyricsPillRoot.isPlaying
            font.pixelSize: lyricsPillRoot.miniMusicIconSize
            font.weight: lyricsPillRoot.miniMusicIconWeight
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter

            // Dynamic color logic:
            color: {
                switch (lyricsPillRoot.miniMusicIconColorMode) {
                    case 0: // Dynamic album cover color
                        if (lyricsPillRoot.albumColor && lyricsPillRoot.albumColor != "" && lyricsPillRoot.albumColor != "#000000" && lyricsPillRoot.albumColor != "transparent") {
                            return lyricsPillRoot.albumColor;
                        }
                        return lyricsPillRoot.accentColor || "#ffffff";
                    case 1: // KDE system accent
                        return Kirigami.Theme.highlightColor;
                    case 2: // Dim white / grey
                        return Qt.rgba(1, 1, 1, 0.75);
                    case 3: // Custom color picker
                        return lyricsPillRoot.miniMusicIconCustomColor;
                    default:
                        return "#ffffff";
                }
            }

            Behavior on color {
                ColorAnimation { duration: 250 }
            }
        }

        // Active lyric line in the middle
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Text {
                id: lyricLabel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: lyricsPillRoot.currentLyricLine !== "" 
                      ? lyricsPillRoot.currentLyricLine 
                      : (lyricsPillRoot.trackTitle ? (lyricsPillRoot.trackTitle + (lyricsPillRoot.trackArtist ? " • " + lyricsPillRoot.trackArtist : "")) : "Tidak ada media")
                font.pixelSize: lyricsPillRoot.fontSize
                font.bold: lyricsPillRoot.lyricsFontBold
                font.family: lyricsPillRoot.lyricsFontFamily ? lyricsPillRoot.lyricsFontFamily : "Inter, Roboto, sans-serif"
                color: "#ffffff"
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter

                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: lyricLabel; property: "opacity"; to: 0.2; duration: 100 }
                        PropertyAction { target: lyricLabel; property: "text" }
                        NumberAnimation { target: lyricLabel; property: "opacity"; to: 1.0; duration: 160 }
                    }
                }
            }
        }

        // Optional Mini Audio Visualizer on the right (Toggled via settings)
        AudioVisualizer {
            id: miniVisualizer
            Layout.alignment: Qt.AlignVCenter
            isPlaying: lyricsPillRoot.isPlaying
            albumColor: lyricsPillRoot.albumColor || lyricsPillRoot.accentColor
            visible: lyricsPillRoot.showCompactVisualizer
            barWidth: lyricsPillRoot.miniVisBarWidth
            maxHeight: lyricsPillRoot.miniVisHeight
            spacing: lyricsPillRoot.miniVisSpacing
            colorMode: lyricsPillRoot.miniVisColorMode
            customColor: lyricsPillRoot.miniVisCustomColor
            alignment: lyricsPillRoot.miniVisAlignment
            rounded: lyricsPillRoot.miniVisRounded
            levels: lyricsPillRoot.visualizerLevels
            realAudioActive: lyricsPillRoot.visualizerServiceActive
        }
    }
}
