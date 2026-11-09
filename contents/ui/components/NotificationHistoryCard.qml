pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "."

Item {
    id: root

    property color accentColor: "#3daee9"
    property var notificationItems: []

    signal requestClearAll()
    signal requestRemoveItem(var notifId)

    // --- Header ---
    Item {
        id: headerNotificationArea
        anchors.top: parent.top
        anchors.topMargin: 18
        anchors.left: parent.left
        anchors.leftMargin: 46
        anchors.right: parent.right
        anchors.rightMargin: 46
        height: 26

        RowLayout {
            anchors.fill: parent
            spacing: 8

            // Bell Icon
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.08)

                SFSymbolIcon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    name: "bell.fill"
                    color: root.accentColor
                }
            }

            // Title
            Text {
                text: i18n("Notifications")
                font.pixelSize: 14
                font.bold: true
                color: "#ffffff"
                font.family: "Inter, Roboto, sans-serif"
            }

            // Circular Count Badge
            Rectangle {
                visible: root.notificationItems && root.notificationItems.length > 0
                width: Math.max(18, countText.implicitWidth + 8)
                height: 18
                radius: 9
                color: root.accentColor

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.notificationItems ? root.notificationItems.length : 0
                    font.pixelSize: 10
                    font.bold: true
                    color: "#ffffff"
                    font.family: "Inter, Roboto, sans-serif"
                }
            }

            Item { Layout.fillWidth: true }

            // Clear All Button (xmark.circle.fill)
            Rectangle {
                width: 24
                height: 24
                radius: 12
                visible: root.notificationItems && root.notificationItems.length > 0
                color: clearMa.containsMouse ? Qt.rgba(0.9, 0.2, 0.2, 0.25) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)

                SFSymbolIcon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    name: "xmark.circle.fill"
                    color: clearMa.containsMouse ? "#ff6b6b" : "#ffffff"
                    circleColor: clearMa.containsMouse ? Qt.rgba(0.9, 0.2, 0.2, 0.4) : Qt.rgba(1, 1, 1, 0.16)
                }

                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestClearAll()
                }
            }
        }
    }

    // --- Scrollable Notification ListView (Uniform Height) ---
    ListView {
        id: notificationListView
        anchors.top: headerNotificationArea.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.leftMargin: 46
        anchors.right: parent.right
        anchors.rightMargin: 46
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 38
        clip: true
        spacing: 6
        model: root.notificationItems

        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            id: notifScrollBar
            policy: notificationListView.contentHeight > notificationListView.height 
                ? QQC2.ScrollBar.AsNeeded 
                : QQC2.ScrollBar.AlwaysOff
            width: 4
        }

        delegate: Rectangle {
            id: notifCard
            required property int index
            required property var modelData

            width: notificationListView.width - (notifScrollBar.visible ? 8 : 0)
            height: 48
            radius: 10
            color: notifCardMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: notifCardMa.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 6
                anchors.bottomMargin: 6
                spacing: 10

                // App Icon (Apple Squircle Masking: radius = width * 0.22)
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: width * 0.22
                    color: Qt.rgba(1, 1, 1, 0.10)
                    clip: true

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: notifCard.modelData && notifCard.modelData.icon ? notifCard.modelData.icon : "preferences-desktop-notification"
                        fallback: "dialog-information"
                    }
                }

                // Two-line layout: Sender/Summary on top, Body text below
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: notifCard.modelData && notifCard.modelData.summary ? notifCard.modelData.summary : (notifCard.modelData ? notifCard.modelData.app : "")
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.family: "Inter, Roboto, sans-serif"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: notifCard.modelData && notifCard.modelData.time ? notifCard.modelData.time : ""
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.pixelSize: 10
                            font.family: "Inter, Roboto, sans-serif"
                        }
                    }

                    Text {
                        text: notifCard.modelData && notifCard.modelData.body ? notifCard.modelData.body : (notifCard.modelData ? notifCard.modelData.app : "")
                        color: Qt.rgba(1, 1, 1, 0.68)
                        font.pixelSize: 10
                        font.family: "Inter, Roboto, sans-serif"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Quick Remove Button on Hover
                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 10
                    color: delMa.containsMouse ? Qt.rgba(0.9, 0.2, 0.2, 0.3) : Qt.rgba(1, 1, 1, 0.08)
                    visible: notifCardMa.containsMouse

                    SFSymbolIcon {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        name: "xmark"
                        color: delMa.containsMouse ? "#ff6b6b" : "#ffffff"
                    }

                    MouseArea {
                        id: delMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (notifCard.modelData && notifCard.modelData.id) {
                                root.requestRemoveItem(notifCard.modelData.id);
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: notifCardMa
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }

    // Empty State Overlay
    ColumnLayout {
        anchors.centerIn: notificationListView
        spacing: 6
        visible: !root.notificationItems || root.notificationItems.length === 0

        SFSymbolIcon {
            Layout.alignment: Qt.AlignHCenter
            width: 28
            height: 28
            name: "bell.fill"
            color: Qt.rgba(1, 1, 1, 0.25)
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("No notifications yet")
            font.pixelSize: 12
            color: Qt.rgba(1, 1, 1, 0.45)
            font.family: "Inter, Roboto, sans-serif"
        }
    }
}
