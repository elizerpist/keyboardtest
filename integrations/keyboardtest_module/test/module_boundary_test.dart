import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry delegates without adding state owners', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("import 'package:keyboardtest/main.dart'"));
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('MethodChannel')));
    expect(source, isNot(contains('class ')));
  });
}
