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
    property int fontSize: 13
    property string clockFontFamily: ""
    property bool clockFontBold: true
    property bool showVisualizer: true

    implicitHeight: 34

    // Centered content row (Rapat, harmonis, tidak ada gap kosong, tanpa titik sensor)
    RowLayout {
        anchors.centerIn: parent
        spacing: 7

        // Music note icon (only when media is playing)
        Kirigami.Icon {
            source: "audio-x-generic"
            implicitWidth: 12
            implicitHeight: 12
            color: standbyRoot.accentColor
            visible: standbyRoot.isPlaying
            Layout.alignment: Qt.AlignVCenter
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
            barColor: standbyRoot.accentColor
            visible: standbyRoot.isPlaying && standbyRoot.showVisualizer
            barCount: 4
            barWidth: 2.5
            spacing: 2
            maxHeight: 11
        }
    }
}

