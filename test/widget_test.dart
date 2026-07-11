import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboardtest/main.dart';

void main() {
  testWidgets('home starts with a FAB and no sheet', (tester) async {
    await tester.pumpWidget(const KeyboardTestApp());

    expect(
      find.byKey(const ValueKey('keyboardtest-open-sheet-fab')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('keyboardtest-slide-sheet')),
      findsNothing,
    );
  });

  testWidgets('FAB opens the slide up sheet with a floating text pill', (
    tester,
  ) async {
    await tester.pumpWidget(const KeyboardTestApp());

    await tester.tap(find.byKey(const ValueKey('keyboardtest-open-sheet-fab')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('keyboardtest-slide-sheet')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('keyboardtest-floating-pill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('keyboardtest-pill-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('keyboardtest-motion-repaint-boundary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('keyboardtest-sheet-repaint-boundary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('keyboardtest-pill-repaint-boundary')),
      findsOneWidget,
    );
  });

  testWidgets(
    'slide up sheet and floating pill follow the same keyboard delta',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewPadding();
        tester.view.resetViewInsets();
      });

      await tester.pumpWidget(const KeyboardTestApp());
      await tester.tap(
        find.byKey(const ValueKey('keyboardtest-open-sheet-fab')),
      );
      await tester.pumpAndSettle();

      final closedSheetTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-slide-sheet')))
          .top;
      final closedPillTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-floating-pill')))
          .top;
      expect(
        find.byKey(const ValueKey('keyboardtest-sheet-backplate')),
        findsNothing,
      );

      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pump();

      final keyboardSheetTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-slide-sheet')))
          .top;
      final keyboardPillTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-floating-pill')))
          .top;

      final sheetDelta = closedSheetTop - keyboardSheetTop;
      final pillDelta = closedPillTop - keyboardPillTop;

      expect(sheetDelta, greaterThan(200));
      expect(sheetDelta, moreOrLessEquals(pillDelta, epsilon: 0.1));
      expect(
        find.byKey(const ValueKey('keyboardtest-sheet-backplate')),
        findsNothing,
      );
    },
  );

  testWidgets('pill returns directly to safe-area dock without bottom bounce', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(const KeyboardTestApp());
    await tester.tap(find.byKey(const ValueKey('keyboardtest-open-sheet-fab')));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();

    final screenHeight = tester.view.physicalSize.height;
    final pillRect = tester.getRect(
      find.byKey(const ValueKey('keyboardtest-floating-pill')),
    );

    expect(screenHeight - pillRect.bottom, 36);
  });

  testWidgets('debug button opens console dialog and copies motion values', (
    tester,
  ) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final arguments = methodCall.arguments as Map<dynamic, dynamic>;
            copiedText = arguments['text'] as String?;
          }
          return null;
        });

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetViewInsets();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(const KeyboardTestApp());

    expect(
      find.byKey(const ValueKey('keyboardtest-debug-panel')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('debug-floating-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('keyboardtest-open-sheet-fab')));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('keyboardtest-pill-field')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('debug-console-dialog')), findsOneWidget);
    expect(find.byKey(const ValueKey('debug-console-copy')), findsOneWidget);
    expect(find.byKey(const ValueKey('debug-console-clear')), findsOneWidget);
    expect(find.byKey(const ValueKey('debug-console-close')), findsOneWidget);
    expect(find.textContaining('raw=260.0'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('debug-console-copy')));
    await tester.pump();

    expect(copiedText, contains('raw=260.0'));
    expect(copiedText, contains('safe=24.0'));
    expect(copiedText, contains('dock=272.0'));
    expect(copiedText, contains('lift=236.0'));
    expect(copiedText, contains('sheet=-236.0'));
    expect(copiedText, contains('pill=272.0'));
    expect(copiedText, contains('seq='));
    expect(copiedText, contains('dtMs='));
    expect(copiedText, contains('rawDelta='));
    expect(copiedText, contains('velocity='));
    expect(copiedText, contains('droppedLike='));
    expect(copiedText, contains('builds motion='));
    expect(copiedText, contains('frameProbe buildMs='));
    expect(copiedText, contains('rasterMs='));
    expect(copiedText, contains('totalMs='));
    expect(copiedText, contains('over16ms='));
    expect(copiedText, contains('over33ms='));
    expect(copiedText, contains('focus active=true'));
  });
}
