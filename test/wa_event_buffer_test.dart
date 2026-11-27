import 'package:flutter_test/flutter_test.dart';
import 'support/java_contract.dart';

void main() {
  test('diagnostic snapshot is bounded and frozen', () async {
    await runJavaContract(
      'third_party/widgets-anywhere/app/src/main/java/tk/zwander/lockscreenwidgets/lab/LabEventBuffer.java',
      'test/native/LabEventBufferTest.java',
      'LabEventBufferTest',
    );
  });
}
