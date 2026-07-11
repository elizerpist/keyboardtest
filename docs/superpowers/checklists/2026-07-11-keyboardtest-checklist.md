# Keyboardtest Acceptance Checklist

| ID | Source instruction | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| KT-001 | User: create new repo named `keyboardtest` from local `flutteetest`; save beside `exptv2` | Project root | Project exists at `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/keyboardtest` with package/repo identity updated to `keyboardtest`. | Direct file inspection of path, `pubspec.yaml`, Android namespace/applicationId, and git remote. | DONE |
| KT-002 | User: empty Flutter app with a FAB button | `lib/main.dart` | Initial screen is a minimal app with one FAB that opens the test sheet. | Flutter widget test verifies FAB exists before opening. | DONE |
| KT-003 | User: FAB opens a slide up sheet | `lib/main.dart` | Tapping the FAB reveals a bottom slide-up sheet. | Flutter widget test taps FAB and finds the sheet. | DONE |
| KT-004 | User: sheet contains a text pill above the safety zone | `lib/main.dart` | The sheet has a bottom text-entry pill positioned above the bottom safe area when the keyboard is closed. | Flutter widget test inspects pill and sheet widgets. | DONE |
| KT-005 | User: keyboard slides up and the pill follows; pill is a separate component | `lib/main.dart` | The pill is implemented as its own floating component and changes vertical position from `MediaQuery.viewInsets.bottom`; the sheet body is not moved by the keyboard. | Flutter widget test pumps fake viewInsets and verifies the pill moves while the sheet remains present. | DONE |
| KT-006 | User: upload to GitHub as `keyboardtest` | Git/GitHub | GitHub repo `elizerpist/keyboardtest` exists and main branch contains the implementation commit. | `gh repo view elizerpist/keyboardtest` and `git status`. | NOT DONE |
| KT-007 | User: build online; build name includes commit name | `.github/workflows/android-build.yml` | GitHub Actions builds debug APK and uploads an artifact whose name includes the short commit SHA. | `gh run` inspection and artifact name. | PARTIAL |
| KT-008 | User: download to Android `/emulated/0/download/keyboardtest`; folder does not exist yet | Android shared storage | The built APK artifact is downloaded and copied under `/storage/emulated/0/Download/keyboardtest`. | `ls -la /storage/emulated/0/Download/keyboardtest`. | NOT DONE |
