import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    property alias cfg_compactWidth: compactWidthSpin.value
    property alias cfg_compactHeight: compactHeightSpin.value
    property alias cfg_expandedWidth: expandedWidthSpin.value
    property alias cfg_expandedHeight: expandedHeightSpin.value
    property alias cfg_borderRadius: borderRadiusSpin.value

    property alias cfg_islandShapeMode: shapeModeHiddenField.text
    property alias cfg_verticalOffset: verticalOffsetSpin.value
    property alias cfg_horizontalOffset: horizontalOffsetSpin.value
    property alias cfg_clockFontSize: clockFontSizeSpin.value
    property alias cfg_notchCornerRadius: notchCornerRadiusSpin.value

    QQC2.TextField {
        id: shapeModeHiddenField
        visible: false
        text: "notch"
    }

    property alias cfg_backgroundColor: bgColorField.text
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_borderColor: borderColorField.text
    property alias cfg_accentColor: accentColorField.text
    property alias cfg_expandOnHover: hoverSwitch.checked
    property alias cfg_showVisualizer: visualizerSwitch.checked
    property alias cfg_notificationDuration: notifDurationSpin.value

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
                text: i18n("📌 Nempel Atas (-8px)")
                onClicked: verticalOffsetSpin.value = -8
            }
            QQC2.Button {
                text: i18n("🔄 0px")
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
            Kirigami.FormData.label: i18n("Ukuran Font Jam Standby:")
            spacing: 8
            QQC2.SpinBox {
                id: clockFontSizeSpin
                from: 9
                to: 20
                stepSize: 1
                editable: true
            }
            QQC2.Label { text: "pt" }
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
                text: i18n("🎨 Pilih")
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
                text: i18n("🎨 Pilih")
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
                text: i18n("🎨 Pilih")
                onClicked: accentColDialog.open()
            }
        }

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
                value: 4500
                editable: true
            }
            QQC2.Label { text: "ms" }
        }
    }
}
