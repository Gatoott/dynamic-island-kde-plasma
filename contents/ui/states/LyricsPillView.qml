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

    implicitHeight: 34

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 2
        spacing: 8

        // Music icon on the left (Gambar 1)
        Kirigami.Icon {
            id: noteIcon
            source: "audio-x-generic"
            implicitWidth: 14
            implicitHeight: 14
            color: lyricsPillRoot.accentColor
            Layout.alignment: Qt.AlignVCenter
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
        }
    }
}


