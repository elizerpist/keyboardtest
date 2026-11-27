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
               and 'mHasSurface=true' in block and 'mDrawState=HAS_DRAWN' in block
               and 'isVisible=true' in block for block in blocks)


def screen_asleep(dump):
    return (re.search(r'mWakefulness=(?:Asleep|Dozing)\b', dump) is not None
            and 'mWakefulnessChanging=false' in dump)


def keyguard_shown(dump):
    return re.search(r'KeyguardServiceDelegate\s+showing=true\b', dump) is not None


def service_connected(dump):
    enabled = re.search(r'Enabled services:[^\n]*' + re.escape(SERVICE), dump, re.I)
    bound = re.search(r'Bound services:[^\n]*Service\[label=keyboardtest · WA,', dump, re.I)
    return enabled is not None and bound is not None


def wake_to_overlay(adb, prefix):
    adb('shell', 'input', 'keyevent', 'KEYCODE_SLEEP')
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        power = adb('shell', 'dumpsys', 'power')
        (EVIDENCE / f'{prefix}-power-before-wake.txt').write_text(power)
        if screen_asleep(power):
            break
        time.sleep(0.5)
    else:
        raise AssertionError('Emulator did not finish going to sleep')
    (EVIDENCE / f'{prefix}-sleep-policy.txt').write_text(adb('shell', 'dumpsys', 'window', 'policy'))
    adb('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        policy = adb('shell', 'dumpsys', 'window', 'policy')
        (EVIDENCE / f'{prefix}-keyguard-policy.txt').write_text(policy)
        if keyguard_shown(policy):
            break
        time.sleep(0.5)
    else:
        raise AssertionError('Emulator keyguard did not become visible after wake')
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        windows = adb('shell', 'dumpsys', 'window', 'windows')
        (EVIDENCE / f'{prefix}-lock-windows.txt').write_text(windows)
        (EVIDENCE / f'{prefix}-keyguard-policy.txt').write_text(adb('shell', 'dumpsys', 'window', 'policy'))
        if matching_overlay(windows):
            break
        time.sleep(0.5)
    else:
        raise AssertionError('WA accessibility overlay was not attached on emulator keyguard')


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
        adb('shell', 'locksettings', 'set-disabled', 'false')
        (EVIDENCE / 'locksettings.txt').write_text(adb('shell', 'locksettings', 'get-disabled'))
        adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
        (EVIDENCE / 'before-lock-activities.txt').write_text(adb('shell', 'dumpsys', 'activity', 'activities'))
        wake_to_overlay(adb, 'first')
        screenshot = subprocess.run(['adb', 'exec-out', 'screencap', '-p'], check=True, capture_output=True, timeout=20).stdout
        (EVIDENCE / 'live-lockscreen.png').write_bytes(screenshot)
        size = adb('shell', 'wm', 'size')
        match = re.search(r'(\d+)x(\d+)', size)
        if not match:
            raise AssertionError('Cannot read emulator screen size')
        width, height = map(int, match.groups())
        x, y = width // 2, height // 2
        adb('shell', 'input', 'swipe', str(x), str(y), str(x + 25), str(y), '2500')
        adb('shell', 'input', 'swipe', str(x), str(height - 40), str(x), '100', '300')
        adb('shell', 'input', 'keyevent', 'KEYCODE_MENU')
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            policy = adb('shell', 'dumpsys', 'window', 'policy')
            windows = adb('shell', 'dumpsys', 'window', 'windows')
            if not keyguard_shown(policy) and not matching_overlay(windows):
                break
            time.sleep(0.5)
        else:
            raise AssertionError('WA overlay remained after emulator unlock')
        wake_to_overlay(adb, 'relock')
        screenshot = subprocess.run(['adb', 'exec-out', 'screencap', '-p'], check=True, capture_output=True, timeout=20).stdout
        (EVIDENCE / 'relocked-position.png').write_bytes(screenshot)
    except Exception as error:
        failure = error
    finally:
        # The emulator has no credential; this returns to the unlocked setup screen.
        adb('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP', check=False)
        adb('shell', 'input', 'swipe', '160', '600', '160', '100', '300', check=False)
        adb('shell', 'input', 'keyevent', 'KEYCODE_MENU', check=False)
        adb('shell', 'am', 'start', '-W', '-n', PACKAGE + '/tk.zwander.lockscreenwidgets.lab.KeyboardLabActivity', check=False)
        tap(wait_node('Zárképernyő teszt'))
        tap(wait_node('Leállítás és másolás'))
        deadline = time.monotonic() + 10
        prefs = ''
        while time.monotonic() < deadline:
            prefs = adb('shell', 'run-as', PACKAGE, 'cat', 'shared_prefs/wa_lab_diagnostics.xml', check=False)
            if '<map>' in prefs and 'name="body"' in prefs:
                break
            time.sleep(0.5)
        (EVIDENCE / 'diagnostics.xml').write_text(prefs)
        if not prefs:
            raise AssertionError('Frozen diagnostic file was not created')
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
    start = next(row for row in rows if row['event'] == 'DRAG_START' and row['widgetId'] == int(widget_id))
    drop = next(row for row in rows if row['event'] == 'DRAG_DROP' and row['widgetId'] == int(widget_id))
    if abs((drop['x'] - start['x']) - 25) > 2 or abs(drop['y'] - start['y']) > 2:
        raise AssertionError('Frame movement did not match the injected screen delta')
    restored = [row for row in rows if row['event'] == 'RESTORE' and row['seq'] > drop['seq']]
    if not restored or (restored[-1]['x'], restored[-1]['y']) != (drop['x'], drop['y']):
        raise AssertionError('Frame position was not restored after relocking')
    if not any(row['event'] == 'VISIBILITY' and row['flags'] & 2 and row['flags'] & (1 << 20) for row in rows):
        raise AssertionError('No allowed keyguard visibility decision was recorded')
    (EVIDENCE / 'lock-episode.txt').write_text('Emulator-only injected accessibility grant; real WA overlay, host draw, single-pointer drag and relock restore recorded.\n')
