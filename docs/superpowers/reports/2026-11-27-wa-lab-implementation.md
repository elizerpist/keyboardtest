# KWA-D1 implementation checkpoint

The integrated application uses the Widgets Anywhere host imported from upstream commit `e377ce98abe1addd496c03b169a1ab6d419986d7`. The separate pristine import commit is `e70b278d485a6b05b2d539c0d39e3278584a5ffb`; its vendor tree has 577 files and tree ID `2575893b5356b7f4badf57d01643d07b5872293d`.

The lab profile embeds the existing keyboard Flutter module in the native WA application, with its own package identity, setup screen, app widget provider and opt-in diagnostics. Widget binding keeps the ID allocated before Android consent, and cancellation cleans only the pending ID. The WA frame remains responsible for positioning and visibility. The optional wallpaper companion has a distinct lab package and shared lab signature permission.

Ubuntu proot `flutter test` passed 40 tests, including the keyboard regressions and focused consent, drag, bounds and buffer checks. These are not Android keyguard tests. The workflow builds the actual native host using Android 17 and NDK 29, verifies signed package identity and contents, publishes an immutable SHA-tagged APK, and attempts an API 37 emulator installation and launch. Check the exact Actions run for actual build, signer and fixture results; a source test is not evidence of a real widget or keyguard interaction.

Real consent, host rendering, lock-screen gesture, wake timing, OEM behavior and the Nothing Phone (2a) acceptance remain unverified until measured. No physical result is claimed here. The application source SHA is embedded during CI and displayed in the setup screen and diagnostics.
