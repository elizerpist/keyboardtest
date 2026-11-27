#!/usr/bin/env python3
"""Exercise the lab entry and Android's real widget-consent dialog on an emulator."""
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

EVIDENCE = Path('emulator-evidence')


def adb(*args, check=True):
    return subprocess.run(['adb', *args], check=check, capture_output=True, text=True, timeout=20).stdout


def hierarchy():
    adb('shell', 'uiautomator', 'dump', '/sdcard/wa-window.xml')
    xml = adb('shell', 'cat', '/sdcard/wa-window.xml')
    (EVIDENCE / 'window.xml').write_text(xml)
    return ET.fromstring(xml)


def find_node(root, labels):
    for node in root.iter('node'):
        values = (node.get('text', ''), node.get('content-desc', ''), node.get('resource-id', ''))
        if any(label.casefold() in value.casefold() for label in labels for value in values):
            return node
    return None


def wait_node(*labels, timeout=25):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        node = find_node(hierarchy(), labels)
        if node is not None:
            return node
        time.sleep(0.5)
    raise AssertionError(f'UI element not found: {labels}')


def tap(node):
    bounds = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.get('bounds', ''))
    if bounds is None:
        raise AssertionError('UI element has no tap bounds')
    x1, y1, x2, y2 = map(int, bounds.groups())
    adb('shell', 'input', 'tap', str((x1 + x2) // 2), str((y1 + y2) // 2))



def main():
    try:
        tap(wait_node('Zárképernyő teszt'))
        wait_node('Zárképernyő teszt ·')
        tap(wait_node('Zárképernyős tesztwidget'))
        tap(wait_node('Tesztwidget hozzáadása'))
        tap(wait_node('android:id/button2'))
        wait_node('Kötött widget ID: nincs')
        tap(wait_node('Tesztwidget hozzáadása'))
        tap(wait_node('android:id/button1'))
        deadline = time.monotonic() + 25
        widget_id = None
        while time.monotonic() < deadline:
            node = find_node(hierarchy(), ('Kötött widget ID:',))
            if node is not None:
                match = re.search(r'Kötött widget ID: (\d+)', node.get('text', ''))
                if match:
                    widget_id = match.group(1)
                    break
            time.sleep(0.5)
        if widget_id is None:
            raise AssertionError('Approved widget did not retain a bound ID')
        tap(wait_node('Tesztwidget hozzáadása'))
        wait_node(f'Kötött widget ID: {widget_id}')
        (EVIDENCE / 'consent.txt').write_text(f'Android dialog denied, retried, accepted; repeated add retained ID {widget_id}.\n')
    finally:
        (EVIDENCE / 'logcat.txt').write_text(adb('logcat', '-d', '-v', 'threadtime', check=False))


if __name__ == "__main__":
    main()
