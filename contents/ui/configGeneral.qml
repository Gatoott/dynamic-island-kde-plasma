import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    // Dimensions & Offsets
    property alias cfg_compactWidth: compactWidthSpin.value
    property alias cfg_compactHeight: compactHeightSpin.value
    property alias cfg_expandedWidth: expandedWidthSpin.value
    property alias cfg_expandedHeight: expandedHeightSpin.value
    property alias cfg_borderRadius: borderRadiusSpin.value

    property alias cfg_islandShapeMode: shapeModeHiddenField.text
    property alias cfg_verticalOffset: verticalOffsetSpin.value
    property alias cfg_horizontalOffset: horizontalOffsetSpin.value
    property alias cfg_notchCornerRadius: notchCornerRadiusSpin.value

    QQC2.TextField {
        id: shapeModeHiddenField
        visible: false
        text: "notch"
    }

    // Appearance
    property alias cfg_backgroundColor: bgColorField.text
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_borderColor: borderColorField.text
    property alias cfg_accentColor: accentColorField.text
    property alias cfg_expandOnHover: hoverSwitch.checked
    property alias cfg_showVisualizer: visualizerSwitch.checked
    property alias cfg_showCompactVisualizer: compactVisualizerCheck.checked
    property alias cfg_notificationDuration: notifDurationSpin.value

    // Tab Visibility Toggles
    property alias cfg_showControlTab: showControlTabCheck.checked
    property alias cfg_showMediaTab: showMediaTabCheck.checked
    property alias cfg_showClipboardTab: showClipboardTabCheck.checked
    property alias cfg_showNotificationTab: showNotificationTabCheck.checked

    // Clock Typography
    property alias cfg_clockFontFamily: clockFontCombo.currentText
    property alias cfg_clockFontSize: clockFontSizeSpin.value
    property alias cfg_clockFontBold: clockFontBoldSwitch.checked

    // Lyrics Typography & Settings
    property alias cfg_lyricsFontFamily: lyricsFontCombo.currentText
    property alias cfg_lyricsFontSize: lyricsFontSizeSpin.value
    property alias cfg_lyricsFontBold: lyricsFontBoldSwitch.checked
    property alias cfg_autoRetryLyrics: autoRetryLyricsCheck.checked

    readonly property var systemFonts: ["Default (Inter/Roboto)"].concat(Qt.fontFamilies())

    QtDialogs.ColorDialog {
        id: bgColDialog
        title: i18n("Pilih Warna Background")
        selectedColor: bgColorField.text !== "" ? bgColorField.text : "#0d0f12"
        onAccepted: bgColorField.text = selectedColor.toString()
    }

    QtDialogs.ColorDialog {
        id: accentColDialog
        title: i18n("Pilih Warna Aksen")
        selectedColor: accentColorField.text !== "" ? accentColorField.text : "#3daee9"
        onAccepted: accentColorField.text = selectedColor.toString()
    }

    QtDialogs.ColorDialog {
        id: borderColDialog
        title: i18n("Pilih Warna Border")
        selectedColor: borderColorField.text !== "" ? borderColorField.text : "#33ffffff"
        onAccepted: borderColorField.text = selectedColor.toString()
    }

    Kirigami.FormLayout {
        id: mainForm
        Layout.fillWidth: true

        // =========================================================
        // 1. MODULAR TAB TOGGLES
        // =========================================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Pilihan Tab Aktif (Modular Visibility)")
        }

        QQC2.CheckBox {
            id: showControlTabCheck
            Kirigami.FormData.label: i18n("Tab Kontrol Utama:")
            text: i18n("Aktifkan Tab Control Center & System Monitor")
            checked: true
        }

        QQC2.CheckBox {
            id: showMediaTabCheck
            Kirigami.FormData.label: i18n("Tab Media & Lirik:")
            text: i18n("Aktifkan Tab Pemutar Musik & Synced Lyrics")
            checked: true
        }

        QQC2.CheckBox {
            id: showClipboardTabCheck
            Kirigami.FormData.label: i18n("Tab Riwayat Clipboard:")
            text: i18n("Aktifkan Tab Pengelola Clipboard (Klipper)")
            checked: true
        }

        QQC2.CheckBox {
            id: showNotificationTabCheck
            Kirigami.FormData.label: i18n("Tab Riwayat Notifikasi:")
            text: i18n("Aktifkan Tab Daftar Notifikasi Masuk")
            checked: true
        }

        QQC2.CheckBox {
            id: compactVisualizerCheck
            Kirigami.FormData.label: i18n("Visualizer Lirik Notch:")
            text: i18n("Tampilkan audio visualizer mini di sisi kanan pill lirik notch")
            checked: false
        }

        // =========================================================
        // 2. CLOCK TYPOGRAPHY
        // =========================================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Tipografi Jam Standby")
        }

        QQC2.ComboBox {
            id: clockFontCombo
            Kirigami.FormData.label: i18n("Font Family Jam:")
            model: configPage.systemFonts
            Layout.preferredWidth: 260
            Component.onCompleted: {
                var idx = find(cfg_clockFontFamily || "Default (Inter/Roboto)");
                if (idx >= 0) currentIndex = idx;
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Ukuran Font Jam:")
            spacing: 8
            QQC2.SpinBox {
                id: clockFontSizeSpin
                from: 9
                to: 24
                value: 13
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "pt" }
        }

        QQC2.CheckBox {
            id: clockFontBoldSwitch
            Kirigami.FormData.label: i18n("Bobot Font Jam:")
            text: i18n("Tebal (Bold)")
            checked: true
        }

        // =========================================================
        // 3. LYRICS TYPOGRAPHY IN NOTCH
        // =========================================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Tipografi Lirik Musik di Notch")
        }

        QQC2.ComboBox {
            id: lyricsFontCombo
            Kirigami.FormData.label: i18n("Font Family Lirik:")
            model: configPage.systemFonts
            Layout.preferredWidth: 260
            Component.onCompleted: {
                var idx = find(cfg_lyricsFontFamily || "Default (Inter/Roboto)");
                if (idx >= 0) currentIndex = idx;
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Ukuran Font Lirik:")
            spacing: 8
            QQC2.SpinBox {
                id: lyricsFontSizeSpin
                from: 9
                to: 24
                value: 13
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "pt" }
        }

        QQC2.CheckBox {
            id: lyricsFontBoldSwitch
            Kirigami.FormData.label: i18n("Bobot Font Lirik:")
            text: i18n("Tebal (Bold / DemiBold)")
            checked: true
        }

        QQC2.CheckBox {
            id: autoRetryLyricsCheck
            Kirigami.FormData.label: i18n("Auto-Retry Lirik:")
            text: i18n("Otomatis coba lagi jika lirik gagal ditemukan (Auto-retry lyrics)")
            checked: true
        }

        // =========================================================
        // 4. MODE & POSISI
        // =========================================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Mode & Posisi")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Mode Tampilan:")
            spacing: 16
            QQC2.RadioButton {
                text: i18n("Notch (Nempel Atas)")
                checked: shapeModeHiddenField.text === "notch"
                onToggled: if (checked) shapeModeHiddenField.text = "notch"
            }
            QQC2.RadioButton {
                text: i18n("Dock (Mengambang)")
                checked: shapeModeHiddenField.text === "dock"
                onToggled: if (checked) shapeModeHiddenField.text = "dock"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Margin Vertikal (Y-Offset):")
            spacing: 8
            QQC2.SpinBox {
                id: verticalOffsetSpin
                from: -150
                to: 150
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
            QQC2.Button {
                text: i18n("Nempel Atas (-8px)")
                onClicked: verticalOffsetSpin.value = -8
            }
            QQC2.Button {
                text: i18n("Reset 0px")
                onClicked: verticalOffsetSpin.value = 0
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Offset Horizontal (X-Offset):")
            spacing: 8
            QQC2.SpinBox {
                id: horizontalOffsetSpin
                from: -300
                to: 300
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        // =========================================================
        // 5. UKURAN & DIMENSI
        // =========================================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Ukuran & Dimensi")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Corner Radius Notch Bawah:")
            spacing: 8
            QQC2.SpinBox {
                id: notchCornerRadiusSpin
                from: 4
                to: 32
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Tinggi Standby Pill:")
            spacing: 8
            QQC2.SpinBox {
                id: compactHeightSpin
                from: 24
                to: 60
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Lebar Standby Default:")
            spacing: 8
            QQC2.SpinBox {
                id: compactWidthSpin
                from: 100
                to: 300
                stepSize: 5
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Dimensi Expanded (Lebar x Tinggi):")
            spacing: 8
            QQC2.SpinBox {
                id: expandedWidthSpin
                from: 350
                to: 800
                stepSize: 10
                editable: true
            }
            QQC2.Label { text: "x" }
            QQC2.SpinBox {
                id: expandedHeightSpin
                from: 200
                to: 600
                stepSize: 10
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        RowLayout {
            visible: false
            QQC2.SpinBox { id: borderRadiusSpin; from: 0; to: 30; value: 18 }
        }

        // =========================================================
        // 6. WARNA & TAMPILAN
        // =========================================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Warna & Tampilan")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Warna Background:")
            spacing: 8
            QQC2.TextField {
                id: bgColorField
                text: "#0d0f12"
                Layout.preferredWidth: 100
            }
            QQC2.Button {
                text: i18n("Pilih...")
                onClicked: bgColDialog.open()
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Opasitas Background:")
            spacing: 8
            QQC2.Slider {
                id: opacitySlider
                from: 0.1
                to: 1.0
                stepSize: 0.05
                value: 0.95
                Layout.preferredWidth: 150
            }
            QQC2.Label {
                text: Math.round(opacitySlider.value * 100) + "%"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Warna Border:")
            spacing: 8
            QQC2.TextField {
                id: borderColorField
                text: "#33ffffff"
                Layout.preferredWidth: 100
            }
            QQC2.Button {
                text: i18n("Pilih...")
                onClicked: borderColDialog.open()
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Warna Aksen:")
            spacing: 8
            QQC2.TextField {
                id: accentColorField
                text: "#3daee9"
                Layout.preferredWidth: 100
            }
            QQC2.Button {
                text: i18n("Pilih...")
                onClicked: accentColDialog.open()
            }
        }

        // =========================================================
        // 7. INTERAKSI & FITUR
        // =========================================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Interaksi & Fitur")
        }

        QQC2.CheckBox {
            id: visualizerSwitch
            Kirigami.FormData.label: i18n("Audio Visualizer:")
            text: i18n("Tampilkan bar visualizer mini saat musik berputar")
            checked: true
        }

        QQC2.CheckBox {
            id: hoverSwitch
            Kirigami.FormData.label: i18n("Expand on Hover:")
            text: i18n("Buka notch otomatis saat kursor mouse melintas")
            checked: false
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Durasi Notifikasi:")
            spacing: 8
            QQC2.SpinBox {
                id: notifDurationSpin
                from: 1000
                to: 15000
                stepSize: 500
                value: 4000
                editable: true
            }
            QQC2.Label { text: "ms" }
        }
    }
}
