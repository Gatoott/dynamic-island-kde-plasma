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
import json
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

TIMER_IFACE = "org.kde.plasma.dynamicisland.timer"
TIMER_PATH = "/Timer"
TIMER_STATE_FILE = os.path.join(CONFIG_DIR, "timer_state.json")

EYE_IFACE = "org.kde.plasma.dynamicisland.eyecare"
EYE_PATH = "/EyeCare"
EYE_STATE_FILE = os.path.join(CONFIG_DIR, "eyecare_state.json")

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

    @dbus.service.signal(IFACE, signature="b")
    def SetExpanded(self, expanded):
        pass

    @dbus.service.method(IFACE, in_signature="b", out_signature="b")
    def RequestExpanded(self, expanded):
        self.SetExpanded(bool(expanded))
        return True

    @dbus.service.signal(IFACE, signature="b")
    def SetLyrics(self, show):
        pass

    @dbus.service.method(IFACE, in_signature="b", out_signature="b")
    def RequestLyrics(self, show):
        self.SetLyrics(bool(show))
        return True

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


class TimerService(dbus.service.Object):
    def __init__(self, bus):
        bus_name = dbus.service.BusName(TIMER_IFACE, bus)
        super().__init__(bus_name, TIMER_PATH)
        self.bus = bus
        self._lock = threading.Lock()
        self.state = "idle" # idle, running, paused, finished
        self.total_duration = 0
        self.remaining_seconds = 0
        self.target_timestamp = 0.0
        self.sound_enabled = True
        self._timer_source_id = None
        self._load_state()

    def _load_state(self):
        if not os.path.exists(TIMER_STATE_FILE):
            return
        try:
            with open(TIMER_STATE_FILE, "r") as f:
                data = json.load(f)
            saved_state = data.get("state", "idle")
            self.total_duration = int(data.get("total_duration", 0))
            self.sound_enabled = bool(data.get("sound_enabled", True))
            target_ts = float(data.get("target_timestamp", 0.0))
            rem_sec = int(data.get("remaining_seconds", 0))

            now = time.time()
            if saved_state == "running" and target_ts > 0:
                if target_ts > now:
                    self.target_timestamp = target_ts
                    self.remaining_seconds = max(0, int(round(target_ts - now)))
                    self.state = "running"
                    self._start_timer_loop()
                else:
                    self.target_timestamp = 0.0
                    self.remaining_seconds = 0
                    self.state = "finished"
            elif saved_state == "paused":
                self.state = "paused"
                self.remaining_seconds = rem_sec
                self.target_timestamp = 0.0
            elif saved_state == "finished":
                self.state = "finished"
                self.remaining_seconds = 0
            else:
                self.state = "idle"
                self.remaining_seconds = 0
        except Exception as e:
            print("[Timer] Gagal memuat state:", e, flush=True)

    def _save_state(self):
        try:
            os.makedirs(CONFIG_DIR, exist_ok=True)
            data = {
                "state": self.state,
                "total_duration": self.total_duration,
                "remaining_seconds": self.remaining_seconds,
                "target_timestamp": self.target_timestamp,
                "sound_enabled": self.sound_enabled
            }
            tmp = TIMER_STATE_FILE + ".tmp"
            with open(tmp, "w") as f:
                json.dump(data, f)
            os.replace(tmp, TIMER_STATE_FILE)
        except Exception as e:
            print("[Timer] Gagal menyimpan state:", e, flush=True)

    def _start_timer_loop(self):
        if self._timer_source_id is not None:
            GLib.source_remove(self._timer_source_id)
        self._timer_source_id = GLib.timeout_add(1000, self._on_tick)

    def _stop_timer_loop(self):
        if self._timer_source_id is not None:
            GLib.source_remove(self._timer_source_id)
            self._timer_source_id = None

    def _on_tick(self):
        with self._lock:
            if self.state != "running":
                self._timer_source_id = None
                return False

            now = time.time()
            remaining = int(round(self.target_timestamp - now))
            if remaining <= 0:
                self.remaining_seconds = 0
                self.state = "finished"
                self._stop_timer_loop()
                self._save_state()
                self._emit_updated()
                self._trigger_finished()
                return False
            else:
                self.remaining_seconds = remaining
                self._emit_updated()
                return True

    def _trigger_finished(self):
        def _fire():
            try:
                self.TimerFinished(dbus.Int32(self.total_duration))
            except Exception:
                pass

            # Mainkan suara alarm sistem jika diaktifkan di konfigurasi
            if self.sound_enabled:
                sound_file = "/usr/share/sounds/ocean/stereo/alarm-clock-elapsed.oga"
                if not os.path.exists(sound_file):
                    sound_file = "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
                if shutil.which("pw-play") and os.path.exists(sound_file):
                    try:
                        subprocess.Popen(["pw-play", sound_file], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    except Exception:
                        pass
                elif shutil.which("canberra-gtk-play"):
                    try:
                        subprocess.Popen(["canberra-gtk-play", "-i", "alarm-clock-elapsed"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    except Exception:
                        pass

            # Kirim notifikasi desktop (Satu notifikasi tunggal untuk seluruh monitor)
            if shutil.which("notify-send"):
                try:
                    mins = self.total_duration // 60
                    secs = self.total_duration % 60
                    dur_str = f"{mins} menit" if mins > 0 and secs == 0 else (f"{self.total_duration} detik" if mins == 0 else f"{mins}m {secs}s")
                    subprocess.Popen([
                        "notify-send",
                        "-a", "Dynamic Island",
                        "-i", "chronometer",
                        "-u", "critical",
                        "Timer Selesai!",
                        f"Waktu {dur_str} telah habis."
                    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                except Exception:
                    pass

        GLib.idle_add(_fire)

    def _emit_updated(self):
        def _fire():
            try:
                self.TimerUpdated(
                    dbus.String(self.state),
                    dbus.Int32(self.remaining_seconds),
                    dbus.Int32(self.total_duration),
                    dbus.Double(self.target_timestamp)
                )

                changed = dbus.Dictionary({
                    dbus.String("state"): dbus.String(self.state, variant_level=1),
                    dbus.String("remainingSeconds"): dbus.Int32(self.remaining_seconds, variant_level=1),
                    dbus.String("totalDuration"): dbus.Int32(self.total_duration, variant_level=1),
                    dbus.String("targetTimestamp"): dbus.Double(self.target_timestamp, variant_level=1),
                    dbus.String("soundEnabled"): dbus.Boolean(self.sound_enabled, variant_level=1)
                }, signature="sv")
                self.PropertiesChanged(TIMER_IFACE, changed, dbus.Array([], signature="s"))
            except Exception:
                pass
        GLib.idle_add(_fire)

    # --- D-Bus Methods ---
    @dbus.service.method(TIMER_IFACE, in_signature="i", out_signature="b")
    def Start(self, duration_seconds):
        dur = int(duration_seconds)
        if dur <= 0:
            return False
        with self._lock:
            now = time.time()
            self.total_duration = dur
            self.remaining_seconds = dur
            self.target_timestamp = now + dur
            self.state = "running"
            self._save_state()
            self._start_timer_loop()
        self._emit_updated()
        print(f"[Timer] Dimulai: {dur} detik (target: {self.target_timestamp})", flush=True)
        return True

    @dbus.service.method(TIMER_IFACE, out_signature="b")
    def Pause(self):
        with self._lock:
            if self.state == "running":
                now = time.time()
                self.remaining_seconds = max(1, int(round(self.target_timestamp - now)))
                self.target_timestamp = 0.0
                self.state = "paused"
                self._stop_timer_loop()
                self._save_state()
        self._emit_updated()
        print(f"[Timer] Dijeda: sisa {self.remaining_seconds} detik", flush=True)
        return True

    @dbus.service.method(TIMER_IFACE, out_signature="b")
    def Resume(self):
        with self._lock:
            if self.state == "paused" and self.remaining_seconds > 0:
                now = time.time()
                self.target_timestamp = now + self.remaining_seconds
                self.state = "running"
                self._save_state()
                self._start_timer_loop()
        self._emit_updated()
        print(f"[Timer] Dilanjutkan: sisa {self.remaining_seconds} detik", flush=True)
        return True

    @dbus.service.method(TIMER_IFACE, out_signature="b")
    def Reset(self):
        with self._lock:
            self.state = "idle"
            self.remaining_seconds = 0
            self.total_duration = 0
            self.target_timestamp = 0.0
            self._stop_timer_loop()
            self._save_state()
        self._emit_updated()
        print("[Timer] Direset ke idle", flush=True)
        return True

    @dbus.service.method(TIMER_IFACE, out_signature="b")
    def DismissFinished(self):
        with self._lock:
            if self.state == "finished":
                self.state = "idle"
                self.remaining_seconds = 0
                self.total_duration = 0
                self.target_timestamp = 0.0
                self._save_state()
        self._emit_updated()
        return True

    @dbus.service.method(TIMER_IFACE, in_signature="b", out_signature="b")
    def SetSoundEnabled(self, enabled):
        with self._lock:
            self.sound_enabled = bool(enabled)
            self._save_state()
        self._emit_updated()
        return True

    # --- Properties Interface ---
    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        with self._lock:
            if prop == "state":
                return dbus.String(self.state)
            elif prop == "remainingSeconds":
                return dbus.Int32(self.remaining_seconds)
            elif prop == "totalDuration":
                return dbus.Int32(self.total_duration)
            elif prop == "targetTimestamp":
                return dbus.Double(self.target_timestamp)
            elif prop == "soundEnabled":
                return dbus.Boolean(self.sound_enabled)
        return dbus.String("")

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        with self._lock:
            return dbus.Dictionary({
                dbus.String("state"): dbus.String(self.state, variant_level=1),
                dbus.String("remainingSeconds"): dbus.Int32(self.remaining_seconds, variant_level=1),
                dbus.String("totalDuration"): dbus.Int32(self.total_duration, variant_level=1),
                dbus.String("targetTimestamp"): dbus.Double(self.target_timestamp, variant_level=1),
                dbus.String("soundEnabled"): dbus.Boolean(self.sound_enabled, variant_level=1)
            }, signature="sv")

    # --- Signals ---
    @dbus.service.signal(TIMER_IFACE, signature="siid")
    def TimerUpdated(self, state, remaining_seconds, total_duration, target_timestamp):
        pass

    @dbus.service.signal(TIMER_IFACE, signature="i")
    def TimerFinished(self, total_duration):
        pass

    @dbus.service.signal(dbus.PROPERTIES_IFACE, signature="sa{sv}as")
    def PropertiesChanged(self, interface_name, changed_properties, invalidated_properties):
        pass


class EyeCareService(dbus.service.Object):
    def __init__(self, session_bus, system_bus=None):
        bus_name = dbus.service.BusName(EYE_IFACE, session_bus)
        super().__init__(bus_name, EYE_PATH)
        self.session_bus = session_bus
        self.system_bus = system_bus
        self._lock = threading.Lock()

        self.state = "idle" # idle, running, break
        self.interval_minutes = 20
        self.remaining_seconds = 1200
        self.break_duration = 20 # aturan 20-20-20 (20 detik)
        self.time_since_last_break = 0 # akumulasi detik layar aktif sejak istirahat terakhir
        self.last_break_time = time.time()
        self.is_overdue = False
        self.is_screen_locked = False
        self.is_sleeping = False
        self.is_paused = False
        self._timer_source_id = None
        self._save_counter = 0

        self._setup_lock_and_sleep_listeners()
        self._load_state()

    def _setup_lock_and_sleep_listeners(self):
        # 1. ScreenSaver lock screen signal
        try:
            self.session_bus.add_signal_receiver(
                self._on_screensaver_active_changed,
                signal_name="ActiveChanged",
                dbus_interface="org.freedesktop.ScreenSaver"
            )
            try:
                ss_obj = self.session_bus.get_object("org.freedesktop.ScreenSaver", "/ScreenSaver")
                ss_iface = dbus.Interface(ss_obj, "org.freedesktop.ScreenSaver")
                self.is_screen_locked = bool(ss_iface.GetActive())
            except Exception:
                self.is_screen_locked = False
        except Exception as e:
            print("[EyeCare] Gagal pasang listener ScreenSaver:", e, flush=True)

        # 2. Login1 sleep/suspend signal
        if self.system_bus:
            try:
                self.system_bus.add_signal_receiver(
                    self._on_prepare_for_sleep,
                    signal_name="PrepareForSleep",
                    dbus_interface="org.freedesktop.login1.Manager"
                )
            except Exception as e:
                print("[EyeCare] Gagal pasang listener login1 PrepareForSleep:", e, flush=True)

    def _on_screensaver_active_changed(self, active):
        with self._lock:
            self.is_screen_locked = bool(active)
            self._update_paused_state()
            print(f"[EyeCare] Layar terkunci: {self.is_screen_locked}", flush=True)
        self._emit_updated()

    def _on_prepare_for_sleep(self, going_to_sleep):
        with self._lock:
            self.is_sleeping = bool(going_to_sleep)
            self._update_paused_state()
            print(f"[EyeCare] Sleep/Suspend state: {self.is_sleeping}", flush=True)
        self._emit_updated()

    def _update_paused_state(self):
        self.is_paused = self.is_screen_locked or self.is_sleeping

    def _load_state(self):
        if not os.path.exists(EYE_STATE_FILE):
            return
        try:
            with open(EYE_STATE_FILE, "r") as f:
                data = json.load(f)
            self.interval_minutes = int(data.get("interval_minutes", 20))
            self.state = data.get("state", "idle")
            self.remaining_seconds = int(data.get("remaining_seconds", self.interval_minutes * 60))
            self.time_since_last_break = int(data.get("time_since_last_break", 0))
            self.last_break_time = float(data.get("last_break_time", time.time()))
            self.is_overdue = (self.time_since_last_break > (self.interval_minutes * 60))

            if self.state in ("running", "break"):
                self._start_timer_loop()
        except Exception as e:
            print("[EyeCare] Gagal memuat state:", e, flush=True)

    def _save_state(self):
        try:
            os.makedirs(CONFIG_DIR, exist_ok=True)
            data = {
                "state": self.state,
                "interval_minutes": self.interval_minutes,
                "remaining_seconds": self.remaining_seconds,
                "time_since_last_break": self.time_since_last_break,
                "last_break_time": self.last_break_time
            }
            tmp = EYE_STATE_FILE + ".tmp"
            with open(tmp, "w") as f:
                json.dump(data, f)
            os.replace(tmp, EYE_STATE_FILE)
        except Exception as e:
            print("[EyeCare] Gagal menyimpan state:", e, flush=True)

    def _start_timer_loop(self):
        if self._timer_source_id is not None:
            GLib.source_remove(self._timer_source_id)
        self._timer_source_id = GLib.timeout_add(1000, self._on_tick)

    def _stop_timer_loop(self):
        if self._timer_source_id is not None:
            GLib.source_remove(self._timer_source_id)
            self._timer_source_id = None

    def _on_tick(self):
        with self._lock:
            if self.state not in ("running", "break"):
                self._timer_source_id = None
                return False

            # Jika layar terkunci atau laptop sleep: JEDA WAKTU LAYAR!
            if self.is_screen_locked or self.is_sleeping:
                if not self.is_paused:
                    self.is_paused = True
                    self._emit_updated()
                return True

            if self.is_paused:
                self.is_paused = False

            if self.state == "running":
                self.time_since_last_break += 1
                self.remaining_seconds -= 1
                self.is_overdue = (self.time_since_last_break > (self.interval_minutes * 60))

                if self.remaining_seconds <= 0:
                    # Masuk waktu istirahat 20 detik!
                    self.state = "break"
                    self.remaining_seconds = self.break_duration
                    self._trigger_break_notification()

            elif self.state == "break":
                self.remaining_seconds -= 1
                if self.remaining_seconds <= 0:
                    # Istirahat 20 detik selesai! Mulai siklus baru otomatis
                    self._trigger_break_finished()
                    self.state = "running"
                    self.remaining_seconds = self.interval_minutes * 60
                    self.time_since_last_break = 0
                    self.last_break_time = time.time()
                    self.is_overdue = False

            self._save_counter += 1
            if self._save_counter >= 5:
                self._save_counter = 0
                self._save_state()

        self._emit_updated()
        return True

    def _trigger_break_notification(self):
        def _fire():
            try:
                self.BreakStarted(dbus.Int32(self.break_duration))
            except Exception:
                pass

            sound_file = "/usr/share/sounds/ocean/stereo/bell.oga"
            if not os.path.exists(sound_file):
                sound_file = "/usr/share/sounds/freedesktop/stereo/bell.oga"
            if shutil.which("pw-play") and os.path.exists(sound_file):
                try:
                    subprocess.Popen(["pw-play", sound_file], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                except Exception:
                    pass
            elif shutil.which("canberra-gtk-play"):
                try:
                    subprocess.Popen(["canberra-gtk-play", "-i", "bell"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                except Exception:
                    pass

            if shutil.which("notify-send"):
                try:
                    subprocess.Popen([
                        "notify-send",
                        "-a", "Dynamic Island",
                        "-i", "view-visible",
                        "-u", "normal",
                        "Waktunya Istirahat Mata!",
                        "Istirahatkan matamu, lihat jauh selama 20 detik (Aturan 20-20-20)."
                    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                except Exception:
                    pass

        GLib.idle_add(_fire)

    def _trigger_break_finished(self):
        def _fire():
            try:
                self.BreakFinished()
            except Exception:
                pass

            sound_file = "/usr/share/sounds/ocean/stereo/complete-media-burn.oga"
            if not os.path.exists(sound_file):
                sound_file = "/usr/share/sounds/freedesktop/stereo/complete.oga"
            if shutil.which("pw-play") and os.path.exists(sound_file):
                try:
                    subprocess.Popen(["pw-play", sound_file], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                except Exception:
                    pass
            elif shutil.which("canberra-gtk-play"):
                try:
                    subprocess.Popen(["canberra-gtk-play", "-i", "complete"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                except Exception:
                    pass

        GLib.idle_add(_fire)

    def _emit_updated(self):
        def _fire():
            try:
                self.EyeUpdated(
                    dbus.String(self.state),
                    dbus.Int32(self.remaining_seconds),
                    dbus.Int32(self.time_since_last_break),
                    dbus.Boolean(self.is_overdue),
                    dbus.Boolean(self.is_paused)
                )

                changed = dbus.Dictionary({
                    dbus.String("state"): dbus.String(self.state, variant_level=1),
                    dbus.String("intervalMinutes"): dbus.Int32(self.interval_minutes, variant_level=1),
                    dbus.String("remainingSeconds"): dbus.Int32(self.remaining_seconds, variant_level=1),
                    dbus.String("breakDuration"): dbus.Int32(self.break_duration, variant_level=1),
                    dbus.String("timeSinceLastBreak"): dbus.Int32(self.time_since_last_break, variant_level=1),
                    dbus.String("isOverdue"): dbus.Boolean(self.is_overdue, variant_level=1),
                    dbus.String("isPaused"): dbus.Boolean(self.is_paused, variant_level=1)
                }, signature="sv")
                self.PropertiesChanged(EYE_IFACE, changed, dbus.Array([], signature="s"))
            except Exception:
                pass
        GLib.idle_add(_fire)

    # --- D-Bus Methods ---
    @dbus.service.method(EYE_IFACE, in_signature="i", out_signature="b")
    def Start(self, interval_minutes):
        mins = int(interval_minutes)
        if mins <= 0:
            mins = self.interval_minutes
        with self._lock:
            self.interval_minutes = mins
            self.state = "running"
            self.remaining_seconds = mins * 60
            self._save_state()
            self._start_timer_loop()
        self._emit_updated()
        print(f"[EyeCare] Dimulai dengan interval: {mins} menit", flush=True)
        return True

    @dbus.service.method(EYE_IFACE, out_signature="b")
    def Stop(self):
        with self._lock:
            self.state = "idle"
            self.remaining_seconds = self.interval_minutes * 60
            self._stop_timer_loop()
            self._save_state()
        self._emit_updated()
        print("[EyeCare] Dihentikan", flush=True)
        return True

    @dbus.service.method(EYE_IFACE, in_signature="i", out_signature="b")
    def Snooze(self, snooze_minutes):
        mins = int(snooze_minutes) if snooze_minutes > 0 else 5
        with self._lock:
            self.state = "running"
            self.remaining_seconds = mins * 60
            self.is_overdue = (self.time_since_last_break > (self.interval_minutes * 60))
            self._save_state()
            self._start_timer_loop()
        self._emit_updated()
        print(f"[EyeCare] Ditunda {mins} menit (total aktif: {self.time_since_last_break} detik)", flush=True)
        return True

    @dbus.service.method(EYE_IFACE, out_signature="b")
    def SkipBreak(self):
        with self._lock:
            self.state = "running"
            self.remaining_seconds = self.interval_minutes * 60
            self.time_since_last_break = 0
            self.last_break_time = time.time()
            self.is_overdue = False
            self._save_state()
            self._start_timer_loop()
        self._emit_updated()
        print("[EyeCare] Istirahat dilewati, siklus baru dimulai", flush=True)
        return True

    @dbus.service.method(EYE_IFACE, out_signature="b")
    def TriggerBreak(self):
        with self._lock:
            self.state = "break"
            self.remaining_seconds = self.break_duration
            self._save_state()
            self._start_timer_loop()
            self._trigger_break_notification()
        self._emit_updated()
        print(f"[EyeCare] Sesi rehat 20 detik dipicu secara manual", flush=True)
        return True

    @dbus.service.method(EYE_IFACE, in_signature="i", out_signature="b")
    def SetInterval(self, minutes):
        mins = int(minutes)
        if mins <= 0:
            return False
        with self._lock:
            self.interval_minutes = mins
            if self.state == "idle":
                self.remaining_seconds = mins * 60
            self._save_state()
        self._emit_updated()
        return True

    # --- Properties Interface ---
    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        with self._lock:
            if prop == "state": return dbus.String(self.state)
            elif prop == "intervalMinutes": return dbus.Int32(self.interval_minutes)
            elif prop == "remainingSeconds": return dbus.Int32(self.remaining_seconds)
            elif prop == "breakDuration": return dbus.Int32(self.break_duration)
            elif prop == "timeSinceLastBreak": return dbus.Int32(self.time_since_last_break)
            elif prop == "isOverdue": return dbus.Boolean(self.is_overdue)
            elif prop == "isPaused": return dbus.Boolean(self.is_paused)
        return dbus.String("")

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        with self._lock:
            return dbus.Dictionary({
                dbus.String("state"): dbus.String(self.state, variant_level=1),
                dbus.String("intervalMinutes"): dbus.Int32(self.interval_minutes, variant_level=1),
                dbus.String("remainingSeconds"): dbus.Int32(self.remaining_seconds, variant_level=1),
                dbus.String("breakDuration"): dbus.Int32(self.break_duration, variant_level=1),
                dbus.String("timeSinceLastBreak"): dbus.Int32(self.time_since_last_break, variant_level=1),
                dbus.String("isOverdue"): dbus.Boolean(self.is_overdue, variant_level=1),
                dbus.String("isPaused"): dbus.Boolean(self.is_paused, variant_level=1)
            }, signature="sv")

    # --- Signals ---
    @dbus.service.signal(EYE_IFACE, signature="siibb")
    def EyeUpdated(self, state, remaining_seconds, time_since_last_break, is_overdue, is_paused):
        pass

    @dbus.service.signal(EYE_IFACE, signature="i")
    def BreakStarted(self, break_duration):
        pass

    @dbus.service.signal(EYE_IFACE)
    def BreakFinished(self):
        pass

    @dbus.service.signal(dbus.PROPERTIES_IFACE, signature="sa{sv}as")
    def PropertiesChanged(self, interface_name, changed_properties, invalidated_properties):
        pass


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
                            # Decay perlahan selama 40 frame (~0.7s pada 60fps)
                            if self.silent_frames <= 40:
                                self.service.notify_levels(list(self.smoothed), True)
                            elif self.service.active:
                                # Kirim status hening tepat sekali, lalu berhenti broadcast sinyal
                                self.smoothed = [0.0, 0.0, 0.0, 0.0]
                                self.service.notify_levels([0.0, 0.0, 0.0, 0.0], False)
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
    sys_bus = None
    try:
        sys_bus = dbus.SystemBus()
    except Exception as e:
        print("[EyeCare] System bus tidak dapat diakses:", e, flush=True)

    service = VisualizerService(bus)
    timer_service = TimerService(bus)
    eye_service = EyeCareService(bus, sys_bus)
    runner = CavaRunner(service)

    def on_set_playing(is_playing):
        # Callback saat QML memberi sinyal playback
        pass

    service.on_set_playing_cb = on_set_playing

    # Mulai audio capture cava secara konsisten (cava menggunakan sleep_timer=3 untuk hemat daya saat hening)
    runner.start()

    loop = GLib.MainLoop()

    def handle_signal(sig, frame):
        print(f"\n[DynamicIsland] Menghentikan service (signal {sig})...", flush=True)
        runner.stop()
        timer_service._stop_timer_loop()
        eye_service._stop_timer_loop()
        loop.quit()

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    print(f"[Visualizer] Service aktif pada D-Bus: {IFACE} di {PATH}", flush=True)
    print(f"[Timer] Service aktif pada D-Bus: {TIMER_IFACE} di {TIMER_PATH}", flush=True)
    print(f"[EyeCare] Service aktif pada D-Bus: {EYE_IFACE} di {EYE_PATH}", flush=True)
    try:
        loop.run()
    except KeyboardInterrupt:
        runner.stop()

if __name__ == "__main__":
    main()
