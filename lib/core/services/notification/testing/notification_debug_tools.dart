
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../handlers/background_handler.dart';
import '../scheduling/schedule_manager.dart';
import '../display/notification_display.dart';
import '../managers/permission_manager.dart';
import '../managers/channel_manager.dart';
import '../../../../data/models/notification_content.dart';


class NotificationDebugTools {
  final ScheduleManager _scheduleManager;
  final NotificationDisplay _display;
  final PermissionManager _permissionManager;

  NotificationDebugTools(
    this._scheduleManager,
    this._display,
    this._permissionManager,
  );

  /// TEST: Trigger an immediate standard notification
  Future<void> testNotification() async {
    debugPrint('NotificationDebugTools: Triggering TEST notification...');
    final content = NotificationContent(
      id: '999',
      type: NotificationType.reminder,
      titleAr: 'اختبار التنبيهات 🔔',
      bodyAr: 'هذا تنبيه تجريبي للتأكد من وصول الإشعارات بشكل سليم.',
      titleEn: 'Notification Test 🔔',
      bodyEn: 'This is a test notification to ensure reminders are working.',
    );

    await _display.show(
      id: 999,
      content: content,
      channelId: ChannelManager.channelRemindersId,
    );
  }

  /// TEST: Trigger an immediate floating overlay (or fallback)
  Future<void> testFloatingOverlay() async {
    debugPrint('NotificationDebugTools: Triggering TEST floating overlay in 20 seconds...');
    final hasPermission = await _permissionManager.isOverlayPermissionGranted();
    
    if (hasPermission) {
      final now = tz.TZDateTime.now(tz.local);
      final testTime = now.add(const Duration(seconds: 20));
      
      // Use test ID 998 and encoded ID for isolation
      final int id = 998;
      final int encodedId = (id * 10000) + (testTime.hour * 100) + testTime.minute;

      await _scheduleManager.scheduleOneShot(
        time: testTime,
        id: encodedId,
        callback: showOverlayCallback,
        alarmClock: true,
        wakeup: true,
      );
      debugPrint('SUCCESS: Scheduled TEST overlay in 20 seconds at $testTime');
    } else {
      debugPrint('FALLBACK: Overlay permission missing for TEST. Using standard notification.');
      await testNotification();
    }
  }

  /// TEST: Trigger a normal notification in 20 seconds (Background Test)
  Future<void> testDelayedNotification() async {
    debugPrint('NotificationDebugTools: Triggering TEST delayed alert in 20 seconds...');
    
    final now = tz.TZDateTime.now(tz.local);
    final testTime = now.add(const Duration(seconds: 20));
    
    final content = NotificationContent(
      id: '997',
      type: NotificationType.reminder,
      titleAr: 'تنبيه تجريبي (خلفية) 🔔',
      bodyAr: 'هذا التنبيه ظهر بعد إغلاق التطبيق للتأكد من استمرارية الخدمة.',
      titleEn: 'Delayed Test Alert 🔔',
      bodyEn: 'This notification appeared after closing the app to ensure service persistence.',
    );

    await _display.schedule(
      id: 997,
      content: content,
      scheduledTime: testTime,
      channelId: ChannelManager.channelRemindersId,
      matchDateTimeComponents: null, // One-time
    );
    debugPrint('SUCCESS: Scheduled TEST delayed alert in 20 seconds at $testTime');
  }

  /// TEST: Trigger a prayer notification in 10 seconds with custom sound
  Future<void> testAthanNotification(String? sound) async {
    debugPrint('NotificationDebugTools: Triggering TEST Athan in 10 seconds...');
    
    final now = tz.TZDateTime.now(tz.local);
    final testTime = now.add(const Duration(seconds: 10));
    
    final content = NotificationContent(
      id: '996',
      type: NotificationType.reminder,
      titleAr: 'اختبار الأذان 🕌',
      bodyAr: 'حي على الصلاة.. حي على الفلاح',
      titleEn: 'Athan Test 🕌',
      bodyEn: 'Hasten to prayer, hasten to success',
    );

    await _display.schedule(
      id: 996,
      content: content,
      scheduledTime: testTime,
      channelId: ChannelManager.getPrayerChannelId(sound),
      matchDateTimeComponents: null,
      sound: sound == 'default' ? null : sound,
    );
    debugPrint('SUCCESS: Scheduled TEST Athan in 10 seconds with sound: $sound');
  }
  /// TEST: Audit all pending schedules
  Future<void> auditSchedule() async {
    debugPrint('\n--- NOTIFICATION AUDIT START ---');
    
    // 1. Check Standard Notifications
    final pending = await _display.getPendingRequest();
    debugPrint('PENDING STANDARD NOTIFICATIONS (${pending.length}):');
    if (pending.isEmpty) {
      debugPrint('  [NONE]');
    } else {
      for (final p in pending) {
        debugPrint('  - ID: ${p.id}, Title: ${p.title}, Body: ${p.body}, Payload: ${p.payload}');
      }
    }

    // 2. Check Alarm Manager (Cannot list directly, but we can verify logic)
    debugPrint('PENDING ALARMS (Cannot list directly via Android API):');
    debugPrint('  - If "Standard Notifications" above shows items for future times,');
    debugPrint('    then the Dual-Layer strategy means Alarms are also set (if permission granted).');
    
    debugPrint('--- NOTIFICATION AUDIT END ---\n');
  }
}
