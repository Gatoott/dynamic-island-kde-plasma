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

## Installation Guide (Panduan Instalasi dari Nol)

Ikuti langkah-langkah praktis berikut untuk menginstal dan menjalankan Plasma Dynamic Island di desktop KDE Plasma 6 kamu:

### Langkah 1: Install Dependencies

Buka terminal (**Konsole**), lalu jalankan perintah instalasi paket sesuai distribusi Linux yang kamu gunakan:

#### 🔹 Arch Linux / Manjaro / EndeavourOS
```bash
sudo pacman -S --needed git qt6-declarative qt6-5compat kirigami libnotify playerctl
```

#### 🔹 Ubuntu / Kubuntu / Debian / KDE neon
```bash
sudo apt update && sudo apt install -y git qml6-module-qtquick qml6-module-qtquick-shapes qml6-module-org-kde-kirigami libnotify-bin playerctl
```

#### 🔹 Fedora / Nobara
```bash
sudo dnf install -y git qt6-qtdeclarative qt6-qt5compat kf6-kirigami libnotify playerctl
```

#### 🔹 openSUSE (Tumbleweed / Leap)
```bash
sudo zypper install -y git qt6-declarative kirigami-imports libnotify playerctl
```

---

### Langkah 2: Clone Repositori (Langsung ke Folder Plasmoid)

Jalankan perintah ini di terminal. Widget akan langsung di-clone ke direktori plasmoids KDE Plasma tanpa perlu pusing mengatur symlink manual:

```bash
# Buat folder plasmoid jika belum ada, lalu clone langsung
mkdir -p ~/.local/share/plasma/plasmoids
git clone https://github.com/Gatoott/dynamic-island-kde-plasma.git ~/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland
```

---

### Langkah 3: Muat Ulang Plasma (Restart Plasmashell)

Bersihkan cache QML lama dan restart plasmashell agar KDE langsung mengenali widget baru:

```bash
rm -rf ~/.cache/qmlcache* ~/.cache/plasma* && systemctl --user restart plasma-plasmashell
```

---

### Langkah 4: Tambahkan Widget ke Panel Layar

1. **Klik kanan** pada Panel Atas (*Top Panel*) atau Desktop kamu.
2. Pilih **"Add Widgets..."** (*Tambahkan Widget...*).
3. Cari **"Plasma Dynamic Island"**.
4. Tarik (*drag & drop*) widget tersebut ke posisi tengah panel atas layar kamu.
5. Selesai! Dynamic Island sudah aktif dan siap digunakan. 🎉

---

### 💡 Tips: Update & Uninstall

- **Cara Update ke Versi Terbaru:**
  ```bash
  cd ~/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland && git pull && systemctl --user restart plasma-plasmashell
  ```

- **Cara Uninstall (Hapus Widget):**
  ```bash
  rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland && systemctl --user restart plasma-plasmashell
  ```

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
