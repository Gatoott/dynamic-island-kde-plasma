import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: volControlRoot

    property real currentVolumePercent: 0
    property bool isMuted: false

    property real collapsedWidth: 32
    property real expandedWidth: 104
    property real controlHeight: 32
    property real iconSize: 14

    signal requestSetVolume(real percent)
    signal requestToggleMute()
    signal requestAdjustVolume(var wheel)

    implicitWidth: isExpanded ? expandedWidth : collapsedWidth
    implicitHeight: controlHeight

    readonly property bool isExpanded: volHoverMa.containsMouse || volSliderMa.pressed || speakerIconMa.containsMouse

    Behavior on implicitWidth {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.controlHeight / 2
        color: volControlRoot.isExpanded ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.10)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 7
            anchors.rightMargin: 7
            spacing: 6

            Item {
                id: volSliderRow
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: volControlRoot.implicitWidth > (volControlRoot.collapsedWidth + 18)

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 3
                    radius: 1.5
                    color: Qt.rgba(1, 1, 1, 0.25)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(3, parent.width * (volControlRoot.currentVolumePercent / 100))
                        radius: 1.5
                        color: volControlRoot.isMuted ? Qt.rgba(1, 1, 1, 0.45) : "#ffffff"
                    }
                }

                MouseArea {
                    id: volSliderMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    function updateMiniVol(mouse) {
                        const pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)));
                        volControlRoot.requestSetVolume(pct);
                    }

                    onPressed: (mouse) => updateMiniVol(mouse)
                    onPositionChanged: (mouse) => {
                        if (pressed) updateMiniVol(mouse);
                    }
                    onWheel: (wheel) => volControlRoot.requestAdjustVolume(wheel)
                }
            }

            Item {
                Layout.preferredWidth: volControlRoot.iconSize + 2
                Layout.preferredHeight: volControlRoot.iconSize + 2
                Layout.alignment: Qt.AlignVCenter

                SFSymbolIcon {
                    anchors.centerIn: parent
                    width: volControlRoot.iconSize
                    height: volControlRoot.iconSize
                    name: (volControlRoot.isMuted || volControlRoot.currentVolumePercent === 0)
                        ? "speaker.slash.fill"
                        : (volControlRoot.currentVolumePercent < 50 ? "speaker.wave.1.fill" : "speaker.wave.2.fill")
                    color: volControlRoot.isMuted ? Qt.rgba(1, 1, 1, 0.5) : "#ffffff"
                }

                MouseArea {
                    id: speakerIconMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: volControlRoot.requestToggleMute()
                    onWheel: (wheel) => volControlRoot.requestAdjustVolume(wheel)
                }
            }
        }
    }

    MouseArea {
        id: volHoverMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => volControlRoot.requestAdjustVolume(wheel)
    }
}

