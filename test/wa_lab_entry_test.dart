import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboardtest/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('keyboardtest/wa_lab');
  var calls = <String>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return call.method == 'available' ? true : null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'lab entry launches the native setup and hides while sheet is open',
    (tester) async {
      await tester.pumpWidget(const KeyboardTestApp());
      await tester.pumpAndSettle();
      expect(find.text('Zárképernyő teszt'), findsOneWidget);
      await tester.tap(find.text('Zárképernyő teszt'));
      await tester.pump();
      expect(calls, contains('open'));
      await tester.tap(
        find.byKey(const ValueKey('keyboardtest-open-sheet-fab')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zárképernyő teszt'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets('keyboard-only host does not expose lab entry', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => false);
    await tester.pumpWidget(const KeyboardTestApp());
    await tester.pumpAndSettle();
    expect(find.text('Zárképernyő teszt'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
