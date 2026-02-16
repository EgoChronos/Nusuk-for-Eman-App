import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/sources/hive_storage.dart';
import 'core/providers.dart';
import 'core/intention/intention_provider.dart';
import 'app.dart';

import 'features/floating_content/overlay_screen.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

// Overlay Entry Point
@pragma("vm:entry-point")
void overlayMain() {
  debugPrint('OVERLAY ISOLATE: overlayMain starting...');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('OVERLAY ISOLATE: Bindings initialized.');
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayScreen(),
    ),
  );
  debugPrint('OVERLAY ISOLATE: runApp called.');
}

// ... imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (Keep this as it's fast and essential for reading first_launch flag)
  final storage = HiveStorage();
  await storage.init();

  // Initialize Alarm Manager (Fast enough to keep here, or move if needed)
  await AndroidAlarmManager.initialize();

  // App running with minimal blocking
  runApp(
    ProviderScope(
      overrides: [
        hiveStorageProvider.overrideWithValue(storage),
        // other providers will be initialized in Splash and overridden there or lazily initialized
        intentionProvider.overrideWith((ref) => IntentionNotifier(storage.settingsBox)),
      ],
      child: NusukApp(
        storage: storage,
        isFirstLaunch: storage.isFirstLaunch,
      ),
    ),
  );
}
