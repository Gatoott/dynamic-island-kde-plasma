pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: root

    property color accentColor: "#3daee9"
    property var notificationItems: []

    signal requestClearAll()
    signal requestRemoveItem(var notifId)

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 44
        anchors.rightMargin: 44
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 10

        // --- Header ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: Qt.rgba(1, 1, 1, 0.08)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "notifications"
                    color: root.accentColor
                }
            }

            Text {
                text: i18n("Notifications") + (root.notificationItems.length > 0 ? " (" + root.notificationItems.length + ")" : "")
                font.pixelSize: 15
                font.bold: true
                color: "#ffffff"
                font.family: "Inter, Roboto, sans-serif"
            }

            Item { Layout.fillWidth: true }

            // Clear All Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                visible: root.notificationItems.length > 0
                color: clearMa.containsMouse ? Qt.rgba(0.9, 0.2, 0.2, 0.3) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: "edit-clear-history"
                    color: clearMa.containsMouse ? "#ff6b6b" : "#ffffff"
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

        // --- Content List ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty State
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: root.notificationItems.length === 0

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    width: 36
                    height: 36
                    source: "notifications-disabled"
                    color: Qt.rgba(1, 1, 1, 0.3)
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("No notifications yet")
                    font.pixelSize: 13
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: "Inter, Roboto, sans-serif"
                }
            }

            // ListView of Notifications
            ListView {
                id: notifListView
                anchors.fill: parent
                clip: true
                spacing: 6
                model: root.notificationItems

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    id: notifScrollBar
                    active: true
                    policy: QQC2.ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    id: notifCard
                    required property int index
                    required property var modelData

                    width: notifListView.width - (notifScrollBar.visible ? 10 : 0)
                    height: Math.min(Math.max(48, itemCol.implicitHeight + 16), 84)
                    radius: 10
                    color: notifCardMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: notifCardMa.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.08)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        // App Icon
                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.1)

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                source: notifCard.modelData && notifCard.modelData.icon ? notifCard.modelData.icon : "preferences-desktop-notification"
                                fallback: "dialog-information"
                            }
                        }

                        // Texts
                        ColumnLayout {
                            id: itemCol
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: notifCard.modelData && notifCard.modelData.summary ? notifCard.modelData.summary : (notifCard.modelData ? notifCard.modelData.app : "")
                                    color: "#ffffff"
                                    font.pixelSize: 12
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
                                color: Qt.rgba(1, 1, 1, 0.7)
                                font.pixelSize: 11
                                font.family: "Inter, Roboto, sans-serif"
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: text.length > 0
                            }
                        }

                        // Quick Remove Button on Hover
                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 11
                            color: delMa.containsMouse ? Qt.rgba(0.9, 0.2, 0.2, 0.3) : Qt.rgba(1, 1, 1, 0.08)
                            visible: notifCardMa.containsMouse

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                source: "edit-delete"
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
        }
    }
}
