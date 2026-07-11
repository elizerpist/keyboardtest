# Keyboard Profile APK Delivery Evidence

## Source

- Branch: `feat/profile-keyboard-performance`
- Commit: `513c3368865fb254afc1c4b7c213f653d56e1b2a`
- GitHub Actions run: `29153287157`
- Job: `Build profile APK`
- Job conclusion: `success`
- Duration: 3 minutes 20 seconds

## Direct Release Asset

- Release tag: `keyboardtest-513c336`
- Asset: `keyboardtest-513c336-profile.apk`
- Content type: `application/vnd.android.package-archive`
- Size: `64,391,861` bytes
- Direct URL: `https://github.com/elizerpist/keyboardtest/releases/download/keyboardtest-513c336/keyboardtest-513c336-profile.apk`
- GitHub digest: `sha256:187e66900bed28ed4ddd267f637fbda14cf3b46c1d526471f01c2eb00d0b3611`

The workflow did not publish an Actions artifact. The URL above addresses the APK Release asset directly.

## Android Shared Storage

- Path: `/storage/emulated/0/Download/keyboardtest/keyboardtest-513c336-profile.apk`
- Detected type: Android package (APK), with Gradle `app-metadata.properties`
- Size: `64,391,861` bytes
- SHA-256: `187e66900bed28ed4ddd267f637fbda14cf3b46c1d526471f01c2eb00d0b3611`

A second copy retrieved through `gh release download` had the same size and SHA-256. The temporary comparison copy was deleted after verification; the requested shared-storage APK remains in place.

## Remaining Performance Gate

This delivery proves the profile build and direct APK distribution requirements. It does not replace the physical-device acceptance run. KT-027 through KT-029 remain `PARTIAL`, and KT-030 through KT-031 remain `NOT DONE`, until the installed profile APK completes the specified warmup plus ten keyboard open/close cycles with detailed collection disabled and enabled.
