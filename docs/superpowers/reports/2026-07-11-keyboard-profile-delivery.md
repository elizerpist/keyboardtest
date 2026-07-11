# Keyboard Profile APK Delivery Evidence

## Source

- Branch: `feat/profile-keyboard-performance`
- Commit: `b610a6a96a73ff4f94f670e3869fbe99fa0fba05`
- GitHub Actions run: `29153985580`
- Job: `Build profile APK`
- Job conclusion: `success`
- Duration: 3 minutes 20 seconds

## Direct Release Asset

- Release tag: `keyboardtest-b610a6a`
- Asset: `keyboardtest-b610a6a-profile.apk`
- Content type: `application/vnd.android.package-archive`
- Size: `64,391,861` bytes
- Direct URL: `https://github.com/elizerpist/keyboardtest/releases/download/keyboardtest-b610a6a/keyboardtest-b610a6a-profile.apk`
- GitHub digest: `sha256:29b6c47855e32e5472191aa25d01aea2b1f0d51127eb694d10ec4471e8008593`

The workflow did not publish an Actions artifact. The URL above addresses the APK Release asset directly.

## Android Shared Storage

- Path: `/storage/emulated/0/Download/keyboardtest/keyboardtest-b610a6a-profile.apk`
- Detected type: Android package (APK), with Gradle `app-metadata.properties`
- Size: `64,391,861` bytes
- SHA-256: `29b6c47855e32e5472191aa25d01aea2b1f0d51127eb694d10ec4471e8008593`

The downloaded file matches the SHA-256 digest published by GitHub Release metadata. The requested shared-storage APK remains in place.

## Remaining Performance Gate

This delivery proves the profile build and direct APK distribution requirements. It does not replace the physical-device acceptance run. KT-027 through KT-029 remain `PARTIAL`, and KT-030 through KT-031 remain `NOT DONE`, until the installed profile APK completes the specified warmup plus ten keyboard open/close cycles with detailed collection disabled and enabled.
