# Keyboardtest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a minimal Flutter keyboard footer test app.

**Architecture:** A shared keyboard motion layer reads `MediaQuery.viewInsets.bottom` and moves both the actual slide-up sheet and the separate floating text pill from one transform. The pill remains its own component, but it is visually synchronized with the sheet and can use a short bounded catch-up to smooth raw IME sample jitter.

**Tech Stack:** Flutter, Dart widget tests, GitHub Actions, Android debug APK.

## Global Constraints

- Project path must be `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/keyboardtest`.
- Starter source is `/data/data/com.termux/files/home/flutteetest`.
- Local Flutter commands must run through Ubuntu/proot.
- Local APK builds must not be run in Termux; APK build must run through GitHub Actions.
- GitHub repo name must be `keyboardtest`.
- Download destination must be `/storage/emulated/0/Download/keyboardtest`.
- Artifact name must include the short commit SHA.

---

### Task 1: Project Identity And Documentation

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/build.gradle.kts`
- Move: `android/app/src/main/kotlin/com/example/flutteetest/MainActivity.kt`
- Create: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`
- Create: `docs/superpowers/specs/2026-07-11-keyboardtest-design.md`

**Interfaces:**
- Produces project identity `keyboardtest`.
- Produces acceptance checklist used before final status.

- [x] Copy starter into the target folder without build/cache/IDE files.
- [x] Rename Dart package and Android application identity to `keyboardtest`.
- [x] Initialize git repository.
- [x] Commit the initial project baseline.

### Task 2: TDD For FAB, Sheet, And Floating Pill

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Produces `KeyboardTestApp`, `KeyboardTestHome`, `SlideUpKeyboardSheet`, and `FloatingKeyboardPill`.
- Tests verify visible behavior using widget keys:
  - `keyboardtest-open-sheet-fab`
  - `keyboardtest-slide-sheet`
  - `keyboardtest-floating-pill`
  - `keyboardtest-pill-field`

- [x] Replace the counter smoke test with failing widget tests for the FAB, sheet reveal, and fake keyboard inset movement.
- [x] Run targeted Flutter test through Ubuntu/proot and confirm the new tests fail before implementation.
- [x] Replace the counter app with the keyboard test app.
- [x] Run targeted Flutter test through Ubuntu/proot and confirm it passes.

### Task 3: GitHub Actions Build

**Files:**
- Create: `.github/workflows/android-build.yml`

**Interfaces:**
- Produces `keyboardtest-${{ steps.vars.outputs.short_sha }}-debug-apk` artifact.

- [x] Add workflow triggered by push and manual dispatch.
- [x] Use Flutter stable setup, run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --debug`.
- [x] Upload `build/app/outputs/flutter-apk/app-debug.apk` with a short-SHA artifact name.

### Task 4: Verification, Push, Online Build, Download

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`

**Interfaces:**
- Consumes GitHub CLI auth for `elizerpist`.
- Produces APK under `/storage/emulated/0/Download/keyboardtest`.

- [x] Run `flutter analyze` through Ubuntu/proot.
- [x] Run `flutter test` through Ubuntu/proot.
- [x] Update checklist statuses that local verification proves.
- [x] Commit implementation.
- [x] Create or reuse GitHub repo `elizerpist/keyboardtest`.
- [x] Push `main`.
- [x] Wait for GitHub Actions build.
- [x] Download artifact and copy APK to `/storage/emulated/0/Download/keyboardtest`.
- [x] Update checklist to `DONE` only for verified rows.

### Task 5: Synchronized Sheet Motion And Debug Panel

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/main.dart`
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`

**Interfaces:**
- Produces `KeyboardMotionMetrics.fromContext(BuildContext context)`.
- Produces `MotionDebugLog`, a small in-memory visible debug log for the test app.
- Keeps widget keys:
  - `keyboardtest-slide-sheet`
  - `keyboardtest-sheet-backplate`
  - `keyboardtest-floating-pill`
  - `keyboardtest-debug-panel`

- [x] Add failing widget tests for same-frame sheet backplate and pill motion.
- [x] Add failing widget tests for safe-area bounce prevention when inset returns to zero.
- [x] Add failing widget tests for on-screen debug values.
- [x] Implement `KeyboardMotionMetrics` with `dockBottom = max(rawInset, safeBottom) + 12`.
- [x] Move the backplate and pill from the same metrics without independent animations.
- [x] Add compact visible debug panel with recent motion lines.
- [x] Run `flutter analyze` and `flutter test` through Ubuntu/proot.
- [x] Update checklist statuses from verified evidence.
- [x] Commit, push, wait for online debug APK build, and download the updated artifact.

### Task 6: Correct Sheet Motion And Debug Console

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/main.dart`
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`
- Modify: `docs/superpowers/specs/2026-07-11-keyboardtest-design.md`

**Interfaces:**
- `KeyboardMotionMetrics.sheetTranslation` remains the shared vertical transform for the keyboard lift.
- `KeyboardMotionMetrics.layerPillBottom` is the pill's local bottom inside the transformed sheet layer.
- `DebugConsole.log(String message)` stores debug entries.
- `DebugFloatingButton` uses `debug-floating-button` and opens `DebugConsoleDialog`.
- `DebugConsoleDialog` uses `debug-console-dialog`, `debug-console-copy`, `debug-console-clear`, and `debug-console-close`.

- [x] Write failing widget tests proving the actual slide-up sheet and pill move by the same keyboard delta.
- [x] Write failing widget tests proving no `keyboardtest-sheet-backplate` layer exists.
- [x] Write failing widget tests proving there is no fixed `keyboardtest-debug-panel`.
- [x] Write failing widget tests proving the left debug button opens a dialog and the copy button writes log text to the clipboard.
- [x] Remove the separate `_SheetBackplate` layer.
- [x] Move the sheet and pill together with one shared `Transform.translate`.
- [x] Replace the fixed debug overlay with an `exptv2`-style floating debug button and dialog.
- [x] Run `flutter analyze` and `flutter test` through Ubuntu/proot.
- [x] Update checklist statuses from verified evidence.
- [x] Commit, push, wait for online debug APK build, and download the updated artifact.

### Task 7: Jank Diagnostics And Motion Isolation

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/main.dart`
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`
- Modify: `docs/superpowers/specs/2026-07-11-keyboardtest-design.md`

**Interfaces:**
- `DebugConsole.logMotion(KeyboardMotionMetrics metrics)` logs `seq`, `dtMs`, `rawDelta`, `velocity`, `droppedLike`, and build counters.
- `DebugPerformanceProbe.ensureStarted()` installs a frame timing callback and logs `buildMs`, `rasterMs`, `totalMs`, `over16ms`, and `over33ms` fields when timings arrive.
- `DebugBuildStats` tracks `motionBuild`, `sheetBuild`, and `pillBuild`.
- Repaint boundary keys:
  - `keyboardtest-motion-repaint-boundary`
  - `keyboardtest-sheet-repaint-boundary`
  - `keyboardtest-pill-repaint-boundary`

- [x] Write failing widget tests proving copied logs include jank diagnostic fields.
- [x] Write failing widget tests proving motion/sheet/pill repaint boundaries exist.
- [x] Add batched debug notifier so log writes do not synchronously rebuild the dialog for every keyboard sample.
- [x] Add motion sample diagnostics: sequence number, milliseconds since previous sample, raw inset delta, velocity, and dropped-frame-like marker.
- [x] Add frame timing instrumentation with build/raster/total milliseconds and over-budget flags.
- [x] Add build counters for motion layer, sheet, and pill.
- [x] Add focus change logs for the pill field.
- [x] Wrap moving layer, sheet, and pill in repaint boundaries.
- [x] Run `flutter analyze` and `flutter test` through Ubuntu/proot.
- [x] Update checklist statuses from verified evidence.
- [x] Commit, push, wait for online debug APK build, and download the updated artifact.

### Task 8: Consistent Keyboard Motion And Debug Throttling

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/main.dart`
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`
- Modify: `docs/superpowers/specs/2026-07-11-keyboardtest-design.md`

**Interfaces:**
- `KeyboardMotionLayer` remains the only shared transform owner for the actual `SlideUpKeyboardSheet` and `FloatingKeyboardPill`.
- `KeyboardMotionMetrics.withVisualLift(double visualLift, {required String source})` produces debug metrics containing `targetLift`, `visualLift`, `lagPx`, and `source`.
- `DebugPerformanceProbe` logs `rateLimitMs`, `suppressed`, `worstTotalMs`, and `source` so frame timing diagnostics do not flood the console.
- `DebugConsole._scheduleNotify()` batches listener updates without calling `WidgetsBinding.instance.scheduleFrame()`.

- [x] Write failing widget tests proving copied logs include `targetLift`, `visualLift`, `lagPx`, `source`, `rateLimitMs`, `suppressed`, and `worstTotalMs`.
- [x] Write/update widget tests proving the sheet and pill still move by the same settled keyboard delta from one shared transform.
- [x] Run targeted Flutter widget tests through Ubuntu/proot and confirm the new diagnostics test fails before implementation.
- [x] Remove the explicit `scheduleFrame()` call from debug console notification.
- [x] Rate-limit frame timing logs and aggregate suppressed frame timing rows.
- [x] Add visual lift diagnostics and a short shared-transform catch-up for IME sample jitter.
- [x] Run `flutter analyze` and `flutter test` through Ubuntu/proot.
- [x] Update checklist statuses from verified evidence.
- [x] Commit, push, wait for online debug APK build, and download the updated artifact.

### Task 9: Debug Console Tail View And Clearer Gap Labels

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/main.dart`
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`
- Modify: `docs/superpowers/specs/2026-07-11-keyboardtest-design.md`

**Interfaces:**
- `DebugConsole.visibleTailText` returns only the recent visible lines used by `DebugConsoleDialog`.
- `DebugConsole.allText` remains the full copy/export payload.
- `DebugConsole.logMotion(KeyboardMotionMetrics metrics)` appends `idleGap`, `sampleGap`, `activeMotion`, and `motionPhase`.
- `DebugPerformanceProbe` logs `source=flutterFrame debugOpen=<bool>` for frame timing rows.
- `KeyboardMotionLayer` keeps the shared-transform architecture from `keyboard-smooth-v1`.

- [x] Write failing widget tests proving the dialog text is truncated to recent tail lines but copied text contains full history.
- [x] Write failing widget tests proving copied diagnostics include `idleGap`, `sampleGap`, `activeMotion`, `motionPhase`, and `debugOpen`.
- [x] Run targeted Flutter widget tests through Ubuntu/proot and confirm the new tests fail before implementation.
- [x] Add `DebugConsole.visibleTailText` and update the dialog to render that tail.
- [x] Change copy behavior to copy `DebugConsole.allText` rather than the visible controller text.
- [x] Add motion gap labels without changing visual motion math.
- [x] Change frame timing logs to keep `source=flutterFrame` and add `debugOpen`.
- [x] Run `flutter analyze` and `flutter test` through Ubuntu/proot.
- [x] Update checklist statuses from verified evidence.
- [x] Commit, push, wait for online debug APK build, and download the updated artifact.

### Task 10: Active Sample Gap Bridging And Lightweight Debug Text

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/main.dart`
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`
- Modify: `docs/superpowers/specs/2026-07-11-keyboardtest-design.md`

**Interfaces:**
- `KeyboardMotionLayer` keeps one shared transform around `SlideUpKeyboardSheet` and `FloatingKeyboardPill`.
- `KeyboardMotionMetrics.withVisualLift(double visualLift, {required String source, required int bridgeMs, required bool bridgedGap})` carries bridge diagnostics into copied motion logs.
- `DebugPerformanceProbe` logs `warmupFrame=<bool>` for frame rows.
- `DebugConsoleDialog` renders `DebugConsole.visibleTailText` as lightweight text inside a scroll view and still copies `DebugConsole.allText`.

- [x] Write failing widget tests proving copied logs include `bridgeMs=`, `bridgedGap=`, and `warmupFrame=`.
- [x] Write failing widget tests proving the debug dialog no longer has a descendant log `TextField` while copy still exports old and recent log lines.
- [x] Run targeted Flutter widget tests through Ubuntu/proot and confirm the new tests fail before implementation.
- [x] Add bridge diagnostics to `KeyboardMotionMetrics`.
- [x] Add adaptive active sample-gap bridge duration in `KeyboardMotionLayer` without adding a new motion layer. This was later superseded by Task 11 after measured downward lag.
- [x] Add `warmupFrame` to frame timing logs.
- [x] Replace the dialog log `TextField` with lightweight scrollable text.
- [x] Run `flutter analyze` and `flutter test` through Ubuntu/proot.
- [x] Update checklist statuses from verified evidence.
- [x] Commit, push, wait for online debug APK build, and download the updated artifact.

### Task 11: Direct Active IME Sample Sync

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/main.dart`
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`
- Modify: `docs/superpowers/specs/2026-07-11-keyboardtest-design.md`

**Interfaces:**
- `KeyboardMotionLayer` remains the only shared transform owner for the actual `SlideUpKeyboardSheet` and `FloatingKeyboardPill`.
- `KeyboardMotionMetrics.withVisualLift(...)` still carries copied diagnostics, but active IME samples set `visualLift == targetLift` in the same frame.
- `bridgedGap` remains a diagnostic flag for compact active IME sample gaps; `bridgeMs=0` indicates no extra visual catch-up animation is being applied.

- [x] Write a failing widget test proving opening and closing IME samples are visible in the same frame without waiting for catch-up.
- [x] Run the targeted Flutter widget test through Ubuntu/proot and confirm it fails before implementation.
- [x] Remove the extra `TweenAnimationBuilder` catch-up from `KeyboardMotionLayer`.
- [x] Keep sample-gap diagnostics while applying the target lift directly.
- [x] Run `flutter analyze` and `flutter test` through Ubuntu/proot.
- [x] Update checklist statuses from verified evidence.
- [x] Commit, push, wait for online debug APK build, and download the updated artifact.

### Task 12: First Keyboard Slide TextInput Prewarm

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/main.dart`
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`
- Modify: `docs/superpowers/specs/2026-07-11-keyboardtest-design.md`

**Interfaces:**
- `KeyboardInputWarmup.ensureScheduled()` prewarms Flutter/platform text input after app startup without calling `show()` and without focusing `keyboardtest-pill-field`.
- Sheet-open diagnostics log `text input prewarm ready=<bool>` so first-slide warmup state is visible in copied logs.

- [x] Write a failing widget test proving sheet-open logs report ready text input prewarm before pill focus.
- [x] Run the targeted Flutter widget test through Ubuntu/proot and confirm it fails before implementation.
- [x] Add an idempotent no-keyboard TextInput attach/close warmup.
- [x] Log warmup readiness during sheet open.
- [x] Run `flutter analyze` and `flutter test` through Ubuntu/proot.
- [x] Update checklist statuses from verified evidence.
- [ ] Commit, push, wait for online debug APK build, and download the updated artifact.
