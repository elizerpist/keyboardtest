import 'package:flutter_test/flutter_test.dart';
import 'support/java_contract.dart';

void main() {
  test('long press drag commits only an uninterrupted single pointer', () async {
    await runJavaContract(
      'third_party/widgets-anywhere/app/src/main/java/tk/zwander/lockscreenwidgets/lab/LabDragState.java',
      'test/native/LabDragStateTest.java',
      'LabDragStateTest',
    );
  });
  test('frame bounds include insets and the whole rectangle', () async {
    await runJavaContract(
      'third_party/widgets-anywhere/app/src/main/java/tk/zwander/lockscreenwidgets/lab/LabFrameBounds.java',
      'test/native/LabFrameBoundsTest.java',
      'LabFrameBoundsTest',
    );
  });
}
