import 'package:flutter/services.dart';

class ForegroundLauncher {
  static const MethodChannel _channel = MethodChannel('com.noor.foreground_launcher');

  /// Brings the application to the foreground.
  /// 
  /// This works by using the Android ApplicationContext to start the main activity
  /// with Intent flags that force it to wake up even from background isolates.
  static Future<bool> bringToForeground() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('bringToForeground');
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
