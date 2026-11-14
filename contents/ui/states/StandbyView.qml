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
    property bool miniMusicIconEnabled: true
    property int miniMusicIconSize: 13
    property int miniMusicIconWeight: 600
    property int miniMusicIconColorMode: 0
    property color miniMusicIconCustomColor: "#ffffff"

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

