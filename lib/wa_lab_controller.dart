import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WaLabController extends ChangeNotifier {
  static const _channel = MethodChannel('keyboardtest/wa_lab');
  bool available = false;
  bool _disposed = false;

  Future<void> load() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final result = await _channel.invokeMethod<bool>('available') ?? false;
      if (!_disposed) {
        available = result;
        notifyListeners();
      }
    } on MissingPluginException {
      // The standard keyboard-only build has no lab host.
    } on PlatformException {
      // Keep the entry hidden when the host cannot report capability.
    }
  }

  Future<void> open() async {
    try {
      await _channel.invokeMethod<void>('open');
    } on MissingPluginException {
      // The host can disappear while the application is running.
    } on PlatformException {
      // Leave the keyboard screen usable if launching setup fails.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
