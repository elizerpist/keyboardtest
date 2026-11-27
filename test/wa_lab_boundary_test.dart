import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lab controller owns capability and launch without UI or storage', () {
    final source = File('lib/wa_lab_controller.dart').readAsStringSync();
    for (final forbidden in [
      'package:flutter/material.dart',
      'package:flutter/widgets.dart',
      'BuildContext',
      'dart:io',
      'SharedPreferences',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
    expect(source, contains('MethodChannel'));
    expect(source, contains('available'));
  });
  test('keyboard screen does not own the lab platform channel', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, isNot(contains("MethodChannel('keyboardtest/wa_lab')")));
    expect(source, contains('WaLabController'));
  });
}
