# Keyboardtest Design

## Goal

Create a minimal Flutter app that isolates the keyboard-following footer behavior: a FAB opens a slide-up sheet, and a text pill floats above the keyboard as a separate component.

## Architecture

The root screen owns only the sheet open/close state. A `KeyboardMotionLayer` reads `MediaQuery.viewInsets.bottom` and `MediaQuery.viewPadding.bottom`, then applies one shared `Transform.translate` to both the actual `SlideUpKeyboardSheet` and the separate `FloatingKeyboardPill`. The pill is still a separate component, but it lives inside the same transformed layer as the sheet.

The corrected motion pass removes the extra sheet backplate/container layer. `KeyboardMotionMetrics.sheetTranslation` provides the single keyboard lift transform for the whole moving layer, and `KeyboardMotionMetrics.layerPillBottom` keeps the pill locally docked above the safe area. The effective on-screen pill dock remains `max(viewInsets.bottom, viewPadding.bottom) + spacing`, without applying the keyboard inset twice.

The hide-path bounce is fixed by docking to `max(viewInsets.bottom, viewPadding.bottom) + spacing`. When the IME bottom inset reaches zero, the pill lands directly at the safe-area dock instead of dropping to `spacing` and bouncing back upward.

The debug log follows the `exptv2` pattern: a small floating terminal button on the left opens a debug dialog. The dialog shows recent motion events, exposes copy-to-clipboard and clear buttons, and includes raw inset, safe bottom, dock bottom, keyboard lift, sheet translation, and pill bottom values.

The jank diagnostics pass adds low-overhead instrumentation around the keyboard motion path. Motion logs include sample sequence, milliseconds since the previous inset sample, raw inset delta, velocity, dropped-frame-like markers, and build counters for the motion layer, sheet, and pill. A frame timing probe logs build/raster/total milliseconds and 16 ms / 33 ms budget flags when Flutter provides frame timings. Debug console notifications are batched to post-frame updates, following the `exptv2` notifier pattern, so log writes do not synchronously rebuild the dialog for every keyboard sample.

The consistency pass keeps the same shared sheet+pill transform and logs target-vs-rendered motion using `targetLift`, `visualLift`, `lagPx`, and `source`. Active IME samples now apply the current target lift directly in the same frame; this avoids the sheet/pill sitting one raw inset sample behind the Android keyboard, especially while the keyboard hides. Frame timing diagnostics are rate-limited and aggregate suppressed rows so opening the copyable debug dialog does not create its own frame-timing feedback loop.

The debug-tail pass preserves the `keyboard-smooth-v1` shared motion behavior and changes only diagnostic presentation. The debug dialog renders a bounded tail of recent lines to reduce its own build cost, while the copy action exports the complete log buffer. Motion logs split idle gaps from active sample gaps, and frame logs keep `source=flutterFrame` with a separate `debugOpen` flag.

The sample-gap diagnostics pass keeps the same shared transform and labels active IME sample gaps without adding a second visual motion layer. `bridgeMs=0` means the current mainline no longer adds a separate catch-up animation; `bridgedGap=true` still records that a compact sample gap was detected. Frame warmup rows are marked with `warmupFrame`, and the debug dialog renders its visible tail as lightweight scrollable text instead of an editable text field.

The first-slide warmup pass prewarms Flutter's platform text input path after app startup by attaching and closing a no-keyboard `TextInput` client without calling `show()`. Sheet-open diagnostics report `text input prewarm ready=<bool>` so copied logs show whether the first visible pill focus should avoid the text input initialization cost. This does not request focus, does not show the IME, and does not alter the sheet/pill transform math.

For a production sheet full of functional content, the main risk is rebuilding or relayouting heavy content on every keyboard inset sample. This test app keeps the shared transform approach and wraps the moving layer, sheet, and pill in repaint boundaries so the debug log can show whether the sheet subtree is rebuilding every sample (`sheetBuild`) or whether the remaining jank is more likely in raster/compositing or Android IME inset delivery.

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
- Add jank diagnostics for motion timing, frame timing, build counters, focus changes, and repaint boundary isolation.
- Rate-limit debug frame timing logs and add visual lift diagnostics for target-vs-rendered keyboard motion.
- Keep the smooth shared motion milestone intact while reducing debug dialog render cost and clarifying diagnostic labels.
- Apply active IME samples directly from the existing shared transform and label sample-gap/warmup/debug diagnostics without changing sheet content rebuild behavior.
- Prewarm the platform text input path before the first visible pill focus to reduce first-slide-only initialization jank.

Excluded:
- Native Android IME animation code.
- Production app migration from `exptv2`.
- Release signing.

## Acceptance

The checklist lives at `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`. Completion requires every row to be `DONE`, or an explicit stated deferral.
