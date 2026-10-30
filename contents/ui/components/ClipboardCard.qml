pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.dbus as DBus

Item {
    id: root

    property color accentColor: "#3daee9"
    property var clipboardItems: []
    property bool loading: false
    property string feedbackMessage: ""

    signal requestCopy(string text)
    signal requestClearAll()

    // --- DBus Caller to Klipper ---
    DBusCall {
        id: klipperCall
        service: "org.kde.klipper"
        path: "/klipper"
        iface: "org.kde.klipper.klipper"
    }

    Timer {
        id: autoRefreshTimer
        interval: 1500
        running: root.visible
        repeat: true
        onTriggered: root.refreshHistory()
    }

    onVisibleChanged: {
        if (root.visible) {
            root.refreshHistory();
        }
    }

    Timer {
        id: feedbackTimer
        interval: 1800
        repeat: false
        onTriggered: root.feedbackMessage = ""
    }

    function refreshHistory() {
        root.loading = true;
        klipperCall.call("getClipboardHistoryMenu", [], (reply) => {
            root.loading = false;
            if (reply && !reply.isError) {
                var list = null;
                if (reply.value !== undefined && Array.isArray(reply.value)) {
                    list = reply.value;
                } else if (reply.values && reply.values.length > 0 && Array.isArray(reply.values[0])) {
                    list = reply.values[0];
                } else if (reply.arguments && reply.arguments.length > 0 && Array.isArray(reply.arguments[0])) {
                    list = reply.arguments[0];
                }

                if (Array.isArray(list)) {
                    // Ambil maksimal 15 item riwayat teks terakhir
                    root.clipboardItems = list.slice(0, 15);
                } else {
                    root.clipboardItems = [];
                }
            }
        });
    }

    function copyItem(text) {
        if (!text) return;
        klipperCall.call("setClipboardContents", [text], (reply) => {
            root.feedbackMessage = i18n("Copied to clipboard!");
            feedbackTimer.restart();
            root.requestCopy(text);
        });
    }

    function clearAllHistory() {
        klipperCall.call("clearClipboardHistory", [], (reply) => {
            root.clipboardItems = [];
            root.feedbackMessage = i18n("History cleared!");
            feedbackTimer.restart();
            root.requestClearAll();
        });
    }

    Component.onCompleted: {
        refreshHistory();
    }

    ColumnLayout {
        anchors.fill: parent
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
                    source: "edit-paste"
                    color: root.accentColor
                }
            }

            Text {
                text: i18n("Clipboard History")
                font.pixelSize: 15
                font.bold: true
                color: "#ffffff"
                font.family: "Inter, Roboto, sans-serif"
            }

            Item { Layout.fillWidth: true }

            // Feedback Message
            Text {
                text: root.feedbackMessage
                font.pixelSize: 11
                color: "#2ecc71"
                font.bold: true
                visible: root.feedbackMessage.length > 0
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Refresh Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: refreshMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.1)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: "view-refresh"
                    color: "#ffffff"
                }

                MouseArea {
                    id: refreshMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.refreshHistory()
                }
            }

            // Clear All Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
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
                    onClicked: root.clearAllHistory()
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
                visible: !root.loading && root.clipboardItems.length === 0

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    width: 36
                    height: 36
                    source: "edit-paste"
                    color: Qt.rgba(1, 1, 1, 0.3)
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("No clipboard items yet")
                    font.pixelSize: 13
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: "Inter, Roboto, sans-serif"
                }
            }

            // Loading Indicator
            QQC2.BusyIndicator {
                anchors.centerIn: parent
                running: root.loading && root.clipboardItems.length === 0
                visible: running
            }

            // Clipboard History ListView
            ListView {
                id: clipListView
                anchors.fill: parent
                clip: true
                spacing: 6
                model: root.clipboardItems

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    id: clipScrollBar
                    active: true
                    policy: QQC2.ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    id: clipCard
                    required property int index
                    required property var modelData

                    width: clipListView.width - (clipScrollBar.visible ? 10 : 0)
                    height: Math.min(Math.max(40, clipText.implicitHeight + 16), 72)
                    radius: 10
                    color: cardMa.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: cardMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Kirigami.Icon {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            source: "edit-copy"
                            color: cardMa.containsMouse ? root.accentColor : Qt.rgba(1, 1, 1, 0.4)
                        }

                        Text {
                            id: clipText
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: Text.AlignVCenter
                            text: (typeof clipCard.modelData === "string") ? clipCard.modelData : ""
                            color: cardMa.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.85)
                            font.pixelSize: 12
                            font.family: "Inter, Roboto, sans-serif"
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: 10
                            color: Qt.rgba(1, 1, 1, 0.1)
                            visible: cardMa.containsMouse

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                source: "dialog-ok"
                                color: "#2ecc71"
                            }
                        }
                    }

                    MouseArea {
                        id: cardMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.copyItem(clipCard.modelData);
                        }
                    }
                }
            }
        }
    }
}
