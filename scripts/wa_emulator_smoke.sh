#!/usr/bin/env bash
set -euo pipefail
mkdir -p emulator-evidence
adb shell getprop ro.build.version.sdk | tee emulator-evidence/api.txt
test "$(tr -d '\r' < emulator-evidence/api.txt)" = 37
adb shell getprop ro.build.fingerprint | tee emulator-evidence/fingerprint.txt
adb shell getprop ro.product.cpu.abi | tee emulator-evidence/abi.txt
mapfile -t apks < <(find wa-evidence -name '*.apk' -type f)
test "${#apks[@]}" -eq 1
sha256sum "${apks[0]}" | tee emulator-evidence/apk-sha256.txt
adb install "${apks[0]}"
adb shell dumpsys package com.example.keyboardtest.walab > emulator-evidence/package.txt
grep -F 'tk.zwander.lockscreenwidgets.lab.LabWidgetProvider' emulator-evidence/package.txt
grep -F 'tk.zwander.lockscreenwidgets.services.Accessibility' emulator-evidence/package.txt
grep -F 'tk.zwander.lockscreenwidgets.services.NotificationListener' emulator-evidence/package.txt
adb shell am start -W -n com.example.keyboardtest.walab/tk.zwander.lockscreenwidgets.lab.KeyboardLabActivity | tee emulator-evidence/launch.txt
if grep -E 'Error:|Exception|Status: error' emulator-evidence/launch.txt; then exit 1; fi
adb shell dumpsys activity activities > emulator-evidence/activities.txt
grep -F 'tk.zwander.lockscreenwidgets.lab.KeyboardLabActivity' emulator-evidence/activities.txt
adb exec-out screencap -p > emulator-evidence/keyboard.png
adb logcat -d -v threadtime > emulator-evidence/logcat.txt
