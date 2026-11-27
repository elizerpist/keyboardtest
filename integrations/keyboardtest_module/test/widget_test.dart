import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboardtest_module/main.dart' as module;

void main() {
  testWidgets('module launches the existing keyboard experiment', (tester) async {
    module.main();
    await tester.pump();
    expect(find.byKey(const ValueKey('keyboardtest-open-sheet-fab')), findsOneWidget);
  });
}
