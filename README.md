# Dynamic Island for KDE Plasma 6

<p align="center">
  <em>A fluid, adaptive Living Notch & Dynamic Island widget crafted for KDE Plasma 6.</em>
</p>

<p align="center">
  <a href="https://kde.org/plasma-desktop/"><img src="https://img.shields.io/badge/KDE%20Plasma-6.0+-blue.svg?style=for-the-badge&logo=kde&logoColor=white" alt="KDE Plasma 6" /></a>
  <a href="https://www.qt.io/"><img src="https://img.shields.io/badge/Qt-6.0+-41CD52.svg?style=for-the-badge&logo=qt&logoColor=white" alt="Qt 6" /></a>
  <a href="https://wayland.freedesktop.org/"><img src="https://img.shields.io/badge/Wayland-Ready-orange.svg?style=for-the-badge&logo=wayland&logoColor=white" alt="Wayland Ready" /></a>
  <a href="https://developer.apple.com/sf-symbols/"><img src="https://img.shields.io/badge/Design-SF%20Symbols%20%7C%20Liquid%20Glass-black.svg?style=for-the-badge" alt="SF Symbols | Liquid Glass" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-purple.svg?style=for-the-badge" alt="License MIT" /></a>
</p>

---

## 📽️ Video Preview

<p align="center">
  <video src="overview/preview.mp4" width="100%" controls autoplay loop muted></video>
</p>

<p align="center">
  <sub>🎬 <em>Jika video di atas tidak tampil di aplikasi browser/markdown Anda:</em> <a href="overview/preview.mp4"><strong>[Tonton Preview Video Langsung]</strong></a></sub>
</p>

---

**Dynamic Island for KDE Plasma 6** menghadirkan pengalaman antarmuka modern yang adaptif, mulus, dan interaktif langsung ke desktop Linux Anda. Dirancang khusus untuk arsitektur modern **KDE Plasma 6 (Wayland & X11)**, widget ini menggabungkan estetika *living notch* fisik dengan fluiditas transisi animasi pegas, kontrol multimedia pintar, visualizer audio spektrum simetris, pemantauan sistem real-time, dan integrasi notifikasi desktop.

---

## 🖼️ Tampilan Antarmuka (Visual Showcase)

Berikut adalah preview dari berbagai mode interaksi dan komponen antarmuka Plasma Dynamic Island:

### 1. Idle Listening Mode (Standby Pill Saat Musik Berputar)
> *Menampilkan Ikon Musik Cerdas ♫ di kiri, Jam Digital di tengah, dan Mini Audio Visualizer di kanan.*

<p align="center">
  <img src="overview/idle listening.png" alt="Notch saat media diputar (Idle Listening Mode)" width="100%" />
</p>

---

### 2. Standby Idle Mode (Kapsul Jam Standby)
> *Tampilan minimalis elegan saat tidak ada media yang diputar.*

<p align="center">
  <img src="overview/idle.png" alt="Notch standby jam default (Idle Mode)" width="100%" />
</p>

---

### 3. Dynamic Lyrics Pill in Notch
> *Dynamic line-by-line synced lyrics yang mengalir langsung di kapsul notch panel.*

<p align="center">
  <img src="overview/lirik notch.png" alt="Dynamic line-by-line lyrics langsung di notch panel" width="100%" />
</p>

---

### 4. Expanded Media Player Card
> *Kartu pemutar media horizontal dengan rona warna album cover, timeline slider interaktif, dan kontrol volume native Plasma 6.*

<p align="center">
  <img src="overview/tab media playing.png" alt="Expanded Media Player landscape card" width="100%" />
</p>

---

### 5. Synced Lyrics View (Split 2-Column)
> *Tampilan lirik lagu tersinkronisasi otomatis kata demi kata dengan auto-scroll dan palet rona cover album.*

<p align="center">
  <img src="overview/tab lirik.png" alt="Split 2-column Synced Lyrics view dengan rona warna cover album" width="100%" />
</p>

---

### 6. Control Center Hub & System Status
> *Pusat kontrol cepat: pemantauan CPU/RAM/Suhu/Baterai, quick toggles, slider kecerahan, dan slider volume master.*

<p align="center">
  <img src="overview/tab menu.png" alt="Control Center Hub & System Status Monitoring" width="100%" />
</p>

---

### 7. Universal Notification Pill
> *Pop-up notifikasi sistem dinamis yang melebar otomatis saat ada pesan atau peringatan sistem masuk.*

<p align="center">
  <img src="overview/notifikasi.png" alt="Universal Notification Pill trigger" width="100%" />
</p>

---

## ✨ Fitur-Fitur Utama (Key Features)

### 1. Standby Notch (Compact Pill)
- **Living Notch vs Floating Island:**  
  Mendukung 2 gaya geometri: **Living Notch** (melekat pada bezel atas layar dengan lekukan sayap cekung *inverted fillet* menggunakan rendering kurva vektor presisi berbasis `QtQuick.Shapes` `PathCubic`) dan **Floating Capsule** (kapsul mengambang mandiri dengan *border radius* penuh).
- **Jam & Tanggal Digital Presisi:**  
  Tipografi jam standby yang dapat disesuaikan sepenuhnya (font family, ukuran pixel, dan opsi huruf tebal/bold).
- **Ikon Musik Cerdas (Smart Music Icon):**  
  Otomatis muncul di sebelah kiri jam saat audio sedang diputar. Dapat dikustomisasi: toggle aktif/nonaktif, ukuran font (px), ketebalan bobot font (*Thin 100* hingga *Black 900*), serta 4 pilihan mode warna (adaptif warna album cover, aksen sistem KDE, putih redup, atau custom hex color).
- **Mini Audio Visualizer (Waveform Spectrum):**  
  Bar spektrum audio animasi di sebelah kanan jam dengan dukungan 2 mode arah pantulan:
  - **Center-Aligned / Mirrored:** Gelombang audio memantul simetris dari tengah ke atas dan ke bawah (Apple style).
  - **Bottom-Aligned:** Gelombang audio memantul ke atas dari dasar bar.
  - Dilengkapi kontrol ketebalan bar (*width*), jarak (*spacing*), tinggi maksimal, sudut membulat (*rounded bars*), serta mode warna dinamis/kustom.
- **Dynamic Lyrics Pill:**  
  Baris lirik yang sedang dinyanyikan tampil real-time detik demi detik di dalam kapsul standby saat mendengarkan musik.

### 2. Expanded Notch Card (macOS Style)
Kartu expanded dirancang dengan layout horizontal modern dan navigasi tab berbasis swipe atau tombol panah samping:
- **Urutan Tab Baru Terstruktur:**
  1. 🎵 **Media Player & Synchronized Lyrics:** Tab default utama saat notch dibuka.
  2. 🔔 **Notification Center:** Pusat riwayat notifikasi desktop.
  3. 🎛️ **Control Center / Quick Settings:** Pusat pemantauan sistem dan kontrol cepat.
  4. 📋 **Clipboard Manager:** Manajer riwayat papan klip Klipper.
- **Media Player Canggih:**
  - Cover album *squircle* beresolusi tinggi dengan pusat pencahayaan dinamis.
  - Seek slider timeline lagu interaktif dengan jarak aman dari tombol navigasi.
  - Tombol kontrol playback bergaya *Apple SF Symbols* (*Previous*, *Play/Pause*, *Next*).
  - **Integrasi Volume Native Plasma 6:** Ikon speaker dinamis (`speaker.wave.1.fill`, `speaker.wave.2.fill`, `speaker.wave.3.fill`, `speaker.slash.fill`) terhubung dua arah secara real-time dengan backend PipeWire/PulseAudio via `org.kde.plasma.private.volume`. Mendukung klik mute/unmute dan scroll wheel langsung di atas ikon speaker.
  - Tampilan jam dan tanggal yang otomatis beralih ke rata kiri saat mode tampilan lirik dibuka.
  - Tampilan bersih tanpa elemen pengganggu (badge "E" / explicit label telah dihilangkan sepenuhnya).
- **Notification Center:**
  - Ketinggian kartu seragam dan presisi dengan pemutar media (*zero jumping height*).
  - Listview notifikasi ber-`clip: true` dengan scrolling halus tanpa garis scrollbar yang mengganggu estetika.
- **Control Center (Pusat Kontrol Cepat):**
  - **System Resource Monitor:** Pemantauan real-time untuk penggunaan CPU (%), RAM (%), Suhu prosesor (°C), dan Status pengisian baterai (%).
  - **Quick Action Tiles:** Toggle cepat untuk Wi-Fi, Bluetooth, Dock Mode, dan Power Profile (*Power Save*, *Balanced*, *Performance*).
  - **Slider Kontrol Native PipeWire:** Slider volume master dan kecerahan layar (*brightness*) interaktif dengan indikator persentase real-time. Scroll wheel mouse pada slider dimatikan agar navigasi scroll halaman Flickable tetap lancar tanpa tersendat.
  - **Action Row Buttons:** Tombol Do Not Disturb (DND), Tombol Pengaturan (Roda Gigi) yang langsung memicu dialog konfigurasi plasmoid, dan Tombol Power/Session Logout dialog.
- **Clipboard Manager (KDE Klipper):**
  - Riwayat papan klip yang terhubung langsung melalui D-Bus untuk menyalin ulang teks dengan satu klik.

### 3. Estetika & Performa
- **4 Pilihan Latar Belakang Kartu Media:**
  1. **Pure Dark:** Hitam pekat minimalis (`#09090b`).
  2. **Warna Album Penuh (Full Tint):** Rona warna dominan cover album aktif di seluruh bidang kartu.
  3. **Gradasi Album (Album Bottom Gradient):** Bagian atas hitam pekat (`#09090b`) menyatu mulus tanpa batas dengan sayap notch dan panel atas layar, lalu memudar lembut ke warna cover album di bagian bawah kartu.
  4. **Liquid Glass / Blur:** Efek kaca akrilik buram semi-transparan (*macOS frosted glass style*).
- **Zero Black Corner Radius Artifacts:**  
  Lekukan sudut bawah kartu dan sayap atas (*concave wings fillet*) mewarisi rona warna latar belakang aktif secara presisi tanpa ada sudut hitam yang bocor atau garis potongan yang tidak menyatu.
- **Animasi Buka/Tutup Bebas Kedip (Anti-Flicker/Ghosting):**  
  Menggunakan arsitektur *Single Container Morphing* terpadu dengan transisi fisika pegas (`Easing.OutBack` / `Easing.OutQuad`) yang halus dan proteksi terhadap bug notch hilang saat diklik berulang kali.

---

## ⚙️ Referensi Pengaturan Lengkap (`main.xml` & `configGeneral.qml`)

Seluruh opsi konfigurasi dapat diatur secara visual melalui dialog setelan widget (klik kanan pada widget > **Configure Plasma Dynamic Island...** atau tekan tombol **Roda Gigi / Settings** pada tab Control Center):

| Kategori | Opsi Pengaturan | Tipe / Pilihan | Nilai Default | Keterangan |
| :--- | :--- | :--- | :--- | :--- |
| **Standby Pill** | `clockFontFamily` | String / Text | *(Kosong / Sistem)* | Nama font khusus untuk jam standby (contoh: `Inter`, `SF Pro Display`). |
| | `clockFontSize` | Integer (px) | `13` | Ukuran teks jam pada kapsul standby. |
| | `clockFontBold` | Boolean | `true` | Mengaktifkan format huruf tebal (**Bold**) pada jam standby. |
| | `compactWidth` | Integer (px) | `165` | Lebar default kapsul notch standby. |
| | `compactHeight` | Integer (px) | `36` | Tinggi kapsul notch standby. |
| **Ikon Musik (♫)** | `miniMusicIconEnabled` | Boolean | `true` | Menampilkan atau menyembunyikan ikon musik di kiri jam saat audio aktif. |
| | `miniMusicIconSize` | Integer (px) | `13` | Ukuran dimensi font ikon musik ♫. |
| | `miniMusicIconWeight` | Integer | `600` | Bobot font ikon musik (*Thin 100*, *Light 300*, *Normal 400*, *Medium 500*, *SemiBold 600*, *Bold 700*, *Black 900*). |
| | `miniMusicIconColorMode`| Integer (0–3) | `0` | Mode warna ikon musik:<br>• `0`: Warna Album Cover (Dynamic)<br>• `1`: Aksen Sistem KDE Plasma<br>• `2`: Putih / Abu Redup<br>• `3`: Custom Color Picker |
| | `miniMusicIconCustomColor` | Color | `#ffffff` | Kode warna heksadesimal untuk ikon musik jika mode custom aktif. |
| **Mini Visualizer** | `showVisualizer` | Boolean | `true` | Menampilkan bar visualizer mini audio di kanan jam. |
| | `miniVisAlignment` | Integer (0–1) | `1` | Arah pantulan bar visualizer:<br>• `0`: *Bottom-Aligned* (ke atas)<br>• `1`: *Center-Aligned / Mirrored* (simetris atas-bawah) |
| | `miniVisColorMode` | Integer (0–2) | `0` | Pilihan warna bar:<br>• `0`: Warna Cover Album Dinamis<br>• `1`: Warna Aksen Sistem KDE<br>• `2`: Custom Color Picker |
| | `miniVisCustomColor` | Color | `#38bdf8` | Warna kustom bar mini visualizer. |
| | `miniVisBarWidth` | Integer (px) | `2` | Ketebalan/lebar setiap bilah visualizer. |
| | `miniVisSpacing` | Integer (px) | `2` | Jarak horizontal antar bilah visualizer. |
| | `miniVisHeight` | Integer (px) | `14` | Ketinggian maksimal ayunan bilah visualizer. |
| | `miniVisRounded` | Boolean | `true` | Sudut bilah visualizer membulat (*true*) atau persegi (*false*). |
| **Geometri Notch** | `islandShapeMode` | String | `"notch"` | Pilihan mode bentuk: `"notch"` (*Living Notch*) atau `"island"` (*Floating Capsule*). |
| | `notchStyle` | Integer (0–1) | `0` | Gaya visual notch: `0` (Living Notch menyatu panel) atau `1` (Floating Island mengambang). |
| | `verticalOffset` | Integer (px) | `0` | Margin vertikal dari tepi atas layar (berguna bila panel memiliki jarak/gap). |
| | `horizontalOffset` | Integer (px) | `0` | Offset horizontal ke kiri (-) atau kanan (+) jika posisi fisik notch perlu disesuaikan. |
| | `notchWingRadius` | Integer (px) | `14` | Radius kurva cekung sayap atas (*concave wings*) pada mode Living Notch. |
| | `notchBottomRadius` | Integer (px) | `14` | Radius kelengkungan sudut bawah notch (*bottom corner radius*). |
| **Expanded Card** | `expandedWidth` | Integer (px) | `420` | Lebar seragam kartu expanded saat dibuka. |
| | `expandedHeight` | Integer (px) | `325` | Tinggi seragam kartu expanded saat dibuka. |
| | `mediaBgStyle` / `mediaCardBgMode` | Integer (0–3) | `2` | Mode latar belakang Media Player:<br>• `0`: Pure Dark (Hitam Pekat `#09090b`)<br>• `1`: Warna Album Penuh (Full Tint)<br>• `2`: Gradasi Album (Atas Hitam $\to$ Bawah Album)<br>• `3`: Liquid Glass / Blur Translucent |
| | `expandedBgStyle` | Integer (0–1) | `0` | Gaya latar belakang utama kartu expanded: `0` (Solid Dark) atau `1` (Glassy Frosted Blur). |
| | `lyricsBgMode` | Integer (0–1) | `1` | Latar belakang mode lirik: `0` (Hitam Pekat) atau `1` (Gradasi Rona Album Bawah). |
| | `backgroundColor` | Color | `#0d0f12` | Warna dasar kartu jika tidak memakai rona album. |
| | `backgroundOpacity` | Double (0–1) | `0.92` | Tingkat opasitas latar kartu expanded. |
| | `borderColor` | Color | `#33ffffff`| Warna garis tepi halus (*subtle border highlight*). |
| | `accentColor` | Color | `#3daee9` | Warna aksen utama widget dan pagination dots. |
| | `expandOnHover` | Boolean | `false` | Membuka notch otomatis saat kursor mouse melintas tanpa diklik. |
| | `notificationDuration` | Integer (ms) | `4500` | Durasi tampil pop-up notifikasi sebelum menutup otomatis. |
| **Lirik Dinamis** | `lyricsFontFamily` | String / Text | *(Kosong / Sistem)* | Jenis font untuk lirik berjalan di kapsul notch. |
| | `lyricsFontSize` | Integer (px) | `13` | Ukuran teks lirik berjalan pada kapsul notch. |
| | `lyricsFontBold` | Boolean | `true` | Format huruf tebal (**Bold**) pada lirik berjalan di notch. |
| | `showCompactVisualizer` | Boolean | `false` | Menampilkan visualizer mini di samping teks lirik di kapsul standby. |
| | `autoRetryLyrics` | Boolean | `true` | Otomatis mencoba mengunduh lirik kembali dari LRCLIB saat lagu berganti. |
| **Modular Tabs** | `showMediaTab` | Boolean | `true` | Mengaktifkan/menonaktifkan tab Media Player & Lirik. |
| | `showNotificationTab` | Boolean | `true` | Mengaktifkan/menonaktifkan tab Riwayat Notifikasi. |
| | `showControlTab` | Boolean | `true` | Mengaktifkan/menonaktifkan tab Pusat Kontrol & Monitor Sistem. |
| | `showClipboardTab` | Boolean | `true` | Mengaktifkan/menonaktifkan tab Riwayat Papan Klip Klipper. |

---

## 📦 Persyaratan Sistem & Dependensi (Requirements)

Pastikan sistem Anda memenuhi dependensi berikut sebelum menjalankan widget:

- **Lingkungan Desktop:** KDE Plasma 6.0 atau lebih baru (direkomendasikan sesi **Wayland**, sesi **X11** didukung penuh).
- **Framework & QML Modules:**
  - `qt6-declarative` (QtQuick 6, QtQuick.Layouts, QtQuick.Controls 2)
  - `qml6-module-qtquick-shapes` (untuk rendering kurva sayap cekung `PathCubic`)
  - `kf6-kirigami` / `kirigami`
  - `plasma5support` (untuk modul monitor data sistem)
- **Audio & Media Integration:**
  - PipeWire / PulseAudio via modul native Plasma 6 `org.kde.plasma.private.volume`.
  - Pemutar musik berbasis MPRIS (Spotify, Firefox, Chromium, Cider, Elisa, VLC, MPV).
  - `playerctl` (opsional, untuk kontrol CLI media).
  - `CAVA` (opsional, untuk penangkapan visualizer spektrum audio lanjutan).

---

## 🚀 Panduan Instalasi Manual (Installation Guide)

### Langkah 1: Pasang Dependensi Sesuai Distro Linux

Buka terminal (**Konsole**), lalu jalankan perintah instalasi paket sesuai distribusi yang Anda gunakan:

#### 🔹 Arch Linux / Manjaro / EndeavourOS
```bash
sudo pacman -S --needed git qt6-declarative qt6-5compat kirigami libnotify playerctl cava
```

#### 🔹 Ubuntu / Kubuntu / Debian / KDE neon
```bash
sudo apt update && sudo apt install -y git qml6-module-qtquick qml6-module-qtquick-shapes qml6-module-org-kde-kirigami libnotify-bin playerctl cava
```

#### 🔹 Fedora / Nobara / RHEL
```bash
sudo dnf install -y git qt6-qtdeclarative qt6-qt5compat kf6-kirigami libnotify playerctl cava
```

#### 🔹 openSUSE (Tumbleweed / Leap)
```bash
sudo zypper install -y git qt6-declarative kirigami-imports libnotify playerctl cava
```

---

### Langkah 2: Unduh Repositori ke Direktori Plasmoids

Jalankan perintah clone berikut untuk menempatkan plasmoid ke folder ekstensi KDE Plasma Anda:

```bash
# Buat folder plasmoid jika belum ada
mkdir -p ~/.local/share/plasma/plasmoids

# Clone repositori langsung ke direktori plasmoid
git clone https://github.com/Gatoott/dynamic-island-kde-plasma.git ~/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland
```

*Atau jika Anda mengkloning dengan nama folder repositori:*
```bash
cd ~/.local/share/plasma/plasmoids/Gatoott.dynamic-island-kde-plasma
```

---

### Langkah 3: Bersihkan Cache QML & Muat Ulang Plasma

Bersihkan cache kompilasi QML lama agar perubahan file segera dimuat, lalu restart plasmashell:

```bash
# Bersihkan cache QML & Plasma dan muat ulang layanan plasmashell
rm -rf ~/.cache/qmlcache* ~/.cache/plasma*
systemctl --user restart plasma-plasmashell.service
```

---

### Langkah 4: Tambahkan Widget ke Panel Layar

1. **Klik kanan** pada Panel Atas (*Top Panel*) desktop KDE Plasma Anda.
2. Pilih **"Add Widgets..."** (*Tambahkan Widget...*).
3. Cari **"Plasma Dynamic Island"**.
4. Tarik (*drag and drop*) widget tersebut ke posisi tengah panel atas.
5. Selesai! Dynamic Island sudah aktif dan siap dinikmati. 🎉

---

### Langkah 5 (Opsional): Mengaktifkan Real Audio Visualizer (cava)

Secara default, widget memiliki animasi visualizer bawaan. Untuk membuatnya membaca dan bergerak mengikuti frekuensi audio nyata secara real-time via PipeWire/Pulse:

1. **Pastikan paket `cava` terpasang:**
   ```bash
   # Fedora
   sudo dnf install -y cava
   # Arch Linux
   sudo pacman -S cava
   # Ubuntu / Debian
   sudo apt install -y cava
   ```

2. **Aktifkan background service penyedia spektrum D-Bus:**
   ```bash
   # Jalankan skrip installer otomatis bawaan widget:
   bash ~/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland/contents/code/install-service.sh
   ```
   *Atau pasang manual ke systemd user:*
   ```bash
   mkdir -p ~/.config/systemd/user
   cp ~/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland/contents/code/plasma-visualizer-service.service ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now plasma-visualizer-service.service
   ```

3. **Cara Pengujian:**
   - **Putar lagu / audio** (Spotify, browser, YouTube, dsb): 4 bar visualizer akan naik-turun selaras dengan ketukan dan intensitas suara nyata.
   - **Pause lagu**: Bar otomatis kembali ke posisi minimum dan service otomatis menghentikan proses cava (**0.0% CPU**).
   - **Hentikan service**: `systemctl --user stop plasma-visualizer-service.service` — visualizer otomatis beralih (*graceful fallback*) ke animasi loop bawaan tanpa kendala.

---

## 🔄 Pembaruan (Update) & Penghapusan (Uninstall)

- **Cara Update ke Versi Paling Baru:**
  ```bash
  cd ~/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland
  git pull
  rm -rf ~/.cache/qmlcache* ~/.cache/plasma*
  systemctl --user restart plasma-plasmashell.service
  ```

- **Cara Uninstall (Menghapus Widget Secara Bersih):**
  ```bash
  rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland
  rm -rf ~/.cache/qmlcache* ~/.cache/plasma*
  systemctl --user restart plasma-plasmashell.service
  ```

---

## 🛠️ Troubleshooting

Jika widget tidak muncul atau tampilannya belum terperbarui setelah pembaruan kode, jalankan perintah pembersihan berikut di terminal:

```bash
# Hapus cache QML dan muat ulang plasmashell
rm -rf ~/.cache/qmlcache* ~/.cache/plasma* && systemctl --user restart plasma-plasmashell.service
```

Untuk memantau log kesalahan jika terjadi kendala pada antarmuka:
```bash
journalctl --user -u plasma-plasmashell.service -f
```

---

## 💬 Kritik, Saran, & Kontak

> **Punya ide fitur baru, menemukan kendala (bug), atau ingin berdiskusi?**  
> Kunjungi dan hubungi langsung melalui website: [muhammadarfa.my.id](https://www.muhammadarfa.my.id/).

---

<p align="center">
  Dibuat dengan vibe coding ❤️
</p>
