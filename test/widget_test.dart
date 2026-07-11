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
      await tester.pump(const Duration(milliseconds: 24));

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

  testWidgets('active IME samples are applied in the same frame', (
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

    final closedSheetTop = tester
        .getRect(find.byKey(const ValueKey('keyboardtest-slide-sheet')))
        .top;
    final closedPillTop = tester
        .getRect(find.byKey(const ValueKey('keyboardtest-floating-pill')))
        .top;

    Future<void> expectImmediateLift({
      required double rawInset,
      required double expectedLift,
    }) async {
      tester.view.viewInsets = FakeViewPadding(bottom: rawInset);
      await tester.pump();

      final sheetTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-slide-sheet')))
          .top;
      final pillTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-floating-pill')))
          .top;

      expect(
        closedSheetTop - sheetTop,
        moreOrLessEquals(expectedLift, epsilon: 0.1),
      );
      expect(
        closedPillTop - pillTop,
        moreOrLessEquals(expectedLift, epsilon: 0.1),
      );
    }

    await expectImmediateLift(rawInset: 332, expectedLift: 308);
    await expectImmediateLift(rawInset: 140, expectedLift: 116);
    await expectImmediateLift(rawInset: 48, expectedLift: 24);
  });

  testWidgets('text input is prewarmed before first pill focus', (
    tester,
  ) async {
    await tester.pumpWidget(const KeyboardTestApp());
    await tester.pump();
    DebugConsole.clear();

    await tester.tap(find.byKey(const ValueKey('keyboardtest-open-sheet-fab')));
    await tester.pumpAndSettle();

    final logText = DebugConsole.allText;
    expect(logText, contains('text input prewarm ready=true'));
    expect(logText, isNot(contains('focus active=true')));
  });

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
    await tester.pump(const Duration(milliseconds: 24));

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
    await tester.pump(const Duration(milliseconds: 24));
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
    expect(copiedText, contains('targetLift=236.0'));
    expect(copiedText, contains('visualLift=236.0'));
    expect(copiedText, contains('lagPx=0.0'));
    expect(copiedText, contains('source='));
    expect(copiedText, contains('bridgeMs='));
    expect(copiedText, contains('bridgedGap='));
    expect(copiedText, contains('seq='));
    expect(copiedText, contains('dtMs='));
    expect(copiedText, contains('rawDelta='));
    expect(copiedText, contains('velocity='));
    expect(copiedText, contains('droppedLike='));
    expect(copiedText, contains('idleGap='));
    expect(copiedText, contains('sampleGap='));
    expect(copiedText, contains('activeMotion='));
    expect(copiedText, contains('motionPhase='));
    expect(copiedText, contains('builds motion='));
    expect(copiedText, contains('frameProbe buildMs='));
    expect(copiedText, contains('rateLimitMs=250'));
    expect(copiedText, contains('suppressed='));
    expect(copiedText, contains('worstTotalMs='));
    expect(copiedText, contains('debugOpen='));
    expect(copiedText, contains('warmupFrame='));
    expect(copiedText, contains('rasterMs='));
    expect(copiedText, contains('totalMs='));
    expect(copiedText, contains('over16ms='));
    expect(copiedText, contains('over33ms='));
    expect(copiedText, contains('focus active=true'));
    expect(copiedText, contains('PerformanceSummary'));
    expect(copiedText, contains('frameCount='));
    expect(copiedText, contains('p95BuildMs='));
  });

  testWidgets('debug notifier does not request frames by itself', (
    tester,
  ) async {
    await tester.pumpWidget(const KeyboardTestApp());
    await tester.pumpAndSettle();
    DebugConsole.clear();
    await tester.pump();

    var notifications = 0;
    void listener() => notifications += 1;

    DebugConsole.notifier.addListener(listener);
    addTearDown(() {
      DebugConsole.notifier.removeListener(listener);
      DebugConsole.clear();
    });

    expect(tester.binding.hasScheduledFrame, isFalse);

    DebugConsole.log('notify probe');

    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pump();
    await tester.pump();
    expect(notifications, 1);
  });

  testWidgets(
    'detailed collection gates motion and toggling schedules no frame',
    (tester) async {
      await tester.pumpWidget(const KeyboardTestApp());
      await tester.pumpAndSettle();
      DebugConsole.clear();
      DebugConsole.setDetailedCollectionEnabled(false);
      addTearDown(() {
        DebugConsole.setDetailedCollectionEnabled(true);
        DebugConsole.clear();
      });

      const sampleMetrics = KeyboardMotionMetrics(
        rawInset: 260,
        safeBottom: 24,
        spacing: 12,
      );

      DebugConsole.log('ordinary text');
      DebugConsole.logMotion(sampleMetrics);

      expect(DebugConsole.allText, contains('ordinary text'));
      expect(DebugConsole.allText, isNot(contains('raw=260.0')));
      expect(tester.binding.hasScheduledFrame, isFalse);

      DebugConsole.setDetailedCollectionEnabled(true);

      expect(DebugConsole.detailedCollectionEnabled, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);

      DebugConsole.logMotion(sampleMetrics);

      expect(DebugConsole.allText, contains('raw=260.0'));
    },
  );

  testWidgets('debug dialog exposes a focus-neutral collection switch', (
    tester,
  ) async {
    DebugConsole.setDetailedCollectionEnabled(false);
    addTearDown(() => DebugConsole.setDetailedCollectionEnabled(true));

    await tester.pumpWidget(const KeyboardTestApp());
    await tester.tap(find.byKey(const ValueKey('keyboardtest-open-sheet-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(
      const ValueKey('debug-detailed-collection-switch'),
    );
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);

    final focusBeforeToggle = FocusManager.instance.primaryFocus;
    final sheetRectBeforeToggle = tester.getRect(
      find.byKey(const ValueKey('keyboardtest-slide-sheet')),
    );

    await tester.tap(switchFinder);
    await tester.pump();

    expect(DebugConsole.detailedCollectionEnabled, isTrue);
    expect(FocusManager.instance.primaryFocus, same(focusBeforeToggle));
    expect(
      tester.getRect(find.byKey(const ValueKey('keyboardtest-slide-sheet'))),
      sheetRectBeforeToggle,
    );
  });

  testWidgets('debug console renders a tail but copies the full log', (
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
    addTearDown(() {
      DebugConsole.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(const KeyboardTestApp());
    await tester.pumpAndSettle();
    DebugConsole.clear();

    for (var index = 1; index <= 120; index += 1) {
      DebugConsole.log('debug-line-${index.toString().padLeft(3, '0')}');
    }

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('debug-console-dialog')),
        matching: find.byType(TextField),
      ),
      findsNothing,
    );

    final text = tester.widget<Text>(
      find.byKey(const ValueKey('debug-console-text')),
    );
    final visibleText = text.data ?? '';

    expect(visibleText, isNot(contains('debug-line-001')));
    expect(visibleText, contains('debug-line-120'));

    await tester.tap(find.byKey(const ValueKey('debug-console-copy')));
    await tester.pump();

    expect(copiedText, contains('debug-line-001'));
    expect(copiedText, contains('debug-line-120'));
  });
}
