pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property bool isCharging: true
    property int batteryPercent: 100

    implicitHeight: 36

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 9

        // Icon Pill (Green lightning for charging, orange/amber battery for unplugged)
        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 11
            color: root.isCharging ? Qt.rgba(0.18, 0.8, 0.44, 0.22) : Qt.rgba(0.95, 0.6, 0.1, 0.22)
            border.width: 1
            border.color: root.isCharging ? "#2ecc71" : "#f39c12"

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 13
                height: 13
                source: root.isCharging ? "battery-charging" : "battery-080"
                color: root.isCharging ? "#2ecc71" : "#f39c12"
            }
        }

        // Status Text
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.isCharging ? i18n("Charger Connected") : i18n("Charger Disconnected")
                font.pixelSize: 11
                font.bold: true
                color: "#ffffff"
                font.family: "Inter, Roboto, sans-serif"
            }

            Text {
                text: root.batteryPercent + "% " + (root.isCharging ? i18n("Charging") : i18n("Discharging"))
                font.pixelSize: 10
                color: root.isCharging ? "#2ecc71" : Qt.rgba(1, 1, 1, 0.65)
                font.family: "Inter, Roboto, sans-serif"
            }
        }

        // Mini battery bar
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 12
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.25)

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1.5
                width: Math.max(2, (parent.width - 3) * (Math.min(100, Math.max(0, root.batteryPercent)) / 100))
                radius: 1.5
                color: root.isCharging ? "#2ecc71" : (root.batteryPercent <= 20 ? "#e74c3c" : "#3daee9")
            }
        }
    }
}
