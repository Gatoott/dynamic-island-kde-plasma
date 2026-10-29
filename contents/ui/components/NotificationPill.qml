pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property string appName: ""
    property string appIcon: "preferences-desktop-notification"
    property string summary: ""
    property string body: ""

    implicitHeight: 36

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 9

        // App Icon
        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 6
            color: Qt.rgba(1, 1, 1, 0.12)

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: root.appIcon.length > 0 ? root.appIcon : "preferences-desktop-notification"
                fallback: "dialog-information"
            }
        }

        // Title / Sender + Message Preview
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.summary.length > 0 ? root.summary : (root.appName.length > 0 ? root.appName : i18n("Notification"))
                    font.pixelSize: 11
                    font.bold: true
                    color: "#ffffff"
                    font.family: "Inter, Roboto, sans-serif"
                    elide: Text.ElideRight
                    Layout.maximumWidth: 160
                }

                Text {
                    text: "•"
                    font.pixelSize: 10
                    color: Qt.rgba(1, 1, 1, 0.4)
                    visible: root.body.length > 0
                }

                Text {
                    Layout.fillWidth: true
                    text: root.body
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.75)
                    font.family: "Inter, Roboto, sans-serif"
                    elide: Text.ElideRight
                    visible: root.body.length > 0
                }
            }
        }

        // Notification pulse indicator
        Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: 6
            radius: 3
            color: "#3daee9"
        }
    }
}
