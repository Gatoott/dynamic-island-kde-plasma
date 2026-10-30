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
    property color accentColor: "#3daee9"

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

        // Notification Title / Summary (Ringkas - Title Only)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.summary.length > 0 ? root.summary : (root.appName.length > 0 ? root.appName : i18n("Notification"))
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "Inter, Roboto, sans-serif"
                color: "#ffffff"
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Notification pulse indicator
        Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: 6
            radius: 3
            color: root.accentColor
        }
    }
}
