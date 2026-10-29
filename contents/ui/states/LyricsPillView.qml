import QtQuick
import QtQuick.Layouts

Item {
    id: lyricsPillRoot

    property string currentLyricLine: ""
    property color accentColor: "#3daee9"
    property int fontSize: 13

    implicitHeight: 34

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 2
        spacing: 9

        // Music icon on the left (Gambar 1)
        Text {
            id: noteIcon
            text: "♫"
            font.pixelSize: 13
            font.bold: true
            color: lyricsPillRoot.accentColor
            Layout.alignment: Qt.AlignVCenter
        }

        // Active lyric line on the right (Gambar 1)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Text {
                id: lyricLabel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: lyricsPillRoot.currentLyricLine !== "" ? lyricsPillRoot.currentLyricLine : "..."
                font.pixelSize: lyricsPillRoot.fontSize
                font.weight: Font.DemiBold
                font.family: "Inter, Roboto, sans-serif"
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
    }
}
