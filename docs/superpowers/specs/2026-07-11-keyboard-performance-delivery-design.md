# Keyboard Performance And Direct APK Delivery Design

## Goal

Produce a measurably well-performing `keyboardtest` app whose sheet and floating text pill follow the Android IME consistently, then publish the profile APK as a directly downloadable GitHub Release asset and copy that APK to `/storage/emulated/0/Download/keyboardtest`.

## Current Evidence

The existing shared transform keeps the sheet and pill synchronized with every inset value that Flutter renders: captured logs report `lagPx=0.0`, and the sheet subtree remains at `sheetBuild=1`. The visible discontinuities coincide with 30–40 ms motion sample intervals and larger inset deltas. The current `bridgedGap=true` state is diagnostic only because `bridgeMs=0`; it does not synthesize missing intermediate positions.

The current performance probe also cannot be treated as authoritative:

- the online workflow builds a debug APK, whose JIT and assertion overhead distort performance;
- it defines `totalMs` as `buildDuration + rasterDuration`, although Flutter pipelines those stages;
- it uses fixed 16.7 ms and 24 ms thresholds without reading the display refresh rate;
- it timestamps post-frame log work rather than separately recording metrics arrival, UI processing, and raster completion;
- it allocates formatted strings for every motion sample even while the console is closed.

## Architecture

### Motion path

`KeyboardMotionLayer` remains the single owner of the transform shared by `SlideUpKeyboardSheet` and `FloatingKeyboardPill`. The received IME target is still applied directly so closing motion is not deliberately placed one sample behind the keyboard.

The moving visual subtree becomes a stable child. Only a small transform owner reacts to inset changes; the sheet, pill, shadows, and text field are not reconstructed for each metrics notification. Repaint boundaries remain around the reusable visual content.

No new Android `setWindowInsetsAnimationCallback` is installed. Flutter 3.41 already owns that callback on Android API 30 and newer, so replacing it would risk disabling the engine's IME synchronization.

### Performance diagnostics

Diagnostics use monotonic timestamps and a bounded structured ring buffer. Hot-path collection stores numeric samples and flags only. Formatting the complete readable report happens only when the user opens or copies the debug report.

Each motion record separates:

1. native metrics arrival observed by `WidgetsBindingObserver.didChangeMetrics`;
2. transform build/application time;
3. completed Flutter frame timing.

Frame records expose `buildDuration`, `rasterDuration`, `totalSpan`, and `vsyncOverhead`. The active frame budget is calculated from `FlutterView.display.refreshRate`, with the observed vsync-start delta also retained so dynamic refresh-rate behavior can be distinguished from application jank.

The probe can be disabled for an A/B run. The app must be measured once with diagnostics disabled and once with collection enabled while the debug dialog remains closed.

### Conditional gap fallback

Direct target synchronization remains the default. A visual predictor is not added merely because debug-mode logs contained gaps.

If the profile build still demonstrates metrics gaps exceeding 1.5 observed vsync intervals while the Flutter UI and raster durations stay within budget, a bounded predictor may continue the last measured IME velocity for at most one observed vsync. It must be clamped between the last received position and the known endpoint, must never overshoot zero or the open keyboard height, and must snap to an arriving authoritative inset when the error is at most one logical pixel. The predictor is disabled immediately at settled endpoints.

This conditional rule avoids reintroducing the fixed catch-up animation that previously made keyboard closing visibly lag behind Android.

## Profile Performance Acceptance

Performance verification runs on the physical Android device using the online-built profile APK. The debug dialog stays closed during measurement.

After one discarded warmup cycle, ten keyboard open/close cycles are captured. A run is accepted when:

- the sheet and pill use the same transform and every authoritative sample has absolute `lagPx <= 1.0` logical pixel;
- UI `buildDuration` p95 is no greater than one observed frame budget;
- `rasterDuration` p95 is no greater than one observed frame budget;
- no steady-state UI or raster frame exceeds two observed frame budgets;
- enabling lightweight collection does not worsen UI or raster p95 by more than 10% compared with diagnostics disabled;
- the report identifies any remaining metrics gaps separately from application frame overruns.

The first sheet/text-input warmup frames are reported separately and are not counted in the ten-cycle steady-state result.

## Online Build And Direct Download

GitHub Actions continues to run `flutter analyze` and `flutter test`, then executes `flutter build apk --profile`. The resulting APK is renamed to `keyboardtest-<short-sha>-profile.apk`.

The workflow creates a commit-specific GitHub Release tag `keyboardtest-<short-sha>` and uploads the `.apk` directly as a Release asset. It does not upload the APK through `actions/upload-artifact`, so the delivered URL addresses the APK itself rather than a ZIP archive.

The expected URL shape is:

`https://github.com/elizerpist/keyboardtest/releases/download/keyboardtest-<short-sha>/keyboardtest-<short-sha>-profile.apk`

The workflow publishes this URL in its job summary. After the online job succeeds, the same direct URL is used to download the file into `/storage/emulated/0/Download/keyboardtest`. The downloaded filename retains the short commit SHA, and its SHA-256 digest is compared with the release asset downloaded through GitHub CLI metadata.

## Error Handling

- Analysis or test failure prevents the APK build and Release publication.
- APK build failure prevents release creation.
- A release/tag collision for the same commit is handled idempotently by updating the existing commit-specific release asset rather than creating a second release.
- An HTTP response that is not successful, an empty file, or a checksum mismatch prevents the local download from being reported as complete.
- Existing files for other commit SHAs in the Android download directory are preserved.

## Verification

- A repository-level workflow contract test checks for profile build mode, direct Release upload, commit-specific APK naming, job-summary URL publication, and absence of `actions/upload-artifact` for the APK.
- Flutter widget/unit tests cover frame-budget calculation, structured buffer bounds, delayed string formatting, authoritative direct motion, and any conditionally introduced predictor.
- `flutter analyze` and all Flutter tests run through the Ubuntu proot environment.
- GitHub Actions logs, Release metadata, the direct HTTP URL, local APK size, and SHA-256 digest verify delivery.
- Physical-device profile logs verify the performance thresholds above.

## Scope

Included:

- Flutter keyboard motion hot-path and diagnostics optimization;
- profile-mode performance measurement;
- conditional one-vsync prediction only if profile evidence requires it;
- online profile APK build;
- direct GitHub Release APK URL;
- download to Android shared storage.

Excluded:

- replacing Flutter's Android IME animation callback;
- release signing or Play Store publication;
- unrelated sheet features or visual redesign;
- deleting previous APKs or GitHub releases.
