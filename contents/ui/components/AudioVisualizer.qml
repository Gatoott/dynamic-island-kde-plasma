import QtQuick

Item {
    id: visualizerRoot

    property bool isPlaying: false
    property color barColor: "#3daee9"
    property int barCount: 4
    property real barWidth: 2.5
    property real spacing: 2
    property real maxHeight: 11
    property real minHeight: 3

    implicitWidth: barCount * barWidth + (barCount - 1) * spacing
    implicitHeight: maxHeight

    Row {
        anchors.centerIn: parent
        spacing: visualizerRoot.spacing

        Repeater {
            model: visualizerRoot.barCount

            Rectangle {
                id: bar
                width: visualizerRoot.barWidth
                radius: width / 2
                color: visualizerRoot.barColor
                anchors.bottom: parent.bottom

                readonly property real maxH: visualizerRoot.maxHeight * (0.65 + 0.35 * Math.sin(index * 1.3))
                readonly property int animDuration: 260 + (index * 80) % 240

                height: visualizerRoot.isPlaying ? visualizerRoot.minHeight : visualizerRoot.minHeight

                SequentialAnimation on height {
                    running: visualizerRoot.isPlaying && visualizerRoot.visible && visualizerRoot.opacity > 0
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: bar.maxH
                        duration: bar.animDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        to: visualizerRoot.minHeight + 1.5
                        duration: bar.animDuration * 0.85
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        to: bar.maxH * 0.75
                        duration: bar.animDuration * 0.95
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        to: visualizerRoot.minHeight
                        duration: bar.animDuration * 0.75
                        easing.type: Easing.InOutQuad
                    }
                }

                Behavior on height {
                    enabled: !visualizerRoot.isPlaying
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: 250 }
                }
            }
        }
    }
}
