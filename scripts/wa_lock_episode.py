#!/usr/bin/env python3
"""Exercise a WA lock-screen episode with emulator-only service provisioning."""
import json
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

PACKAGE = 'com.example.keyboardtest.walab'
SERVICE = PACKAGE + '/tk.zwander.lockscreenwidgets.services.Accessibility'
EVIDENCE = Path('emulator-evidence')


def matching_overlay(dump):
    blocks = re.split(r'(?m)(?=^\s*Window #\d+\s)', dump)
    return any(PACKAGE in block and re.search(r'\bty=(?:ACCESSIBILITY_OVERLAY|2032)\b', block)
               for block in blocks)


def service_connected(dump):
    enabled = re.search(r'Enabled services:[^\n]*' + re.escape(SERVICE), dump, re.I)
    bound = re.search(r'Bound services:[^\n]*Service\[label=keyboardtest · WA,', dump, re.I)
    return enabled is not None and bound is not None


def lock_episode(adb, wait_node, tap, widget_id):
    tap(wait_node('Rögzítés indítása'))
    # The service grant is injected only in the disposable CI emulator.
    adb('shell', 'settings', 'put', 'secure', 'enabled_accessibility_services', SERVICE)
    adb('shell', 'settings', 'put', 'secure', 'accessibility_enabled', '1')
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        state = adb('shell', 'dumpsys', 'accessibility')
        (EVIDENCE / 'accessibility.txt').write_text(state)
        if service_connected(state):
            break
        time.sleep(0.5)
    else:
        raise AssertionError('Injected emulator accessibility service did not connect')

    failure = None
    try:
        adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
        (EVIDENCE / 'before-lock-activities.txt').write_text(adb('shell', 'dumpsys', 'activity', 'activities'))
        adb('shell', 'input', 'keyevent', 'KEYCODE_SLEEP')
        adb('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            windows = adb('shell', 'dumpsys', 'window', 'windows')
            (EVIDENCE / 'lock-windows.txt').write_text(windows)
            if matching_overlay(windows):
                break
            time.sleep(0.5)
        else:
            raise AssertionError('WA accessibility overlay was not attached on emulator keyguard')
        screenshot = subprocess.run(['adb', 'exec-out', 'screencap', '-p'], check=True, capture_output=True, timeout=20).stdout
        (EVIDENCE / 'live-lockscreen.png').write_bytes(screenshot)
        size = adb('shell', 'wm', 'size')
        match = re.search(r'(\d+)x(\d+)', size)
        if not match:
            raise AssertionError('Cannot read emulator screen size')
        width, height = map(int, match.groups())
        x, y = width // 2, height // 2
        adb('shell', 'input', 'swipe', str(x), str(y), str(x + 25), str(y), '2500')
    except Exception as error:
        failure = error
    finally:
        # The emulator has no credential; this returns to the unlocked setup screen.
        adb('shell', 'input', 'swipe', '160', '600', '160', '100', '300', check=False)
        adb('shell', 'input', 'keyevent', 'KEYCODE_MENU', check=False)
        adb('shell', 'am', 'start', '-W', '-n', PACKAGE + '/tk.zwander.lockscreenwidgets.lab.KeyboardLabActivity', check=False)
        tap(wait_node('Zárképernyő teszt'))
        tap(wait_node('Leállítás és másolás'))
        prefs = adb('shell', 'run-as', PACKAGE, 'cat', 'shared_prefs/wa_lab_diagnostics.xml')
        (EVIDENCE / 'diagnostics.xml').write_text(prefs)
    if failure is not None:
        raise failure
    root = ET.fromstring(prefs)
    body = next((item.text for item in root if item.get('name') == 'body'), None)
    if body is None:
        raise AssertionError('Frozen diagnostic body missing')
    report = json.loads(body)
    rows = report['records']
    events = {row['event'] for row in rows if row.get('widgetId') == int(widget_id)}
    required = {'HOST_VIEW', 'FIRST_DRAW', 'WINDOW_ATTACHED', 'WINDOW_REMOVED', 'DRAG_START', 'DRAG_DROP'}
    if not required.issubset(events):
        raise AssertionError('Missing live WA events: ' + ', '.join(sorted(required - events)))
    if not any(row['event'] == 'VISIBILITY' and row['flags'] & 2 and row['flags'] & (1 << 20) for row in rows):
        raise AssertionError('No allowed keyguard visibility decision was recorded')
    (EVIDENCE / 'lock-episode.txt').write_text('Emulator-only injected accessibility grant; real WA overlay, host draw and single-pointer drag recorded.\n')
