import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: visualizerRoot

    property bool isPlaying: false
    property color albumColor: "#3daee9"

    // Customization properties with configuration fallbacks
    property int alignment: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisAlignment !== undefined) return plasmoid.configuration.miniVisAlignment;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisAlignment !== undefined) return Plasmoid.configuration.miniVisAlignment;
        return 1; // 0 = Bottom-Aligned, 1 = Center-Aligned / Mirrored
    }

    property int colorMode: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisColorMode !== undefined) return plasmoid.configuration.miniVisColorMode;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisColorMode !== undefined) return Plasmoid.configuration.miniVisColorMode;
        return 0; // 0 = Dynamic Album Color, 1 = System Accent, 2 = Custom Color
    }

    property color customColor: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisCustomColor) return plasmoid.configuration.miniVisCustomColor;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisCustomColor) return Plasmoid.configuration.miniVisCustomColor;
        return Qt.color("#38bdf8");
    }

    property real barWidth: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisBarWidth !== undefined) return plasmoid.configuration.miniVisBarWidth;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisBarWidth !== undefined) return Plasmoid.configuration.miniVisBarWidth;
        return 2;
    }

    property real spacing: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisSpacing !== undefined) return plasmoid.configuration.miniVisSpacing;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisSpacing !== undefined) return Plasmoid.configuration.miniVisSpacing;
        return 2;
    }

    property real maxHeight: {
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

    property bool rounded: {
        if (typeof plasmoid !== "undefined" && plasmoid.configuration && plasmoid.configuration.miniVisRounded !== undefined) return plasmoid.configuration.miniVisRounded;
        if (typeof Plasmoid !== "undefined" && Plasmoid.configuration && Plasmoid.configuration.miniVisRounded !== undefined) return Plasmoid.configuration.miniVisRounded;
        return true;
    }

    property int barCount: 4
    property real minHeight: Math.max(2, Math.round(maxHeight * 0.2))

    property color barColor: {
        if (colorMode === 0 && albumColor && albumColor != "" && albumColor != "#000000") {
            return albumColor;
        } else if (colorMode === 1) {
            return Kirigami.Theme.highlightColor;
        } else if (colorMode === 2) {
            return customColor;
        }
        return albumColor || Kirigami.Theme.highlightColor;
    }

    implicitWidth: barCount * barWidth + (barCount - 1) * spacing
    implicitHeight: maxHeight

    Row {
        anchors.centerIn: parent
        height: visualizerRoot.maxHeight
        spacing: visualizerRoot.spacing

        Repeater {
            model: visualizerRoot.barCount

            Rectangle {
                id: bar
                width: visualizerRoot.barWidth
                radius: visualizerRoot.rounded ? (width / 2) : 0
                color: visualizerRoot.barColor

                // Perhitungan posisi Y: Center-Aligned (Mirrored) vs Bottom-Aligned
                y: visualizerRoot.alignment === 1
                    ? Math.round((parent.height - height) / 2)
                    : (parent.height - height)

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
                        to: visualizerRoot.minHeight + (bar.maxH - visualizerRoot.minHeight) * 0.25
                        duration: bar.animDuration * 0.85
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        to: bar.maxH * 0.8
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
