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

  testWidgets('floating pill follows keyboard inset while sheet stays fixed', (
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

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pump();

    final keyboardSheetTop = tester
        .getRect(find.byKey(const ValueKey('keyboardtest-slide-sheet')))
        .top;
    final keyboardPillTop = tester
        .getRect(find.byKey(const ValueKey('keyboardtest-floating-pill')))
        .top;

    expect(keyboardSheetTop, closedSheetTop);
    expect(keyboardPillTop, lessThan(closedPillTop - 200));
  });
}
