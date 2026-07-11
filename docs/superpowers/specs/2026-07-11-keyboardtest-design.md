# Keyboardtest Design

## Goal

Create a minimal Flutter app that isolates the keyboard-following footer behavior: a FAB opens a slide-up sheet, and a text pill floats above the keyboard as a separate component.

## Architecture

The root screen owns only the sheet open/close state. The sheet body is a fixed bottom panel so tall-sheet content does not jump upward when the keyboard appears. The pill is a separate `FloatingKeyboardPill` component layered inside the sheet `Stack`; it reads `MediaQuery.viewInsets.bottom` and `MediaQuery.padding.bottom` to dock above the keyboard or safe area.

The second motion pass adds a shared `KeyboardMotionMetrics` model. The sheet backplate and the floating pill both consume the same metrics in the same build frame, so there is no independent animation delay between them. Here, "sheet follows in the background" means the lower backplate layer follows the pill as a visual sheet/background layer, while the main sheet shell remains anchored so typed content is not pushed out of view.

The hide-path bounce is fixed by docking to `max(viewInsets.bottom, viewPadding.bottom) + spacing`. When the IME bottom inset reaches zero, the pill lands directly at the safe-area dock instead of dropping to `spacing` and bouncing back upward.

An on-screen debug log is always available in the test app. It shows recent motion events and the current raw inset, safe bottom, dock bottom, keyboard lift, sheet translation, and pill bottom values, similar in spirit to the `exptv2` debug console.

## Scope

Included:
- Copy the local `flutteetest` starter into `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/keyboardtest`.
- Rename the package, Android namespace, and visible title to `keyboardtest`.
- Build a minimal FAB -> slide-up sheet interaction.
- Add a focused text-entry pill that is visually separate from the sheet body.
- Add widget tests for FAB, sheet reveal, and keyboard inset movement.
- Add GitHub Actions debug APK build with artifact name containing the short commit SHA.
- Push to `elizerpist/keyboardtest`, run the online build, and download the APK to `/storage/emulated/0/Download/keyboardtest`.
- Move the sheet backplate and pill from the same keyboard metrics so they slide together without relative delay.
- Prevent the keyboard-hide dock from falling below the safe area.
- Add on-screen debug logs for keyboard motion inspection.

Excluded:
- Native Android IME animation code.
- Production app migration from `exptv2`.
- Release signing.
- Native Android IME animation code for this pass.

## Acceptance

The checklist lives at `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`. Completion requires every row to be `DONE`, or an explicit stated deferral.
