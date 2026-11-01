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

    readonly property bool isWhatsApp: {
        var a = (root.appName || "").toLowerCase();
        var s = (root.summary || "").toLowerCase();
        return a.indexOf("whatsapp") !== -1 || s.indexOf("whatsapp") !== -1;
    }

    readonly property string senderName: {
        var rawSummary = (root.summary || "").trim();
        var rawBody = (root.body || "").trim();

        if (root.isWhatsApp) {
            // Jika summary hanya bertuliskan "WhatsApp" atau kosong, periksa apakah body berformat "Pengirim: Pesan"
            if (rawSummary.toLowerCase() === "whatsapp" || rawSummary === "") {
                var colonIdx = rawBody.indexOf(":");
                if (colonIdx > 0 && colonIdx < 35) {
                    return rawBody.substring(0, colonIdx).trim();
                }
                return i18n("Pesan Baru");
            }
            return rawSummary;
        }

        if (rawSummary.length > 0) return rawSummary;
        if (root.appName.length > 0) return root.appName;
        return i18n("Notification");
    }

    readonly property string notificationMessageBody: {
        var rawSummary = (root.summary || "").trim();
        var rawBody = (root.body || "").trim();

        if (root.isWhatsApp && (rawSummary.toLowerCase() === "whatsapp" || rawSummary === "")) {
            var colonIdx = rawBody.indexOf(":");
            if (colonIdx > 0 && colonIdx < 35) {
                return rawBody.substring(colonIdx + 1).trim();
            }
        }
        return rawBody;
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 9

        // 1. Icon Aplikasi (WhatsApp / App Icon)
        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 7
            color: root.isWhatsApp ? Qt.rgba(0.15, 0.78, 0.35, 0.22) : Qt.rgba(1, 1, 1, 0.12)
            Layout.alignment: Qt.AlignVCenter

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 15
                height: 15
                source: {
                    if (root.isWhatsApp && (!root.appIcon || root.appIcon === "" || root.appIcon === "preferences-desktop-notification")) {
                        return "whatsapp";
                    }
                    return (root.appIcon && root.appIcon.length > 0) ? root.appIcon : "preferences-desktop-notification";
                }
                fallback: root.isWhatsApp ? "dialog-messages" : "dialog-information"
            }
        }

        // 2. Konten Teks Notifikasi: 2 Baris Vertikal
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            // Baris Atas: Nama Pengirim / Title (Bold, putih)
            Text {
                text: root.senderName
                font.bold: true
                font.pixelSize: 11
                font.family: "Inter, Roboto, sans-serif"
                color: "#ffffff"
                elide: Text.ElideRight
                Layout.fillWidth: true
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                verticalAlignment: Text.AlignVCenter
            }

            // Baris Bawah: Isi Pesan Notifikasi (Abu-abu terang)
            Text {
                text: root.notificationMessageBody.length > 0 ? root.notificationMessageBody : (root.isWhatsApp ? i18n("Pesan Baru") : i18n("Notifikasi"))
                font.pixelSize: 10
                font.family: "Inter, Roboto, sans-serif"
                color: Qt.rgba(1, 1, 1, 0.75)
                elide: Text.ElideRight
                Layout.fillWidth: true
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                verticalAlignment: Text.AlignVCenter
            }
        }

        // 3. Notification pulse indicator
        Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: 6
            radius: 3
            color: root.isWhatsApp ? "#25d366" : root.accentColor
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
