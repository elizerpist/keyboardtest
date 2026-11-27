import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

Future<void> runJavaContract(
  String source,
  String test,
  String className,
) async {
  final directory = await Directory.systemTemp.createTemp('wa-contract-');
  try {
    final compile = await Process.run('javac', [
      '-d',
      directory.path,
      source,
      test,
    ]);
    expect(compile.exitCode, 0, reason: '${compile.stdout} ${compile.stderr}');
    final result = await Process.run('java', [
      '-cp',
      directory.path,
      className,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout} ${result.stderr}');
  } finally {
    await directory.delete(recursive: true);
  }
}
