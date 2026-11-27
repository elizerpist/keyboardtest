import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lab variant supplies the native host entry and real widget provider', () {
    final manifest = File(
      'third_party/widgets-anywhere/app/src/profile/AndroidManifest.xml',
    );
    expect(
      manifest.existsSync(),
      isTrue,
      reason: 'lab profile manifest missing',
    );
    final xml = manifest.readAsStringSync();
    expect(xml, contains('KeyboardLabActivity'));
    expect(xml, contains('LabWidgetProvider'));
    expect(xml, contains('android.permission.BIND_APPWIDGET'));
    expect(xml, contains('android.intent.category.LAUNCHER'));
    expect(
      File(
        'third_party/widgets-anywhere/app/src/profile/java/tk/zwander/lockscreenwidgets/lab/KeyboardLabActivity.kt',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'third_party/widgets-anywhere/app/src/profile/java/tk/zwander/lockscreenwidgets/lab/LabWidgetProvider.kt',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'third_party/widgets-anywhere/app/src/profile/java/tk/zwander/lockscreenwidgets/lab/LabSetupActivity.kt',
      ).existsSync(),
      isTrue,
    );
    final gradle = File(
      'third_party/widgets-anywhere/app/build.gradle.kts',
    ).readAsStringSync();
    expect(gradle, contains('com.example.keyboardtest.walab'));
    expect(gradle, contains('flutter_profile'));
  });
  test(
    'live lab pointer stream bypasses WA multi-finger and double-tap actions',
    () {
      final frame = File(
        'third_party/widgets-anywhere/app/src/main/java/tk/zwander/lockscreenwidgets/compose/WidgetFrameLayout.kt',
      ).readAsStringSync();
      expect(frame, contains('.pointerInput(liveLab)'));
      expect(frame, contains('if (!liveLab) {'));
      expect(
        frame,
        contains('doubleTapTurnOffDisplay && !firstViewing && !liveLab'),
      );
      final delegate = File(
        'third_party/widgets-anywhere/app/src/main/java/tk/zwander/lockscreenwidgets/util/WidgetFrameDelegate.kt',
      ).readAsStringSync();
      expect(delegate, contains('!isPreview && !isDefaultDisplay'));
    },
  );
  test('lab companion uses a separate package and signature permission', () {
    final library = File(
      'third_party/widgets-anywhere/lswinterconnect/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final companion = File(
      'third_party/widgets-anywhere/lswwallpaper/build.gradle.kts',
    ).readAsStringSync();
    final client = File(
      'third_party/widgets-anywhere/app/src/main/java/tk/zwander/common/util/WallpaperClient.kt',
    ).readAsStringSync();
    expect(library, contains(r'${wallpaperPermission}'));
    expect(companion, contains('com.example.keyboardtest.walab.wallpaper'));
    expect(client, contains('dev.zwander.lswwallpaper.WallpaperServerService'));
  });
}
