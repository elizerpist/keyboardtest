import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workflow publishes a direct profile APK release asset', () {
    final yaml = File('.github/workflows/android-build.yml').readAsStringSync();
    expect(yaml, contains('flutter build apk --profile'));
    expect(yaml, contains('permissions:'));
    expect(yaml, contains('contents: write'));
    expect(yaml, contains('gh release upload'));
    expect(yaml, contains('gh release create'));
    expect(
      yaml,
      contains(r'keyboardtest-${{ steps.vars.outputs.short_sha }}-profile.apk'),
    );
    expect(yaml, contains(r'$GITHUB_STEP_SUMMARY'));
    expect(yaml, isNot(contains('actions/upload-artifact')));
  });
}
