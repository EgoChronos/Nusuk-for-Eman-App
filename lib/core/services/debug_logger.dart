import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DebugLogger {
  static File? _logFile;

  static Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/app_debug.log');
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }
      log('DebugLogger initialized at ${_logFile!.path}');
    } catch (e) {
      debugPrint('Failed to initialize logger: $e');
    }
  }

  static void log(String message) {
    debugPrint(message); // Always print to console
    if (_logFile != null) {
      final timestamp = DateTime.now().toIso8601String();
      try {
        _logFile!.writeAsStringSync('[$timestamp] $message\n', mode: FileMode.append);
      } catch (e) {
        debugPrint('Failed to write to log file: $e');
      }
    }
  }

  static Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString('');
      log('Logs cleared.');
    }
  }

  static Future<void> shareLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      final params = ShareParams(
        files: [XFile(_logFile!.path)],
        text: 'Eman App Debug Logs',
      );
      await SharePlus.instance.share(params);
    } else {
      log('No log file to share.');
    }
  }
}
