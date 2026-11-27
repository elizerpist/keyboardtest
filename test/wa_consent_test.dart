import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'support/java_contract.dart';

void main() {
  test('pending widget consent retains or cleans only its own ID', () async {
    await runJavaContract(
      'third_party/widgets-anywhere/app/src/main/java/tk/zwander/common/activities/add/WidgetConsentResult.java',
      'test/native/WidgetConsentResultTest.java',
      'WidgetConsentResultTest',
    );
  });

  test('consent callback continues with the already-bound pending ID', () {
    final source = File(
      'third_party/widgets-anywhere/app/src/main/java/tk/zwander/common/activities/add/BaseBindWidgetActivity.kt',
    ).readAsStringSync();
    expect(source, contains('onBoundWidget(info!!, id)'));
    expect(source, contains('onWidgetBindingCancelled(id)'));
  });
}
