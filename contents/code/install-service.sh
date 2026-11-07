#!/bin/bash
# Installer script for Plasma Dynamic Island Audio Visualizer Service
set -e

echo "=== Memasang Plasma Dynamic Island Audio Visualizer Service ==="

# 1. Cek cava
if ! command -v cava &> /dev/null; then
    echo "[!] cava belum terpasang. Menginstall cava via dnf..."
    sudo dnf install -y cava
else
    echo "[✓] cava sudah terpasang."
fi

# 2. Siapkan direktori systemd user
mkdir -p ~/.config/systemd/user

# 3. Salin service unit
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/plasma-visualizer-service.service" ~/.config/systemd/user/plasma-visualizer-service.service

# 4. Reload & Enable
systemctl --user daemon-reload
systemctl --user enable --now plasma-visualizer-service.service

echo "[✓] Service berhasil dipasang dan dijalankan!"
echo "Status service:"
systemctl --user status plasma-visualizer-service.service --no-pager

