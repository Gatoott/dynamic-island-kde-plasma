# Plasma Dynamic Island

<p align="center">
  <em>A native, fluid Living Notch & Dynamic Island widget crafted for KDE Plasma 6.</em>
</p>

<p align="center">
  <a href="https://kde.org/plasma-desktop/"><img src="https://img.shields.io/badge/KDE%20Plasma-6.0+-blue.svg?style=for-the-badge&logo=kde&logoColor=white" alt="KDE Plasma 6" /></a>
  <a href="https://www.qt.io/"><img src="https://img.shields.io/badge/Qt-6.0+-41CD52.svg?style=for-the-badge&logo=qt&logoColor=white" alt="Qt 6" /></a>
  <a href="https://wayland.freedesktop.org/"><img src="https://img.shields.io/badge/Wayland-Ready-orange.svg?style=for-the-badge&logo=wayland&logoColor=white" alt="Wayland Ready" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-purple.svg?style=for-the-badge" alt="License MIT" /></a>
</p>

---

**Plasma Dynamic Island** menghadirkan pengalaman antarmuka modern yang adaptif, halus, dan interaktif langsung ke desktop Linux Anda. Dirancang khusus untuk **KDE Plasma 6**, widget ini menggabungkan estetika *living notch* fisik dengan fluiditas transisi animasi pegas, kontrol multimedia pintar, visualizer audio, pemantauan sistem, dan integrasi notifikasi desktop.

---

## Showcase / Preview

Berikut adalah tampilan antarmuka dan berbagai mode interaksi dari Plasma Dynamic Island:

### 1. Idle Listening Mode
> *Notch saat media diputar (Idle Listening Mode)*

<p align="center">
  <img src="overview/idle listening.png" alt="Notch saat media diputar (Idle Listening Mode)" width="100%" />
</p>

---

### 2. Idle Mode
> *Notch standby jam default (Idle Mode)*

<p align="center">
  <img src="overview/idle.png" alt="Notch standby jam default (Idle Mode)" width="100%" />
</p>

---

### 3. Dynamic Lyrics Pill in Notch
> *Dynamic line-by-line lyrics langsung di notch panel*

<p align="center">
  <img src="overview/lirik notch.png" alt="Dynamic line-by-line lyrics langsung di notch panel" width="100%" />
</p>

---

### 4. Expanded Media Player Card
> *Expanded Media Player landscape card*

<p align="center">
  <img src="overview/tab media playing.png" alt="Expanded Media Player landscape card" width="100%" />
</p>

---

### 5. Synced Lyrics View (Album Color Palette)
> *Split 2-column Synced Lyrics view dengan rona warna cover album*

<p align="center">
  <img src="overview/tab lirik.png" alt="Split 2-column Synced Lyrics view dengan rona warna cover album" width="100%" />
</p>

---

### 6. Control Center Hub & System Status
> *Control Center Hub & System Status Monitoring*

<p align="center">
  <img src="overview/tab menu.png" alt="Control Center Hub & System Status Monitoring" width="100%" />
</p>

---

### 7. Universal Notification Pill
> *Universal Notification Pill trigger*

<p align="center">
  <img src="overview/notifikasi.png" alt="Universal Notification Pill trigger" width="100%" />
</p>

---

## Key Features

- **Living Notch Geometry:**  
  Siluet kontur melengkung cekung (*concave wings/fillet*) yang menyatu secara alami ke bibir layar atas menggunakan rendering vektor presisi berbasis `QtQuick.Shapes`.

- **Fluid Spring Animations:**  
  Transisi morphing dimensi elastis dan dinamis berbasis fisika pegas (`Easing.OutBack` / `Easing.OutQuad`) untuk ekspansi dan penciutan yang mulus tanpa kedip (*flicker-free*).

- **Media Player & Synced Lyrics:**  
  - Tampilan kartu lanskap horizontal kompak dengan latar belakang rona adaptif mengikuti warna dominan cover album.
  - Sinkronisasi lirik kata demi kata & detik demi detik secara otomatis via LRCLIB API.
  - Tampilan dynamic lyrics pill langsung di notch panel saat mendengarkan musik.

- **Universal Notification & Battery Trigger:**  
  Auto-expand ringkas saat notifikasi sistem masuk (menampilkan judul aplikasi dan notifikasi) serta perubahan status pengisian daya baterai dengan auto-collapse timer.

- **Control Center & System Monitor:**  
  Pusat kontrol serbaguna untuk memantau penggunaan CPU, RAM, suhu sistem, status baterai, quick toggle jaringan (Wi-Fi, Bluetooth, Power Profiles), serta slider volume audio dan kecerahan layar.

- **Clipboard Manager:**  
  Riwayat papan klip yang terintegrasi langsung dengan KDE Klipper melalui D-Bus untuk akses cepat salin-tempel.

- **Modular Customization:**  
  Kustomisasi penuh untuk mengatur visibilitas tiap tab, penyesuaian font, skala ukuran notch, serta toggle visualizer audio gelombang suara.

---

## Dependencies

Sebelum menginstal widget ini, pastikan sistem Anda telah memenuhi dependensi berikut:

- **KDE Plasma:** Versi 6.0 atau yang lebih baru
- **Qt 6 Framework:**
  - `QtQuick` & `QtQuick.Layouts`
  - `QtQuick.Shapes`
  - `org.kde.kirigami`
  - `org.kde.plasma.core` & `org.kde.plasma.plasmoid`
- **System Utilities:**
  - `libnotify` (untuk integrasi event notifikasi D-Bus)
  - `playerctl` atau pemutar musik yang mendukung spesifikasi **MPRIS D-Bus** (misal: Spotify, Elisa, VLC, Cider, Amberol, dll.)

---

## Installation Guide

### Opsi 1: Instalasi Cepat via Symlink (Rekomendasi Pengembang)

Clone repositori ini dan buat tautan simbolik (*symlink*) ke direktori plasmoids pengguna:

```bash
# 1. Clone repositori ke direktori pilihan Anda
git clone https://github.com/Gatoott/dynamic-island-kde-plasma.git ~/dynamic-island

# 2. Buat folder plasmoids lokal jika belum ada
mkdir -p ~/.local/share/plasma/plasmoids

# 3. Buat symlink ke direktori plasmoid KDE Plasma
ln -s ~/dynamic-island ~/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland
```

### Opsi 2: Instalasi Manual via `kpackagetool6`

Anda juga dapat menginstal paket plasmoid secara langsung menggunakan tool paket KDE Plasma 6:

```bash
# Instal plasmoid langsung dari folder sumber
kpackagetool6 --type Plasma/Applet --install /path/to/dynamic-island

# Jika ingin memperbarui versi yang sudah ada:
kpackagetool6 --type Plasma/Applet --upgrade /path/to/dynamic-island
```

### Menambahkan Widget ke Desktop / Panel

1. Klik kanan pada panel atas atau desktop Anda, lalu pilih **"Add Widgets..."** (*Tambahkan Widget...*).
2. Cari **"Plasma Dynamic Island"**.
3. Tarik (*drag & drop*) widget ke bagian tengah panel atas layar Anda.

---

## Troubleshooting

Jika setelah instalasi atau pembaruan widget tidak muncul dengan benar atau cache QML lama masih tertinggal, jalankan perintah pembersihan cache berikut di terminal:

```bash
# Hapus cache QML dan Plasma lalu restart plasmashell
rm -rf ~/.cache/qmlcache* ~/.cache/plasma* && systemctl --user restart plasma-plasmashell
```

---

## Feedback & Contact (Kritik & Saran)

> **Kritik & Saran:**  
> Punya ide fitur baru, menemukan bug, atau ingin berdiskusi seputar proyek ini? Kunjungi dan hubungi langsung melalui website: [muhammadarfa.my.id](https://www.muhammadarfa.my.id/).

---

<p align="center">
  Dibuat dengan vibe coding ❤️.
</p>
