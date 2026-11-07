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
    readonly property var plasmoidConfig: (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration) 
        ? plasmoid.configuration 
        : ((typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration) ? Plasmoid.configuration : null)

    property int miniVisBarWidth: (plasmoidConfig && plasmoidConfig.miniVisBarWidth !== undefined) ? plasmoidConfig.miniVisBarWidth : 2
    property int miniVisHeight: (plasmoidConfig && (plasmoidConfig.miniVisHeight !== undefined || plasmoidConfig.miniVisMaxHeight !== undefined)) ? (plasmoidConfig.miniVisHeight !== undefined ? plasmoidConfig.miniVisHeight : plasmoidConfig.miniVisMaxHeight) : 14
    property int miniVisSpacing: (plasmoidConfig && plasmoidConfig.miniVisSpacing !== undefined) ? plasmoidConfig.miniVisSpacing : 2
    property int miniVisColorMode: (plasmoidConfig && plasmoidConfig.miniVisColorMode !== undefined) ? plasmoidConfig.miniVisColorMode : 0
    property color miniVisCustomColor: (plasmoidConfig && plasmoidConfig.miniVisCustomColor) ? Qt.color(plasmoidConfig.miniVisCustomColor) : Qt.color("#38bdf8")
    property int miniVisAlignment: (plasmoidConfig && plasmoidConfig.miniVisAlignment !== undefined) ? plasmoidConfig.miniVisAlignment : 1
    property bool miniVisRounded: (plasmoidConfig && plasmoidConfig.miniVisRounded !== undefined) ? plasmoidConfig.miniVisRounded : true
    property var visualizerLevels: []
    property bool visualizerServiceActive: false

    // Mini Music Icon (Left of Clock) Customization
    property bool miniMusicIconEnabled: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconEnabled !== undefined) return plasmoid.configuration.miniMusicIconEnabled;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconEnabled !== undefined) return Plasmoid.configuration.miniMusicIconEnabled;
        return true;
    }
    property int miniMusicIconSize: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconSize !== undefined) return plasmoid.configuration.miniMusicIconSize;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconSize !== undefined) return Plasmoid.configuration.miniMusicIconSize;
        return 13;
    }
    property int miniMusicIconWeight: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconWeight !== undefined) return plasmoid.configuration.miniMusicIconWeight;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconWeight !== undefined) return Plasmoid.configuration.miniMusicIconWeight;
        return 600;
    }
    property int miniMusicIconColorMode: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconColorMode !== undefined) return plasmoid.configuration.miniMusicIconColorMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconColorMode !== undefined) return Plasmoid.configuration.miniMusicIconColorMode;
        return 0;
    }
    property color miniMusicIconCustomColor: {
        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconCustomColor) return Qt.color(plasmoid.configuration.miniMusicIconCustomColor);
        if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconCustomColor) return Qt.color(Plasmoid.configuration.miniMusicIconCustomColor);
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
            visible: {
                var en = true;
                if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconEnabled !== undefined) {
                    en = plasmoid.configuration.miniMusicIconEnabled;
                } else if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconEnabled !== undefined) {
                    en = Plasmoid.configuration.miniMusicIconEnabled;
                } else {
                    en = standbyRoot.miniMusicIconEnabled;
                }
                return en && standbyRoot.isPlaying;
            }
            font.pixelSize: {
                if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconSize !== undefined) {
                    return plasmoid.configuration.miniMusicIconSize;
                }
                if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconSize !== undefined) {
                    return Plasmoid.configuration.miniMusicIconSize;
                }
                return (standbyRoot.miniMusicIconSize !== undefined) ? standbyRoot.miniMusicIconSize : 13;
            }
            font.weight: {
                if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconWeight !== undefined) {
                    return plasmoid.configuration.miniMusicIconWeight;
                }
                if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconWeight !== undefined) {
                    return Plasmoid.configuration.miniMusicIconWeight;
                }
                return (standbyRoot.miniMusicIconWeight !== undefined) ? standbyRoot.miniMusicIconWeight : 600;
            }
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter

            // Logika Warna Dinamis:
            color: {
                var cMode = 0;
                if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconColorMode !== undefined) {
                    cMode = plasmoid.configuration.miniMusicIconColorMode;
                } else if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconColorMode !== undefined) {
                    cMode = Plasmoid.configuration.miniMusicIconColorMode;
                } else {
                    cMode = standbyRoot.miniMusicIconColorMode;
                }

                switch (cMode) {
                    case 0: // Warna cover album dinamis
                        if (standbyRoot.albumColor && standbyRoot.albumColor != "" && standbyRoot.albumColor != "#000000" && standbyRoot.albumColor != "transparent") {
                            return standbyRoot.albumColor;
                        }
                        return standbyRoot.accentColor || "#ffffff";
                    case 1: // Aksen sistem KDE
                        return Kirigami.Theme.highlightColor;
                    case 2: // Putih / Abu redup
                        return Qt.rgba(1, 1, 1, 0.75);
                    case 3: // Warna kustom dari color picker
                        var cust = null;
                        if (typeof plasmoid !== "undefined" && plasmoid && plasmoid.configuration && plasmoid.configuration.miniMusicIconCustomColor) {
                            cust = plasmoid.configuration.miniMusicIconCustomColor;
                        } else if (typeof Plasmoid !== "undefined" && Plasmoid && Plasmoid.configuration && Plasmoid.configuration.miniMusicIconCustomColor) {
                            cust = Plasmoid.configuration.miniMusicIconCustomColor;
                        } else {
                            cust = standbyRoot.miniMusicIconCustomColor;
                        }
                        return cust ? Qt.color(cust) : "#ffffff";
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
            visible: standbyRoot.showVisualizer && (standbyRoot.isPlaying || (standbyRoot.visualizerServiceActive && standbyRoot.visualizerLevels && (standbyRoot.visualizerLevels[0] > 0.02 || standbyRoot.visualizerLevels[1] > 0.02 || standbyRoot.visualizerLevels[2] > 0.02 || standbyRoot.visualizerLevels[3] > 0.02)))
            barWidth: standbyRoot.miniVisBarWidth
            maxHeight: standbyRoot.miniVisHeight
            spacing: standbyRoot.miniVisSpacing
            colorMode: standbyRoot.miniVisColorMode
            customColor: standbyRoot.miniVisCustomColor
            alignment: standbyRoot.miniVisAlignment
            rounded: standbyRoot.miniVisRounded
            levels: standbyRoot.visualizerLevels
            realAudioActive: standbyRoot.visualizerServiceActive
        }
    }
}

