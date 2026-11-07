#!/usr/bin/env python3
"""
Plasma Dynamic Island Audio Visualizer Service (cava D-Bus Provider)
Runs cava in raw ascii mode with 4 bars, smooths levels, and publishes
real-time audio amplitude to D-Bus at 'org.kde.plasma.dynamicisland.visualizer'
on object path '/Visualizer'.

Uses cava's built-in sleep_timer to suspend CPU usage when audio is silent.
"""

import os
import sys
import time
import shutil
import signal
import subprocess
import threading

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

IFACE = "org.kde.plasma.dynamicisland.visualizer"
PATH = "/Visualizer"
CONFIG_DIR = os.path.expanduser("~/.config/plasma-dynamic-island")
CAVA_CONF = os.path.join(CONFIG_DIR, "cava.conf")

def ensure_cava_config():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    content = """## Dedicated cava config for Plasma Dynamic Island
[general]
framerate = 60
bars = 4
autosens = 1
lower_cutoff_freq = 50
higher_cutoff_freq = 10000
sleep_timer = 3

[input]
sample_rate = 44100
sample_bits = 16
channels = 2
autoconnect = 2
active = 0
remix = 1
virtual = 1

[output]
channels = mono
mono_option = average
reverse = 0
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10

[smoothing]
noise_reduction = 77
monstercat = 0
waves = 0
"""
    with open(CAVA_CONF, "w") as f:
        f.write(content)
    return CAVA_CONF


class VisualizerService(dbus.service.Object):
    def __init__(self, bus):
        bus_name = dbus.service.BusName(IFACE, bus)
        super().__init__(bus_name, PATH)
        self.bus = bus
        self.levels = [0.0, 0.0, 0.0, 0.0]
        self.active = False
        self._lock = threading.Lock()
        self.on_set_playing_cb = None

    @dbus.service.method(IFACE, out_signature="ad")
    def GetLevels(self):
        with self._lock:
            return [dbus.Double(x) for x in self.levels]

    @dbus.service.method(IFACE, out_signature="b")
    def IsActive(self):
        with self._lock:
            return dbus.Boolean(self.active)

    @dbus.service.method(IFACE, in_signature="b", out_signature="b")
    def SetPlaying(self, is_playing):
        if self.on_set_playing_cb:
            self.on_set_playing_cb(bool(is_playing))
        return True

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        with self._lock:
            if prop == "levels":
                return dbus.Array([dbus.Double(x) for x in self.levels], signature="d")
            elif prop == "active":
                return dbus.Boolean(self.active)
        return dbus.String("")

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        with self._lock:
            return dbus.Dictionary({
                dbus.String("levels"): dbus.Array([dbus.Double(x) for x in self.levels], signature="d", variant_level=1),
                dbus.String("active"): dbus.Boolean(self.active, variant_level=1)
            }, signature="sv")

    @dbus.service.signal(IFACE, signature="adb")
    def LevelsChanged(self, levels, active):
        pass

    @dbus.service.signal(dbus.PROPERTIES_IFACE, signature="sa{sv}as")
    def PropertiesChanged(self, interface_name, changed_properties, invalidated_properties):
        pass

    def notify_levels(self, new_levels, is_active):
        with self._lock:
            self.levels = new_levels
            self.active = is_active

        def _emit():
            try:
                # 1. Custom fast direct signal untuk QML DBus.SignalWatcher
                self.LevelsChanged(dbus.Array([dbus.Double(x) for x in new_levels], signature="d"), dbus.Boolean(is_active))

                # 2. Standar D-Bus PropertiesChanged
                changed = dbus.Dictionary({
                    dbus.String("levels"): dbus.Array([dbus.Double(x) for x in new_levels], signature="d", variant_level=1),
                    dbus.String("active"): dbus.Boolean(is_active, variant_level=1)
                }, signature="sv")
                self.PropertiesChanged(IFACE, changed, dbus.Array([], signature="s"))
            except Exception:
                pass

        GLib.idle_add(_emit)


class CavaRunner:
    def __init__(self, service):
        self.service = service
        self.process = None
        self.running = False
        self.thread = None
        self.smoothed = [0.0, 0.0, 0.0, 0.0]
        self._lock = threading.Lock()
        self.silent_frames = 0

    def start(self):
        with self._lock:
            if self.running:
                return
            if not shutil.which("cava"):
                print("[Visualizer] cava tidak ditemukan di sistem, melewati start.", flush=True)
                return
            self.running = True
            self.thread = threading.Thread(target=self._worker, daemon=True)
            self.thread.start()
            print("[Visualizer] Audio capture cava dimulai.", flush=True)

    def stop(self):
        with self._lock:
            if not self.running:
                return
            self.running = False
            if self.process:
                try:
                    self.process.terminate()
                    self.process.wait(timeout=0.4)
                except Exception:
                    try:
                        self.process.kill()
                    except Exception:
                        pass
                self.process = None
            self.smoothed = [0.0, 0.0, 0.0, 0.0]
            self.service.notify_levels([0.0, 0.0, 0.0, 0.0], False)
            print("[Visualizer] Audio capture cava dihentikan.", flush=True)

    def _worker(self):
        while self.running:
            conf = ensure_cava_config()
            try:
                self.process = subprocess.Popen(
                    ["cava", "-p", conf],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL,
                    text=True,
                    bufsize=1
                )
            except Exception as e:
                print("[Visualizer] Gagal menjalankan cava:", e, flush=True)
                self.service.notify_levels([0.0, 0.0, 0.0, 0.0], False)
                time.sleep(2)
                continue

            self.silent_frames = 0
            while self.running and self.process and self.process.poll() is None:
                line = self.process.stdout.readline()
                if not line:
                    break
                line = line.strip()
                if not line or "\x1b" in line:
                    continue
                parts = [p for p in line.split(";") if p]
                if len(parts) >= 4:
                    try:
                        raw_vals = [min(1.0, max(0.0, float(parts[i]) / 100.0)) for i in range(4)]
                        has_sound = any(v > 0.005 for v in raw_vals)

                        for i in range(4):
                            target = raw_vals[i]
                            # Respon cepat saat ada nada (0.75), dan meluruh perlahan (0.40)
                            if target > self.smoothed[i]:
                                self.smoothed[i] = self.smoothed[i] * 0.25 + target * 0.75
                            else:
                                self.smoothed[i] = self.smoothed[i] * 0.60 + target * 0.40
                            self.smoothed[i] = round(self.smoothed[i], 3)

                        if has_sound:
                            self.silent_frames = 0
                            self.service.notify_levels(list(self.smoothed), True)
                        else:
                            self.silent_frames += 1
                            # Setelah ~40 frame sunyi berturut-turut (~0.7 detik pada 60fps), set active = False
                            if self.silent_frames > 40:
                                self.smoothed = [0.0, 0.0, 0.0, 0.0]
                                self.service.notify_levels([0.0, 0.0, 0.0, 0.0], False)
                            else:
                                self.service.notify_levels(list(self.smoothed), True)
                    except ValueError:
                        continue

            if self.process:
                try:
                    self.process.terminate()
                    self.process.wait(timeout=0.2)
                except Exception:
                    pass
                self.process = None

            if self.running:
                time.sleep(1)


def main():
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    service = VisualizerService(bus)
    runner = CavaRunner(service)

    def on_set_playing(is_playing):
        # Callback saat QML memberi sinyal playback
        pass

    service.on_set_playing_cb = on_set_playing

    # Mulai audio capture cava secara konsisten (cava menggunakan sleep_timer=3 untuk hemat daya saat hening)
    runner.start()

    loop = GLib.MainLoop()

    def handle_signal(sig, frame):
        print(f"\n[Visualizer] Menghentikan service (signal {sig})...", flush=True)
        runner.stop()
        loop.quit()

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    print(f"[Visualizer] Service aktif pada D-Bus: {IFACE} di {PATH}", flush=True)
    try:
        loop.run()
    except KeyboardInterrupt:
        runner.stop()

if __name__ == "__main__":
    main()
