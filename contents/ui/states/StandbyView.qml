import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../components"

Item {
    id: standbyRoot

    property bool isPlaying: false
    property string currentTimeString: ""
    property string trackTitle: ""
    property string trackArtist: ""
    property color accentColor: "#3daee9"
    property color albumColor: accentColor
    property int fontSize: 13
    property string clockFontFamily: ""
    property bool clockFontBold: true
    property bool showVisualizer: true
    property int miniVisBarWidth: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisBarWidth !== undefined) return plasmoid.configuration.miniVisBarWidth;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisBarWidth !== undefined) return Plasmoid.configuration.miniVisBarWidth;
        return 2;
    }
    property int miniVisHeight: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
            if (plasmoid.configuration.miniVisHeight !== undefined) return plasmoid.configuration.miniVisHeight;
            if (plasmoid.configuration.miniVisMaxHeight !== undefined) return plasmoid.configuration.miniVisMaxHeight;
        }
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration) {
            if (Plasmoid.configuration.miniVisHeight !== undefined) return Plasmoid.configuration.miniVisHeight;
            if (Plasmoid.configuration.miniVisMaxHeight !== undefined) return Plasmoid.configuration.miniVisMaxHeight;
        }
        return 14;
    }
    property int miniVisSpacing: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisSpacing !== undefined) return plasmoid.configuration.miniVisSpacing;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisSpacing !== undefined) return Plasmoid.configuration.miniVisSpacing;
        return 2;
    }
    property int miniVisColorMode: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisColorMode !== undefined) return plasmoid.configuration.miniVisColorMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisColorMode !== undefined) return Plasmoid.configuration.miniVisColorMode;
        return 0;
    }
    property color miniVisCustomColor: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisCustomColor) return plasmoid.configuration.miniVisCustomColor;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisCustomColor) return Plasmoid.configuration.miniVisCustomColor;
        return Qt.color("#38bdf8");
    }
    property int miniVisAlignment: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisAlignment !== undefined) return plasmoid.configuration.miniVisAlignment;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisAlignment !== undefined) return Plasmoid.configuration.miniVisAlignment;
        return 1;
    }
    property bool miniVisRounded: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisRounded !== undefined) return plasmoid.configuration.miniVisRounded;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisRounded !== undefined) return Plasmoid.configuration.miniVisRounded;
        return true;
    }

    // Mini Music Icon (Left of Clock) Customization
    property bool miniMusicIconEnabled: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniMusicIconEnabled !== undefined) return plasmoid.configuration.miniMusicIconEnabled;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconEnabled !== undefined) return Plasmoid.configuration.miniMusicIconEnabled;
        return true;
    }
    property int miniMusicIconSize: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniMusicIconSize !== undefined) return plasmoid.configuration.miniMusicIconSize;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconSize !== undefined) return Plasmoid.configuration.miniMusicIconSize;
        return 13;
    }
    property int miniMusicIconWeight: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniMusicIconWeight !== undefined) return plasmoid.configuration.miniMusicIconWeight;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconWeight !== undefined) return Plasmoid.configuration.miniMusicIconWeight;
        return 600;
    }
    property int miniMusicIconColorMode: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniMusicIconColorMode !== undefined) return plasmoid.configuration.miniMusicIconColorMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconColorMode !== undefined) return Plasmoid.configuration.miniMusicIconColorMode;
        return 0;
    }
    property color miniMusicIconCustomColor: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniMusicIconCustomColor) return plasmoid.configuration.miniMusicIconCustomColor;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconCustomColor) return Plasmoid.configuration.miniMusicIconCustomColor;
        return Qt.color("#ffffff");
    }

    implicitHeight: 34

    // Centered content row (Rapat, harmonis, tidak ada gap kosong, tanpa titik sensor)
    RowLayout {
        anchors.centerIn: parent
        spacing: 7

        // Music note icon (♫) on the left of clock
        Text {
            id: musicNoteIcon
            text: "♫"
            visible: standbyRoot.miniMusicIconEnabled && standbyRoot.isPlaying
            font.pixelSize: standbyRoot.miniMusicIconSize
            font.weight: standbyRoot.miniMusicIconWeight
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter

            // Logika Warna Dinamis:
            color: {
                switch (standbyRoot.miniMusicIconColorMode) {
                    case 0:
                        if (standbyRoot.albumColor && standbyRoot.albumColor != "" && standbyRoot.albumColor != "#000000" && standbyRoot.albumColor != "transparent") {
                            return standbyRoot.albumColor;
                        }
                        return standbyRoot.accentColor || "#ffffff";
                    case 1:
                        return Kirigami.Theme.highlightColor;
                    case 2:
                        return Qt.rgba(1, 1, 1, 0.75);
                    case 3:
                        return standbyRoot.miniMusicIconCustomColor;
                    default:
                        return "#ffffff";
                }
            }

            Behavior on color {
                ColorAnimation { duration: 250 }
            }
        }

        // Digital Clock
        Text {
            id: clockText
            text: standbyRoot.currentTimeString
            font.pixelSize: standbyRoot.fontSize
            font.bold: standbyRoot.clockFontBold
            font.family: standbyRoot.clockFontFamily ? standbyRoot.clockFontFamily : "Inter, Roboto, sans-serif"
            color: "#ffffff"
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter
        }

        // Mini Audio Visualizer (only when media is playing)
        AudioVisualizer {
            Layout.alignment: Qt.AlignVCenter
            isPlaying: standbyRoot.isPlaying
            albumColor: standbyRoot.albumColor || standbyRoot.accentColor
            visible: standbyRoot.isPlaying && standbyRoot.showVisualizer
            barWidth: standbyRoot.miniVisBarWidth
            maxHeight: standbyRoot.miniVisHeight
            spacing: standbyRoot.miniVisSpacing
            colorMode: standbyRoot.miniVisColorMode
            customColor: standbyRoot.miniVisCustomColor
            alignment: standbyRoot.miniVisAlignment
            rounded: standbyRoot.miniVisRounded
        }
    }
}

