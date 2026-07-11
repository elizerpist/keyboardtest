# Keyboardtest Design

## Goal

Create a minimal Flutter app that isolates the keyboard-following footer behavior: a FAB opens a slide-up sheet, and a text pill floats above the keyboard as a separate component.

## Architecture

The root screen owns only the sheet open/close state. A `KeyboardMotionLayer` reads `MediaQuery.viewInsets.bottom` and `MediaQuery.viewPadding.bottom`, then applies one shared `Transform.translate` to both the actual `SlideUpKeyboardSheet` and the separate `FloatingKeyboardPill`. The pill is still a separate component, but it lives inside the same transformed layer as the sheet.

The corrected motion pass removes the extra sheet backplate/container layer. `KeyboardMotionMetrics.sheetTranslation` provides the single keyboard lift transform for the whole moving layer, and `KeyboardMotionMetrics.layerPillBottom` keeps the pill locally docked above the safe area. The effective on-screen pill dock remains `max(viewInsets.bottom, viewPadding.bottom) + spacing`, without applying the keyboard inset twice.

The hide-path bounce is fixed by docking to `max(viewInsets.bottom, viewPadding.bottom) + spacing`. When the IME bottom inset reaches zero, the pill lands directly at the safe-area dock instead of dropping to `spacing` and bouncing back upward.

The debug log follows the `exptv2` pattern: a small floating terminal button on the left opens a debug dialog. The dialog shows recent motion events, exposes copy-to-clipboard and clear buttons, and includes raw inset, safe bottom, dock bottom, keyboard lift, sheet translation, and pill bottom values.

## Scope

Included:
- Copy the local `flutteetest` starter into `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/keyboardtest`.
- Rename the package, Android namespace, and visible title to `keyboardtest`.
- Build a minimal FAB -> slide-up sheet interaction.
- Add a focused text-entry pill that is visually separate from the sheet body.
- Add widget tests for FAB, sheet reveal, and keyboard inset movement.
- Add GitHub Actions debug APK build with artifact name containing the short commit SHA.
- Push to `elizerpist/keyboardtest`, run the online build, and download the APK to `/storage/emulated/0/Download/keyboardtest`.
- Move the actual slide-up sheet and pill from the same keyboard transform so they slide together without relative delay.
- Prevent the keyboard-hide dock from falling below the safe area.
- Add an `exptv2`-style floating debug button and copyable debug dialog for keyboard motion inspection.

Excluded:
- Native Android IME animation code.
- Production app migration from `exptv2`.
- Release signing.

## Acceptance

The checklist lives at `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`. Completion requires every row to be `DONE`, or an explicit stated deferral.
