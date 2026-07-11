# Keyboardtest Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a minimal Flutter keyboard footer test app.

**Architecture:** A fixed slide-up sheet contains a separate floating text pill footer. The footer reads `MediaQuery.viewInsets.bottom` directly, so only the footer follows the keyboard and the sheet body does not jump upward.

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
- [ ] Rename Dart package and Android application identity to `keyboardtest`.
- [ ] Initialize git repository.
- [ ] Commit the initial project baseline.

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

- [ ] Replace the counter smoke test with failing widget tests for the FAB, sheet reveal, and fake keyboard inset movement.
- [ ] Run targeted Flutter test through Ubuntu/proot and confirm the new tests fail before implementation.
- [ ] Replace the counter app with the keyboard test app.
- [ ] Run targeted Flutter test through Ubuntu/proot and confirm it passes.

### Task 3: GitHub Actions Build

**Files:**
- Create: `.github/workflows/android-build.yml`

**Interfaces:**
- Produces `keyboardtest-${{ steps.vars.outputs.short_sha }}-debug-apk` artifact.

- [ ] Add workflow triggered by push and manual dispatch.
- [ ] Use Flutter stable setup, run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --debug`.
- [ ] Upload `build/app/outputs/flutter-apk/app-debug.apk` with a short-SHA artifact name.

### Task 4: Verification, Push, Online Build, Download

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`

**Interfaces:**
- Consumes GitHub CLI auth for `elizerpist`.
- Produces APK under `/storage/emulated/0/Download/keyboardtest`.

- [ ] Run `flutter analyze` through Ubuntu/proot.
- [ ] Run `flutter test` through Ubuntu/proot.
- [ ] Update checklist statuses that local verification proves.
- [ ] Commit implementation.
- [ ] Create or reuse GitHub repo `elizerpist/keyboardtest`.
- [ ] Push `main`.
- [ ] Wait for GitHub Actions build.
- [ ] Download artifact and copy APK to `/storage/emulated/0/Download/keyboardtest`.
- [ ] Update checklist to `DONE` only for verified rows.

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
- [ ] Commit, push, wait for online debug APK build, and download the updated artifact.
