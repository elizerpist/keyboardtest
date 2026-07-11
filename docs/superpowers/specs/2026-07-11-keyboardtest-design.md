# Keyboardtest Design

## Goal

Create a minimal Flutter app that isolates the keyboard-following footer behavior: a FAB opens a slide-up sheet, and a text pill floats above the keyboard as a separate component.

## Architecture

The root screen owns only the sheet open/close state. The sheet body is a fixed bottom panel so tall-sheet content does not jump upward when the keyboard appears. The pill is a separate `FloatingKeyboardPill` component layered inside the sheet `Stack`; it reads `MediaQuery.viewInsets.bottom` and `MediaQuery.padding.bottom` to dock above the keyboard or safe area.

## Scope

Included:
- Copy the local `flutteetest` starter into `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/keyboardtest`.
- Rename the package, Android namespace, and visible title to `keyboardtest`.
- Build a minimal FAB -> slide-up sheet interaction.
- Add a focused text-entry pill that is visually separate from the sheet body.
- Add widget tests for FAB, sheet reveal, and keyboard inset movement.
- Add GitHub Actions debug APK build with artifact name containing the short commit SHA.
- Push to `elizerpist/keyboardtest`, run the online build, and download the APK to `/storage/emulated/0/Download/keyboardtest`.

Excluded:
- Native Android IME animation code.
- Production app migration from `exptv2`.
- Release signing.

## Acceptance

The checklist lives at `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`. Completion requires every row to be `DONE`, or an explicit stated deferral.
