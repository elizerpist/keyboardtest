import 'package:flutter/material.dart';
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
  });

  testWidgets(
    'sheet backplate and floating pill follow the same keyboard delta',
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
      final closedBackplateTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-sheet-backplate')))
          .top;
      final closedPillTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-floating-pill')))
          .top;

      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pump();

      final keyboardSheetTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-slide-sheet')))
          .top;
      final keyboardBackplateTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-sheet-backplate')))
          .top;
      final keyboardPillTop = tester
          .getRect(find.byKey(const ValueKey('keyboardtest-floating-pill')))
          .top;

      final backplateDelta = closedBackplateTop - keyboardBackplateTop;
      final pillDelta = closedPillTop - keyboardPillTop;

      expect(keyboardSheetTop, closedSheetTop);
      expect(backplateDelta, greaterThan(200));
      expect(backplateDelta, moreOrLessEquals(pillDelta, epsilon: 0.1));
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

  testWidgets('debug panel shows current keyboard motion values', (
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

    final debugPanel = find.byKey(const ValueKey('keyboardtest-debug-panel'));
    expect(debugPanel, findsOneWidget);
    expect(find.textContaining('raw=260.0'), findsOneWidget);
    expect(find.textContaining('safe=24.0'), findsOneWidget);
    expect(find.textContaining('dock=272.0'), findsOneWidget);
    expect(find.textContaining('lift=236.0'), findsOneWidget);
    expect(find.textContaining('sheet=-236.0'), findsOneWidget);
    expect(find.textContaining('pill=272.0'), findsOneWidget);
  });
}
