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
    property alias cfg_notchStyle: notchStyleSpin.value
    property alias cfg_verticalOffset: verticalOffsetSpin.value
    property alias cfg_horizontalOffset: horizontalOffsetSpin.value
    property alias cfg_notchCornerRadius: bottomRadiusSpin.value
    property alias cfg_notchBottomRadius: bottomRadiusSpin.value
    property alias cfg_notchWingRadius: wingRadiusSpin.value
    property alias cfg_islandPadding: islandPaddingSpin.value
    property alias cfg_enableBlur: enableBlurSwitch.checked
    property alias cfg_expandedBgStyle: expandedBgStyleCombo.currentIndex
    property alias cfg_mediaCardBgMode: mediaCardBgModeCombo.currentIndex
    property alias cfg_mediaBgStyle: mediaCardBgModeCombo.currentIndex
    property alias cfg_lyricsBgMode: lyricsBgModeCombo.currentIndex

    QQC2.TextField {
        id: shapeModeHiddenField
        visible: false
        text: "notch"
    }

    QQC2.SpinBox {
        id: islandPaddingSpin
        visible: false
        from: 0
        to: 100
        value: 12
    }

    QQC2.CheckBox {
        id: enableBlurSwitch
        visible: false
        checked: true
    }

    QQC2.SpinBox {
        id: notchStyleSpin
        visible: false
        from: 0
        to: 1
        value: 0
        Component.onCompleted: {
            if (value === 0 && (shapeModeHiddenField.text === "dock" || shapeModeHiddenField.text === "pill" || shapeModeHiddenField.text === "circle")) {
                value = 1;
            }
        }
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

    // Clock Typography
    property alias cfg_clockFontFamily: clockFontCombo.currentText
    property alias cfg_clockFontSize: clockFontSizeSpin.value
    property alias cfg_clockFontBold: clockFontBoldSwitch.checked

    // Lyrics Typography & Settings
    property alias cfg_lyricsFontFamily: lyricsFontCombo.currentText
    property alias cfg_lyricsFontSize: lyricsFontSizeSpin.value
    property alias cfg_lyricsFontBold: lyricsFontBoldSwitch.checked
    property alias cfg_autoRetryLyrics: autoRetryLyricsCheck.checked

    // Mini Music Icon Customization
    property alias cfg_miniMusicIconEnabled: miniMusicIconEnabledCheck.checked
    property alias cfg_miniMusicIconSize: miniMusicIconSizeSpin.value
    property alias cfg_miniMusicIconWeight: miniMusicIconWeightSpin.value
    property alias cfg_miniMusicIconColorMode: miniMusicIconColorModeCombo.currentIndex
    property alias cfg_miniMusicIconCustomColor: miniMusicIconCustomColorField.text

    // Mini Visualizer (Compact Pill) Customization
    property alias cfg_miniVisAlignment: miniVisAlignmentCombo.currentIndex
    property alias cfg_miniVisColorMode: miniVisColorModeCombo.currentIndex
    property alias cfg_miniVisCustomColor: miniVisCustomColorField.text
    property alias cfg_miniVisBarWidth: miniVisBarWidthSpin.value
    property alias cfg_miniVisSpacing: miniVisSpacingSpin.value
    property alias cfg_miniVisHeight: miniVisHeightSpin.value
    property alias cfg_miniVisMaxHeight: miniVisHeightSpin.value
    property alias cfg_miniVisRounded: miniVisRoundedCheck.checked

    // Tab Visibility Toggles (Grup 3 - Paling Bawah)
    property alias cfg_showMediaTab: showMediaTabCheck.checked
    property alias cfg_showNotificationTab: showNotificationTabCheck.checked
    property alias cfg_showControlTab: showControlTabCheck.checked
    property alias cfg_showClipboardTab: showClipboardTabCheck.checked

    readonly property var systemFonts: ["Default (Inter/Roboto)"].concat(Qt.fontFamilies())

    QtDialogs.ColorDialog {
        id: musicIconColDialog
        title: i18n("Pilih Warna Ikon Musik")
        selectedColor: miniMusicIconCustomColorField.text !== "" ? miniMusicIconCustomColorField.text : "#ffffff"
        onAccepted: miniMusicIconCustomColorField.text = selectedColor.toString()
    }

    QtDialogs.ColorDialog {
        id: miniVisColDialog
        title: i18n("Pilih Warna Custom Visualizer")
        selectedColor: miniVisCustomColorField.text !== "" ? miniVisCustomColorField.text : "#38bdf8"
        onAccepted: miniVisCustomColorField.text = selectedColor.toString()
    }

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
        // GRUP 1: STANDBY PILL & JAM (KAPSUL STANDBY & MINI VISUALIZER)
        // =========================================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Standby Pill & Jam Standby")
        }

        // --- Tipografi & Format Jam ---
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

        // --- Kustomisasi Ikon Musik (Kiri Jam) ---
        QQC2.CheckBox {
            id: miniMusicIconEnabledCheck
            Kirigami.FormData.label: i18n("Ikon Musik Standby:")
            text: i18n("Tampilkan ikon musik (♫) di kiri jam saat lagu diputar")
            checked: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Ukuran Ikon Musik:")
            enabled: miniMusicIconEnabledCheck.checked
            spacing: 8
            QQC2.SpinBox {
                id: miniMusicIconSizeSpin
                from: 8
                to: 24
                value: 13
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        QQC2.SpinBox {
            id: miniMusicIconWeightSpin
            visible: false
            from: 100
            to: 900
            value: 600
        }

        QQC2.ComboBox {
            id: miniMusicIconWeightCombo
            Kirigami.FormData.label: i18n("Ketebalan Ikon Musik:")
            enabled: miniMusicIconEnabledCheck.checked
            model: [
                i18n("Tipis (Light - 300)"),
                i18n("Normal (Regular - 400)"),
                i18n("Sedang (Medium - 600)"),
                i18n("Tebal (Bold - 700)")
            ]
            Layout.preferredWidth: 260
            currentIndex: {
                var w = miniMusicIconWeightSpin.value;
                if (w <= 300) return 0;
                if (w <= 400) return 1;
                if (w <= 600) return 2;
                return 3;
            }
            onActivated: (index) => {
                var weights = [300, 400, 600, 700];
                miniMusicIconWeightSpin.value = weights[index];
            }
        }

        QQC2.ComboBox {
            id: miniMusicIconColorModeCombo
            Kirigami.FormData.label: i18n("Mode Warna Ikon Musik:")
            enabled: miniMusicIconEnabledCheck.checked
            model: [
                i18n("Warna Album (Dynamic Tint)"),
                i18n("Warna Aksen Sistem KDE"),
                i18n("Putih / Abu Standar"),
                i18n("Warna Hex Kustom")
            ]
            Layout.preferredWidth: 260
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Warna Kustom Ikon:")
            visible: miniMusicIconColorModeCombo.currentIndex === 3
            enabled: miniMusicIconEnabledCheck.checked
            spacing: 8

            QQC2.TextField {
                id: miniMusicIconCustomColorField
                text: "#ffffff"
                Layout.preferredWidth: 100
            }

            Rectangle {
                width: 24
                height: 24
                radius: 4
                color: miniMusicIconCustomColorField.text !== "" ? miniMusicIconCustomColorField.text : "#ffffff"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.2)
            }

            QQC2.Button {
                text: i18n("Pilih...")
                onClicked: musicIconColDialog.open()
            }
        }

        // --- Kustomisasi Mini Visualizer di Samping Jam ---
        QQC2.CheckBox {
            id: visualizerSwitch
            Kirigami.FormData.label: i18n("Visualizer Mini Jam:")
            text: i18n("Aktifkan visualizer mini di samping jam standby")
            checked: true
        }

        QQC2.ComboBox {
            id: miniVisColorModeCombo
            Kirigami.FormData.label: i18n("Mode Warna Visualizer:")
            enabled: visualizerSwitch.checked
            model: [
                i18n("Warna Cover Album (Dynamic Tint)"),
                i18n("Warna Aksen Sistem (KDE Accent)"),
                i18n("Warna Hex Kustom (Custom Color)")
            ]
            Layout.preferredWidth: 260
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Warna Kustom Visualizer:")
            visible: miniVisColorModeCombo.currentIndex === 2
            enabled: visualizerSwitch.checked
            spacing: 8

            QQC2.TextField {
                id: miniVisCustomColorField
                text: "#38bdf8"
                Layout.preferredWidth: 100
            }

            Rectangle {
                width: 24
                height: 24
                radius: 4
                color: miniVisCustomColorField.text !== "" ? miniVisCustomColorField.text : "#38bdf8"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.2)
            }

            QQC2.Button {
                text: i18n("Pilih...")
                onClicked: miniVisColDialog.open()
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Ketebalan Bar (Width):")
            enabled: visualizerSwitch.checked
            spacing: 8
            QQC2.SpinBox {
                id: miniVisBarWidthSpin
                from: 1
                to: 6
                value: 2
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Jarak Antar Bar (Spacing):")
            enabled: visualizerSwitch.checked
            spacing: 8
            QQC2.SpinBox {
                id: miniVisSpacingSpin
                from: 1
                to: 5
                value: 2
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Tinggi Bar Visualizer:")
            enabled: visualizerSwitch.checked
            spacing: 8
            QQC2.SpinBox {
                id: miniVisHeightSpin
                from: 8
                to: 20
                value: 14
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        QQC2.ComboBox {
            id: miniVisAlignmentCombo
            Kirigami.FormData.label: i18n("Perataan Visualizer:")
            enabled: visualizerSwitch.checked
            model: [
                i18n("Bottom-Aligned (Memantul ke Atas)"),
                i18n("Center-Aligned (Mirrored / Simetris Atas-Bawah)")
            ]
            Layout.preferredWidth: 260
        }

        QQC2.CheckBox {
            id: miniVisRoundedCheck
            Kirigami.FormData.label: i18n("Bentuk Bar Visualizer:")
            enabled: visualizerSwitch.checked
            text: i18n("Ujung Membulat (Rounded Caps)")
            checked: true
        }

        // --- Bentuk & Dimensi Kapsul Standby ---
        RowLayout {
            Kirigami.FormData.label: i18n("Bentuk & Gaya (Style):")
            spacing: 16
            QQC2.RadioButton {
                text: i18n("Living Notch (Menempel di Atas)")
                checked: notchStyleSpin.value === 0
                onToggled: if (checked) {
                    notchStyleSpin.value = 0;
                    shapeModeHiddenField.text = "notch";
                    if (verticalOffsetSpin.value === 12) {
                        verticalOffsetSpin.value = 0;
                    }
                }
            }
            QQC2.RadioButton {
                text: i18n("Floating Capsule (Kapsul Mengambang)")
                checked: notchStyleSpin.value === 1
                onToggled: if (checked) {
                    notchStyleSpin.value = 1;
                    shapeModeHiddenField.text = "pill";
                    if (verticalOffsetSpin.value === 0) {
                        verticalOffsetSpin.value = 12;
                    }
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Margin Vertikal (Y-Offset):")
            spacing: 6
            QQC2.SpinBox {
                id: verticalOffsetSpin
                from: -100
                to: 100
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
            QQC2.Button {
                text: i18n("Tarik Atas (-8px)")
                onClicked: verticalOffsetSpin.value = -8
            }
            QQC2.Button {
                text: i18n("Rapat (-4px)")
                onClicked: verticalOffsetSpin.value = -4
            }
            QQC2.Button {
                text: i18n("Reset (0px)")
                onClicked: verticalOffsetSpin.value = 0
            }
            QQC2.Button {
                text: i18n("Rapat (4px)")
                onClicked: verticalOffsetSpin.value = 4
            }
            QQC2.Button {
                text: i18n("Default (12px)")
                onClicked: verticalOffsetSpin.value = 12
            }
            QQC2.Button {
                text: i18n("Lega (20px)")
                onClicked: verticalOffsetSpin.value = 20
            }
        }

        QQC2.Label {
            text: i18n("Nilai negatif (-) menggeser ke atas/merapatkan tepi, nilai positif (+) menurunkan posisi kapsul ke bawah.")
            font.pixelSize: 11
            opacity: 0.7
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
            Kirigami.FormData.label: i18n("Lekukan Sayap Atas (Top Wing):")
            spacing: 8
            QQC2.SpinBox {
                id: wingRadiusSpin
                from: 0
                to: 28
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Sudut Bawah Notch (Bottom Corner):")
            spacing: 8
            QQC2.SpinBox {
                id: bottomRadiusSpin
                from: 0
                to: 28
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "px" }
        }

        // --- Tipografi Lirik Musik di Notch ---
        QQC2.ComboBox {
            id: lyricsFontCombo
            Kirigami.FormData.label: i18n("Font Family Lirik Notch:")
            model: configPage.systemFonts
            Layout.preferredWidth: 260
            Component.onCompleted: {
                var idx = find(cfg_lyricsFontFamily || "Default (Inter/Roboto)");
                if (idx >= 0) currentIndex = idx;
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Ukuran Font Lirik Notch:")
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
            Kirigami.FormData.label: i18n("Bobot Font Lirik Notch:")
            text: i18n("Tebal (Bold / DemiBold)")
            checked: true
        }

        QQC2.CheckBox {
            id: compactVisualizerCheck
            Kirigami.FormData.label: i18n("Visualizer Lirik Notch:")
            text: i18n("Tampilkan audio visualizer mini di sisi kanan pill lirik notch")
            checked: false
        }

        QQC2.CheckBox {
            id: autoRetryLyricsCheck
            Kirigami.FormData.label: i18n("Auto-Retry Lirik:")
            text: i18n("Otomatis coba lagi jika lirik gagal ditemukan (Auto-retry lyrics)")
            checked: true
        }

        // =========================================================
        // GRUP 2: DESAIN & TAMPILAN KARTU EXPANDED
        // =========================================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Desain & Tampilan Kartu Expanded")
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

        RowLayout {
            Kirigami.FormData.label: i18n("Latar Belakang Notch Expanded:")
            spacing: 8
            QQC2.ComboBox {
                id: expandedBgStyleCombo
                model: [
                    i18n("Solid Deep Black (Default)"),
                    i18n("Glassy Frosted Blur (macOS Style)")
                ]
                Layout.preferredWidth: 260
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Latar Belakang Media Player:")
            spacing: 8
            QQC2.ComboBox {
                id: mediaCardBgModeCombo
                model: [
                    i18n("Pure Dark (Hitam Pekat)"),
                    i18n("Warna Album Penuh (Full Tint)"),
                    i18n("Gradasi Album (Atas Hitam -> Bawah Album)"),
                    i18n("Liquid Glass / Blur")
                ]
                Layout.preferredWidth: 280
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Latar Belakang Mode Lirik:")
            spacing: 8
            QQC2.ComboBox {
                id: lyricsBgModeCombo
                model: [
                    i18n("Hitam Pekat Minimalis / Pure Dark"),
                    i18n("Gradasi Rona Album (Bottom Album Tint)")
                ]
                Layout.preferredWidth: 260
            }
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

        // =========================================================
        // GRUP 3: PENGATURAN TAB AKTIF (PALING BAWAH)
        // =========================================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Pengaturan Tab Aktif (Modular Visibility)")
        }

        QQC2.Label {
            text: i18n("Pilih tab yang ingin ditampilkan atau disembunyikan saat notch terbuka:")
            font.pixelSize: 11
            opacity: 0.7
        }

        QQC2.CheckBox {
            id: showMediaTabCheck
            Kirigami.FormData.label: i18n("Tab Media & Lirik:")
            text: i18n("Aktifkan Tab Pemutar Musik & Synced Lyrics (Default Depan)")
            checked: true
        }

        QQC2.CheckBox {
            id: showNotificationTabCheck
            Kirigami.FormData.label: i18n("Tab Riwayat Notifikasi:")
            text: i18n("Aktifkan Tab Riwayat Notifikasi Masuk")
            checked: true
        }

        QQC2.CheckBox {
            id: showControlTabCheck
            Kirigami.FormData.label: i18n("Tab Kontrol Utama:")
            text: i18n("Aktifkan Tab Control Center & System Monitor")
            checked: true
        }

        QQC2.CheckBox {
            id: showClipboardTabCheck
            Kirigami.FormData.label: i18n("Tab Riwayat Clipboard:")
            text: i18n("Aktifkan Tab Pengelola Clipboard (Klipper)")
            checked: true
        }
    }
}
