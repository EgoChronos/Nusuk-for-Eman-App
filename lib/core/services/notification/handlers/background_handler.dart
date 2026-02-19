
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../../debug_logger.dart';
import 'dart:convert';

import '../../notification_content_generator.dart';
import '../../../../data/models/notification_content.dart';

/// Top-level function for AndroidAlarmManager callback.
/// Must be static or top-level.
@pragma("vm:entry-point")
void showOverlayCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  await DebugLogger.init(); // Must init in this isolate to write to file
  
  DebugLogger.log('BackgroundHandler: [START] showOverlayCallback triggered with id: $id');
  DebugLogger.log('BackgroundHandler: [START] Isolate active. Waiting 500ms...');

  // Enforce "Notification First" strategy (README: "Floating Overlay: Triggered 100ms later")
  // We use 500ms to be safe given Isolate startup time variance.
  await Future.delayed(const Duration(milliseconds: 500));
  
  DebugLogger.log('BackgroundHandler: [STEP 1] 500ms delay complete. Proceeding...');
  
  // Decode: baseId * 10000 + HHMM
  final int baseId = id ~/ 10000;
  final int hour = (id % 10000) ~/ 100;
  final int minute = id % 100;

  // 1. Handled at top of isolate
  
  // Master Try-Catch to ensure we never crash silently
  try {
    // 2. Initialize Timezones
    try {
      tz_data.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      DebugLogger.log('BackgroundHandler: Timezone init error (non-fatal): $e');
      tz.setLocalLocation(tz.UTC);
    }
  
    DebugLogger.log('BackgroundHandler: Bindings and timezones initialized (BaseId: $baseId)');

    // 3. Initialize Local Notifications (REMOVED: Not needed in isolate)
    
    // 4. Generate Content (using baseId as salt)
    NotificationContent dynamicContent;
    try {
      dynamicContent = await _generateContentForOverlay(baseId);
      DebugLogger.log('BackgroundHandler: Generated content: ${dynamicContent.titleAr}');
    } catch (e) {
      DebugLogger.log('BackgroundHandler: Error generating content: $e');
      dynamicContent = const NotificationContent(
        id: 'fallback_error',
        type: NotificationType.reminder,
        titleAr: 'ذكر الله',
        titleEn: 'Remember Allah',
        bodyAr: 'سبحان الله وبحمده، سبحان الله العظيم',
        bodyEn: 'Glory be to Allah and His is the praise, (and) Allah, the Greatest is free from imperfection.',
        payload: {'target': 'dhikr'},
      );
    }

    // 5. Fallback Notification (REMOVED: Scheduled externally for reliability)
    // We rely on DynamicScheduleProvider to schedule the notification in parallel.
    
    // 6. Shared Data for Overlay
    final data = {
      'id': dynamicContent.id,
      'type': dynamicContent.type.name,
      'titleAr': dynamicContent.titleAr,
      'titleEn': dynamicContent.titleEn,
      'bodyAr': dynamicContent.bodyAr,
      'bodyEn': dynamicContent.bodyEn,
      'sourceLabel': dynamicContent.sourceLabel,
      'payload': dynamicContent.payload,
    };
    
    // 7. Show Overlay
    try {
      DebugLogger.log('BackgroundHandler: [STEP 7] Attempting to show overlay window...');
      final bool isActive = await overlay.FlutterOverlayWindow.isActive();
      final bool isGranted = await overlay.FlutterOverlayWindow.isPermissionGranted();
      DebugLogger.log('BackgroundHandler: Overlay Status -> Active: $isActive, Permission: $isGranted');
      
      if (!isGranted) {
         DebugLogger.log('BackgroundHandler: [ABORT] Permission is NOT granted in background isolate. Cannot show overlay.');
         // We could trigger a fallback here, but DynamicScheduleProvider already scheduled one.
      } else if (!isActive) {
        await overlay.FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: dynamicContent.titleAr,
          overlayContent: dynamicContent.bodyAr,
          flag: overlay.OverlayFlag.defaultFlag,
          alignment: overlay.OverlayAlignment.center,
          visibility: overlay.NotificationVisibility.visibilityPublic,
          positionGravity: overlay.PositionGravity.auto,
          height: overlay.WindowSize.matchParent,
          width: overlay.WindowSize.matchParent,
          startPosition: const overlay.OverlayPosition(0, 0),
        );
        DebugLogger.log('BackgroundHandler: [SUCCESS] showOverlay call completed.');
      } else {
        DebugLogger.log('BackgroundHandler: Overlay already active, skipping showOverlay.');
      }
      
      // NOTE: We intentionally do NOT cancel the standard notification here.
      // The standard notification uses matchDateTimeComponents (repeating daily).
      // Calling fln.cancel() would permanently destroy the repeating schedule,
      // not just dismiss today's instance. The notification banner and overlay
      // are complementary — banner stays in the tray, overlay appears on screen.
      
      // [ROBUSTNESS]: Write to SharedPreferences as backup for shareData
      // Xiaomi often delays Isolate startup by 40+ seconds, missing shareData stream.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('latest_overlay_data', jsonEncode(data));
        DebugLogger.log('BackgroundHandler: Data persisted to SharedPreferences');
      } catch (e) {
        DebugLogger.log('BackgroundHandler: Failed to persist data: $e');
      }
      
      // Send data to listener (Transient)
      await Future.delayed(const Duration(milliseconds: 1500));
      await overlay.FlutterOverlayWindow.shareData(data);
      DebugLogger.log('BackgroundHandler: Data shared with overlay UI');
      
      // Keep isolate alive long enough for Xiaomi's massive startup delay (up to 60s seen in logs)
      await Future.delayed(const Duration(seconds: 60));
    } catch (e) {
      DebugLogger.log('BackgroundHandler: FAILED to show overlay: $e');
    }

    // 8. Self-Rescheduling (Critical for persistence)
    try {
      final now = tz.TZDateTime.now(tz.local);
      var nextInstance = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      
      // If today's time has passed (which it has, since we are running now), schedule for tomorrow
      // Add a small buffer ensuring we don't schedule for "now" if we are late
      if (nextInstance.isBefore(now.add(const Duration(minutes: 1)))) {
        nextInstance = nextInstance.add(const Duration(days: 1));
      }
      
      DebugLogger.log('BackgroundHandler: Rescheduling ID=$id for $nextInstance');
       await AndroidAlarmManager.oneShotAt(
        nextInstance,
        id, // Reuse same ID
        showOverlayCallback,
        exact: true,
        wakeup: true,
        alarmClock: true,
        rescheduleOnReboot: true,
      );
      DebugLogger.log('BackgroundHandler: Reschedule SUCCESS');
    } catch (e) {
       DebugLogger.log('BackgroundHandler: Reschedule FAILED: $e');
    }

  } catch (fatal) {
    DebugLogger.log('BackgroundHandler: FATAL ERROR in isolate: $fatal');
  }
}

/// Static entry point for prayer-specific logic (e.g. Silent Mode, Post-prayer Dhikr)
@pragma("vm:entry-point")
void prayerAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  await DebugLogger.init();
  DebugLogger.log('BackgroundHandler: [PRAYER] prayerAlarmCallback triggered with id: $id');
  
  // Future: Implement "Silent Mode" here if enabled in settings
  // Future: Trigger "Post-Prayer Dhikr" logic
}

// Helper to replicate the mixed content generation from the original service
Future<NotificationContent> _generateContentForOverlay(int salt) async {
  // Simple round-robin or random based on salt
  // 0: Ayah, 1: Hadith, 2: Dhikr/Duaa
  final typeSelector = salt % 3;
  
  if (typeSelector == 0) {
    return await NotificationContentGenerator.getRandomAyah(salt: salt);
  } else if (typeSelector == 1) {
    return NotificationContentGenerator.getRandomHadith(salt: salt);
  } else {
    // Mix Dhikr and Duaa
    if (salt % 2 == 0) {
      return NotificationContentGenerator.getRandomDhikr(salt: salt);
    } else {
      return NotificationContentGenerator.getRandomDuaa(salt: salt);
    }
  }
}
