#!/usr/bin/env python3
import os
import glob
import json
import time

STATE_FILE = '/tmp/.plasma_di_cpu_state'

def get_cpu():
    cur_total = 0
    cur_idle = 0
    try:
        with open('/proc/stat') as f:
            parts = f.readline().split()[1:]
            cur_idle = int(parts[3])
            cur_total = sum(int(x) for x in parts)
    except Exception:
        return 0

    prev_total, prev_idle = 0, 0
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, 'r') as f:
                prev_total, prev_idle = [int(x) for x in f.read().strip().split()]
        except Exception:
            pass

    try:
        with open(STATE_FILE, 'w') as f:
            f.write(f"{cur_total} {cur_idle}")
    except Exception:
        pass

    diff_total = cur_total - prev_total
    diff_idle = cur_idle - prev_idle
    if diff_total > 0:
        usage = max(0, min(100, round((1.0 - (diff_idle / diff_total)) * 100)))
        return usage
    return 0

def get_ram():
    total, avail = 1, 0
    try:
        with open('/proc/meminfo') as f:
            for line in f:
                if line.startswith('MemTotal:'):
                    total = int(line.split()[1])
                elif line.startswith('MemAvailable:'):
                    avail = int(line.split()[1])
    except Exception:
        pass
    used = max(0, total - avail)
    pct = round((used / total) * 100) if total > 0 else 0
    used_gb = round(used / (1024 * 1024), 1)
    total_gb = round(total / (1024 * 1024), 1)
    return pct, f"{used_gb}G", f"{total_gb}G"

def get_disk():
    try:
        st = os.statvfs('/')
        total = st.f_blocks * st.f_frsize
        avail = st.f_bavail * st.f_frsize
        used = total - avail
        pct = round((used / total) * 100) if total > 0 else 0
        used_gb = round(used / (1024**3), 1)
        total_gb = round(total / (1024**3), 1)
        return pct, f"{used_gb}G", f"{total_gb}G"
    except Exception:
        return 0, "0G", "0G"

def get_temp():
    max_temp = 0
    for p in glob.glob('/sys/class/hwmon/hwmon*/temp*_input'):
        try:
            with open(p) as f:
                v = int(f.read().strip()) / 1000.0
                if 20 <= v <= 120 and v > max_temp:
                    max_temp = v
        except Exception:
            pass
    if max_temp == 0:
        for p in glob.glob('/sys/class/thermal/thermal_zone*/temp'):
            try:
                with open(p) as f:
                    v = int(f.read().strip()) / 1000.0
                    if 20 <= v <= 120 and v > max_temp:
                        max_temp = v
            except Exception:
                pass
    return round(max_temp)

def get_battery():
    pct = 100
    charging = False
    plugged = False
    try:
        for p in glob.glob('/sys/class/power_supply/AC*/online'):
            try:
                with open(p) as f:
                    if f.read().strip() == '1':
                        plugged = True
            except Exception:
                pass
        for p in glob.glob('/sys/class/power_supply/BAT*/capacity'):
            try:
                with open(p) as f:
                    pct = int(f.read().strip())
                    break
            except Exception:
                pass
        for p in glob.glob('/sys/class/power_supply/BAT*/status'):
            try:
                with open(p) as f:
                    st = f.read().strip().lower()
                    if 'charging' in st and 'not' not in st:
                        charging = True
                    elif plugged and 'full' in st:
                        charging = True
                    break
            except Exception:
                pass
    except Exception:
        pass
    return pct, charging, plugged

if __name__ == '__main__':
    cpu_pct = get_cpu()
    ram_pct, ram_used, ram_total = get_ram()
    disk_pct, disk_used, disk_total = get_disk()
    temp_c = get_temp()
    bat_pct, bat_charging, bat_plugged = get_battery()

    data = {
        'cpu': cpu_pct,
        'ram': ram_pct,
        'ram_text': f"{ram_used} / {ram_total}",
        'disk': disk_pct,
        'disk_text': f"{disk_used} / {disk_total}",
        'temp': temp_c,
        'battery_pct': bat_pct,
        'battery_charging': bat_charging,
        'power_plugged': bat_plugged
    }
    print(json.dumps(data))
