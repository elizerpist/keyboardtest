import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lab host disables upstream telemetry and raw diagnostics', () {
    final app = File(
      'third_party/widgets-anywhere/app/src/main/java/tk/zwander/lockscreenwidgets/App.kt',
    ).readAsStringSync();
    final log = File(
      'third_party/widgets-anywhere/app/src/main/java/tk/zwander/common/util/LogUtils.kt',
    ).readAsStringSync();
    final manifest = File(
      'third_party/widgets-anywhere/app/src/profile/AndroidManifest.xml',
    ).readAsStringSync();
    expect(app, contains('!BuildConfig.WA_LAB && prefManager.enableBugsnag'));
    expect(log, contains('!BuildConfig.WA_LAB'));
    expect(manifest, contains('com.bugsnag.android.API_KEY'));
    expect(manifest, contains('tools:node="remove"'));
  });
}
