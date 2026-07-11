# Keyboard Performance And Direct APK Delivery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a profile-measured keyboard-following app with a low-overhead diagnostics path, publish its profile APK at a direct GitHub Release URL, and download it to Android shared storage.

**Architecture:** A new diagnostics module owns structured samples, frame-budget math, bounded storage, and report formatting. `KeyboardMotionLayer` observes `FlutterView` metrics directly and rebuilds only a small shared transform around a stable sheet/pill child. GitHub Actions publishes the profile APK as a commit-specific Release asset rather than an Actions artifact.

**Tech Stack:** Flutter 3.41/Dart, Flutter widget and unit tests, GitHub Actions, GitHub CLI/Releases, Android profile APK.

## Global Constraints

- Project path is `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/keyboardtest`.
- Flutter tests and analysis run through Ubuntu proot with `/home/flutteruser/flutter/bin/flutter`.
- Do not run a local Flutter APK build in Termux; the APK build runs in GitHub Actions.
- Keep one shared transform for the actual sheet and floating pill.
- Do not install another Android `setWindowInsetsAnimationCallback`.
- Apply authoritative IME samples directly; do not restore the fixed catch-up tween.
- Publish `keyboardtest-<short-sha>-profile.apk` as a direct GitHub Release asset, not through `actions/upload-artifact`.
- Download the successful asset to `/storage/emulated/0/Download/keyboardtest` without deleting older APKs.
- Completion requires KT-026 through KT-033 to be `DONE`, or an explicit user-approved deferral.

---

### Task 1: Structured Performance Diagnostics Core

**Files:**
- Create: `lib/performance_diagnostics.dart`
- Create: `test/performance_diagnostics_test.dart`

**Interfaces:**
- Produces: `FrameBudget.fromRefreshRate(double refreshRate)`, `FrameBudget.fromObservedVsync({required double refreshRate, required List<double> observedVsyncMs})`.
- Produces: `MotionDiagnosticSample`, `FrameDiagnosticSample`, and `TextDiagnosticSample`, each implementing `DiagnosticSample.format()`.
- Produces: `DiagnosticRingBuffer({required int capacity})`, `add(DiagnosticSample)`, `clear()`, `formattedText`, and `formattedTail(int count)`.
- Produces: `PerformanceSummary.fromFrames(Iterable<FrameDiagnosticSample>)` with p95 build/raster/total-span metrics and over-budget counters.

- [ ] **Step 1: Write failing frame-budget and ring-buffer tests**

```dart
test('frame budget follows display refresh and observed vsync', () {
  expect(FrameBudget.fromRefreshRate(60).milliseconds, closeTo(16.67, 0.01));
  expect(FrameBudget.fromRefreshRate(120).milliseconds, closeTo(8.33, 0.01));
  final observed = FrameBudget.fromObservedVsync(
    refreshRate: 120,
    observedVsyncMs: const [16.6, 16.7, 16.8],
  );
  expect(observed.milliseconds, closeTo(16.7, 0.1));
});

test('ring buffer is bounded and formats only on demand', () {
  var formatCalls = 0;
  final buffer = DiagnosticRingBuffer(capacity: 2);
  buffer.add(FakeSample('one', () => formatCalls += 1));
  buffer.add(FakeSample('two', () => formatCalls += 1));
  buffer.add(FakeSample('three', () => formatCalls += 1));
  expect(formatCalls, 0);
  expect(buffer.formattedText, 'two\nthree');
  expect(formatCalls, 2);
});
```

- [ ] **Step 2: Run the diagnostics test and confirm RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/keyboardtest && /home/flutteruser/flutter/bin/flutter test test/performance_diagnostics_test.dart'
```

Expected: compilation failure because the diagnostics types do not exist.

- [ ] **Step 3: Implement the minimal diagnostics core**

Implement immutable numeric samples and a generic bounded list. Use linear interpolation for p95 and the median observed vsync interval when at least three valid observed intervals exist. Fall back to `1000 / refreshRate`, with 60 Hz used only when the reported refresh rate is non-finite or non-positive.

The production API must have these signatures:

```dart
abstract interface class DiagnosticSample {
  String format();
}

final class FrameBudget {
  const FrameBudget(this.milliseconds);
  final double milliseconds;
  factory FrameBudget.fromRefreshRate(double refreshRate);
  factory FrameBudget.fromObservedVsync({
    required double refreshRate,
    required List<double> observedVsyncMs,
  });
}

final class DiagnosticRingBuffer {
  DiagnosticRingBuffer({required this.capacity});
  final int capacity;
  void add(DiagnosticSample sample);
  void clear();
  String get formattedText;
  String formattedTail(int count);
}
```

- [ ] **Step 4: Add failing summary classification tests**

Create frame samples with a 16.67 ms budget and assert that build/raster overruns are classified independently, while `totalSpan` remains latency rather than being calculated as build plus raster.

- [ ] **Step 5: Implement `FrameDiagnosticSample` and `PerformanceSummary`**

Store `buildMs`, `rasterMs`, `totalSpanMs`, `vsyncOverheadMs`, `vsyncDeltaMs`, `refreshRate`, `budgetMs`, `frameNumber`, and the latest motion sequence. Format labels exactly once in `format()`.

- [ ] **Step 6: Run the diagnostics tests and confirm GREEN**

Run the targeted command from Step 2. Expected: all diagnostics tests pass.

- [ ] **Step 7: Commit the diagnostics core**

```bash
git add lib/performance_diagnostics.dart test/performance_diagnostics_test.dart
git commit -m "feat: add structured keyboard diagnostics"
```

### Task 2: Low-Overhead Console Integration

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: all Task 1 diagnostics types.
- Preserves: `DebugConsole.log`, `DebugConsole.clear`, `DebugConsole.allText`, `DebugConsole.visibleTailText`, and `DebugConsole.notifier` for existing UI/tests.
- Produces: `DebugConsole.detailedCollectionEnabled`, `DebugConsole.setDetailedCollectionEnabled(bool)`, and a copied `PerformanceSummary` section.

- [ ] **Step 1: Write failing compatibility and deferred-formatting widget tests**

Add tests proving that ordinary text logs still display/copy, motion records appear only when detailed collection is enabled, and toggling detailed collection does not schedule a frame by itself.

```dart
DebugConsole.setDetailedCollectionEnabled(false);
DebugConsole.logMotion(sampleMetrics);
expect(DebugConsole.allText, isNot(contains('raw=')));
DebugConsole.setDetailedCollectionEnabled(true);
DebugConsole.logMotion(sampleMetrics);
expect(DebugConsole.allText, contains('raw='));
```

- [ ] **Step 2: Run the targeted widget tests and confirm RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/keyboardtest && /home/flutteruser/flutter/bin/flutter test test/widget_test.dart'
```

Expected: compilation failure for the new collection-control API.

- [ ] **Step 3: Replace hot-path string storage with structured samples**

Keep the public `DebugConsole` facade in `main.dart`, but back it with `DiagnosticRingBuffer(capacity: 500)`. `logMotion` creates `MotionDiagnosticSample`; `DebugPerformanceProbe` creates `FrameDiagnosticSample`; `allText` and `visibleTailText` perform formatting. Do not call `toStringAsFixed`, join the full history, or rebuild the dialog while it has no listener.

- [ ] **Step 4: Correct frame timing collection**

Replace `buildMs + rasterMs` with Flutter's separate values and `timing.totalSpan`. Record `timing.vsyncOverhead`, `timing.frameNumber`, and vsync-start deltas from `timestampInMicroseconds(FramePhase.vsyncStart)`. Derive the current budget from `WidgetsBinding.instance.platformDispatcher.views.first.display.refreshRate` and recent valid vsync deltas.

- [ ] **Step 5: Add a lightweight diagnostics toggle to the dialog**

Add a compact `Switch` keyed `debug-detailed-collection-switch`. Changing it calls `DebugConsole.setDetailedCollectionEnabled`; it must not alter keyboard focus or the motion layer.

- [ ] **Step 6: Run widget and diagnostics tests and confirm GREEN**

Run both test files through proot. Expected: all tests pass.

- [ ] **Step 7: Commit console integration**

```bash
git add lib/main.dart test/widget_test.dart
git commit -m "fix: remove diagnostics from keyboard hot path"
```

### Task 3: Metrics Arrival Timing And Stable Motion Subtree

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: `_KeyboardMotionLayerState` as a `WidgetsBindingObserver`.
- Produces: `_MotionVisualContent`, a const stable child containing the actual `SlideUpKeyboardSheet` and `FloatingKeyboardPill`.
- Preserves: immediate authoritative target application and all existing widget keys.

- [ ] **Step 1: Write failing stable-subtree and latency-field tests**

Pump several fake `viewInsets` changes and assert:

```dart
expect(DebugBuildStats.sheetBuild, 1);
expect(DebugBuildStats.textPillBuild, 1);
expect(DebugBuildStats.transformBuild, greaterThan(3));
expect(DebugConsole.allText, contains('metricsToBuildMs='));
expect(DebugConsole.allText, contains('metricsToPostFrameMs='));
```

Retain assertions that opening and closing authoritative samples move sheet and pill immediately by identical deltas.

- [ ] **Step 2: Run the targeted tests and confirm RED**

Expected: missing counters/latency labels.

- [ ] **Step 3: Observe metrics with a monotonic session clock**

Make `_KeyboardMotionLayerState` implement `WidgetsBindingObserver`. In `didChangeMetrics`, read physical `viewInsets` and `viewPadding` from the current `FlutterView`, divide by `devicePixelRatio`, record the session `Stopwatch.elapsedMicroseconds`, and assign an immutable metrics value to a `ValueNotifier`.

Register the observer in `initState`, seed the initial value after dependencies exist, and remove/dispose it in `dispose`.

- [ ] **Step 4: Move the visual content into the builder child slot**

Use this structure:

```dart
ValueListenableBuilder<KeyboardMotionMetrics>(
  valueListenable: _metrics,
  child: const _MotionVisualContent(),
  builder: (context, metrics, child) {
    DebugBuildStats.transformBuild += 1;
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(0, metrics.sheetTranslation),
        child: child,
      ),
    );
  },
)
```

`_MotionVisualContent` contains the existing repaint boundary and Stack. `FloatingKeyboardPill` no longer needs changing metrics because its local bottom remains `safeBottom + spacing`; provide the safe-area dock through the stable initial configuration and update it only if view padding itself changes.

- [ ] **Step 5: Record arrival-to-build and arrival-to-post-frame latency**

Use the same session `Stopwatch` for all three points. Store numeric microseconds in `MotionDiagnosticSample`, and format `metricsToBuildMs` and `metricsToPostFrameMs` only on report generation.

- [ ] **Step 6: Run all Flutter tests and analysis**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/keyboardtest && /home/flutteruser/flutter/bin/flutter test && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: tests pass and analyzer reports no issues.

- [ ] **Step 7: Commit the stable motion path**

```bash
git add lib/main.dart test/widget_test.dart
git commit -m "perf: isolate keyboard transform updates"
```

### Task 4: Direct Profile APK Release Workflow

**Files:**
- Create: `test/workflow_contract_test.dart`
- Modify: `.github/workflows/android-build.yml`

**Interfaces:**
- Produces: Git tag `keyboardtest-<short-sha>`.
- Produces: Release asset `keyboardtest-<short-sha>-profile.apk`.
- Produces: direct browser URL in `$GITHUB_STEP_SUMMARY`.

- [ ] **Step 1: Write the failing workflow contract test**

```dart
test('workflow publishes a direct profile APK release asset', () {
  final yaml = File('.github/workflows/android-build.yml').readAsStringSync();
  expect(yaml, contains('flutter build apk --profile'));
  expect(yaml, contains('permissions:'));
  expect(yaml, contains('contents: write'));
  expect(yaml, contains('gh release upload'));
  expect(yaml, contains('gh release create'));
  expect(yaml, contains(r'keyboardtest-${{ steps.vars.outputs.short_sha }}-profile.apk'));
  expect(yaml, contains(r'$GITHUB_STEP_SUMMARY'));
  expect(yaml, isNot(contains('actions/upload-artifact')));
});
```

- [ ] **Step 2: Run the contract test and confirm RED**

Run the new test through proot. Expected: failure because the workflow still builds debug and uses `actions/upload-artifact`.

- [ ] **Step 3: Implement the profile Release workflow**

Set workflow/job names to profile APK, add top-level `permissions: contents: write`, and permit pushes to `main` and `feat/**`. Keep analyze and test before build. Build with `flutter build apk --profile` and copy `app-profile.apk` to the SHA-bearing filename.

Use `GH_TOKEN: ${{ github.token }}` and an idempotent shell step:

```bash
tag="keyboardtest-${{ steps.vars.outputs.short_sha }}"
apk="artifacts/keyboardtest-${{ steps.vars.outputs.short_sha }}-profile.apk"
if gh release view "$tag" >/dev/null 2>&1; then
  gh release upload "$tag" "$apk" --clobber
else
  gh release create "$tag" "$apk" --target "$GITHUB_SHA" \
    --title "keyboardtest ${{ steps.vars.outputs.short_sha }} profile" \
    --notes "Profile APK for commit $GITHUB_SHA"
fi
url="https://github.com/${GITHUB_REPOSITORY}/releases/download/${tag}/$(basename "$apk")"
echo "### Direct profile APK" >> "$GITHUB_STEP_SUMMARY"
echo "[Download $(basename "$apk")]($url)" >> "$GITHUB_STEP_SUMMARY"
```

- [ ] **Step 4: Run the contract test and full Flutter verification**

Expected: contract test, full tests, and analysis pass.

- [ ] **Step 5: Commit the workflow**

```bash
git add .github/workflows/android-build.yml test/workflow_contract_test.dart
git commit -m "ci: publish direct profile APK release"
```

### Task 5: Online Build, Direct Download, And Delivery Verification

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`
- Modify: `docs/superpowers/plans/2026-07-11-keyboard-performance-delivery.md`

**Interfaces:**
- Consumes: pushed `feat/profile-keyboard-performance` branch and Task 4 workflow.
- Produces: direct Release URL and local APK under `/storage/emulated/0/Download/keyboardtest`.

- [ ] **Step 1: Re-read the specification and KT-026 through KT-033**

Do not change a status to `DONE` without the verification evidence named in that row.

- [ ] **Step 2: Run fresh local verification**

Run full Flutter tests, analysis, `git diff --check`, and inspect `git status`.

- [ ] **Step 3: Push the feature branch**

```bash
git push -u origin feat/profile-keyboard-performance
```

- [ ] **Step 4: Wait for the branch workflow to finish**

Use `gh run list --branch feat/profile-keyboard-performance`, then `gh run watch <run-id> --exit-status`. On failure, inspect `gh run view <run-id> --log-failed`, fix through a new failing test where applicable, and push the corrective commit.

- [ ] **Step 5: Resolve and verify the direct URL**

Read the short SHA, release tag, asset name, asset size, and `browser_download_url` with `gh release view keyboardtest-<short-sha> --json assets,url`.

- [ ] **Step 6: Download the direct APK without an archive wrapper**

```bash
mkdir -p /storage/emulated/0/Download/keyboardtest
curl --fail --location --output \
  /storage/emulated/0/Download/keyboardtest/keyboardtest-<short-sha>-profile.apk \
  https://github.com/elizerpist/keyboardtest/releases/download/keyboardtest-<short-sha>/keyboardtest-<short-sha>-profile.apk
```

- [ ] **Step 7: Verify file type, size, and SHA-256**

Run `file`, `stat`, and `sha256sum` on the local file. Download the same release asset to a temporary private path using `gh release download`, compare SHA-256 values, then remove only the temporary comparison file.

- [ ] **Step 8: Update delivery checklist statuses and commit evidence**

Mark KT-032 and KT-033 `DONE` only after the successful job, direct HTTP download, and checksum match. Leave performance rows pending until Task 6 evidence exists.

### Task 6: Physical Profile Measurement And Conditional Gap Decision

**Files:**
- Modify if evidence requires: `lib/main.dart`
- Modify if predictor is enabled: `test/performance_diagnostics_test.dart`
- Modify: `docs/superpowers/checklists/2026-07-11-keyboardtest-checklist.md`

**Interfaces:**
- Consumes: installed Task 5 profile APK and copied diagnostic report.
- Produces: ten-cycle enabled/disabled performance evidence and an explicit predictor decision.

- [ ] **Step 1: Install/open the downloaded profile APK on the physical Android device**

Use an available local ADB connection if authorized. If Android requires interactive package-install confirmation, keep delivery complete but report KT-030/KT-031 as not yet verified until the user installs and runs the APK.

- [ ] **Step 2: Capture two ten-cycle runs after one warmup cycle**

Keep the debug dialog closed while moving the keyboard. Capture one minimal-collection run and one detailed-collection run, then copy each report.

- [ ] **Step 3: Evaluate the acceptance thresholds**

Calculate build/raster p95, frames above one/two observed budgets, diagnostics overhead percentage, authoritative `lagPx`, and metrics gaps above 1.5 observed vsync intervals.

- [ ] **Step 4: Make the predictor decision**

If UI or raster overruns explain the gaps, optimize that measured hot spot and repeat the profile build; do not add prediction. If profile frames remain in budget while metrics gaps persist, start a new TDD cycle for a predictor limited to one observed vsync and clamped to `[0, openKeyboardLift]`.

- [ ] **Step 5: If required, verify predictor RED/GREEN**

Tests must cover opening, closing, deceleration, zero endpoint, open endpoint, one-vsync timeout, and authoritative correction within one logical pixel. Rebuild online and repeat the physical profile capture.

- [ ] **Step 6: Complete the acceptance checklist honestly**

Set KT-026 through KT-031 to `DONE` only when code tests and physical profile evidence satisfy every stated condition. Commit the final checklist/report updates and push the branch.
