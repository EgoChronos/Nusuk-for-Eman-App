import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import '../../../../data/models/notification_content.dart';
import '../../notification_content_generator.dart';
import '../display/notification_display.dart';

import '../managers/channel_manager.dart';
import '../managers/permission_manager.dart';
import '../scheduling/schedule_manager.dart';
import '../notification_registry.dart';
import '../../../../data/sources/hive_storage.dart';
import '../handlers/background_handler.dart';
import '../../debug_logger.dart';

class DynamicScheduleProvider implements NotificationScheduleProvider {
  final NotificationDisplay _notificationDisplay;
  final PermissionManager _permissionManager;

  DynamicScheduleProvider(this._notificationDisplay, this._permissionManager);

  @override
  String get id => 'dynamic_content';

  @override
  Future<void> schedule(ScheduleManager manager, HiveStorage storage) async {
    final settings = storage.getNotificationSettings();
    if (settings['enabled'] == false) return;
    if (settings['floating'] != true) return; // Only schedule if floating/dynamic enabled

    final frequency = settings['frequency'] ?? 'medium';
    final hasOverlayPermission = await _permissionManager.isOverlayPermissionGranted();
    
    DebugLogger.log('DynamicScheduleProvider: Scheduling frequency=$frequency, overlayPermission=$hasOverlayPermission');

    // 1. Get Slots
    List<List<int>> slots = _getSlotsForFrequency(frequency);

    // 2. Schedule regular dynamic slots
    for (int i = 0; i < slots.length; i++) {
        await _scheduleDailyContent(
          manager: manager,
          id: 201 + i,
          hour: slots[i][0],
          minute: slots[i][1],
          salt: 201 + i,
          hasOverlayPermission: hasOverlayPermission,
        );
    }
    
    // 3. Schedule "Fixed" Content that uses Overlay (Duaa for Eman)
    // ID 105: Night Duaa (9:00 PM)
    await _scheduleDailyContent(
      manager: manager,
      id: 105,
      hour: 21,
      minute: 0,
      salt: 105,
      hasOverlayPermission: hasOverlayPermission,
      forceContent: NotificationContentGenerator.getReminder('duaa_eman'),
    );

    // ID 106: Morning Duaa (8:00 AM)
    await _scheduleDailyContent(
      manager: manager,
      id: 106,
      hour: 8,
      minute: 0,
      salt: 106,
      hasOverlayPermission: hasOverlayPermission,
      forceContent: NotificationContentGenerator.getReminder('morning_eman'),
    );
  }

  List<List<int>> _getSlotsForFrequency(String frequency) {
    if (frequency == 'low') {
      return [
        [08, 00], [20, 00],
      ];
    } else if (frequency == 'high') {
      return [
        [07, 00], [08, 30], [10, 00], [11, 30], [13, 00], [14, 30],
        [16, 00], [17, 30], [19, 00], [20, 30], [22, 00], [23, 30],
      ];
    } else {
      // Medium
      return [
        [07, 00], [10, 00], [13, 00], [16, 00], [19, 00],
      ];
    }
  }

  Future<void> _scheduleDailyContent({
    required ScheduleManager manager,
    required int id,
    required int hour,
    required int minute,
    required int salt,
    required bool hasOverlayPermission,
    NotificationContent? forceContent,
  }) async {
    // 1. Cancel existing
    await _notificationDisplay.cancel(id); // Cancel standard notif
    await manager.cancel(id); // Cancel precise alarm
    
    // Encode ID for valid AlarmManager usage: baseId * 10000 + HHMM
    final encodedId = (id * 10000) + (hour * 100) + minute;
    await manager.cancel(encodedId); // Cancel previous encoded instance

    // 2. Schedule
    final scheduledTime = _nextInstanceOfTime(hour, minute);

    // [Reliability Fix]: Always generate content and schedule Notification
    // This ensures that even if the Background Isolate (Overlay) is killed by Xiaomi/Android,
    // the standard notification still persists.
    NotificationContent content;
    if (forceContent != null) {
      content = forceContent;
    } else {
      content = await _generateFallbackContent(salt);
    }
    
    // A. Schedule Standard Notification (The "Floor")
    await _notificationDisplay.schedule(
      id: id,
      content: content,
      scheduledTime: scheduledTime,
      channelId: ChannelManager.channelContentId,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    DebugLogger.log('DynamicScheduleProvider: Scheduled FALLBACK notification at $scheduledTime (id=$id)');

    // B. Schedule Overlay (The "Ceiling") if permitted
    if (hasOverlayPermission) {
      await manager.scheduleOneShot(
        time: scheduledTime.add(const Duration(seconds: 5)), // Delay by 5s to allow Standard Notification to wake screen/CPU
        id: encodedId,
        callback: showOverlayCallback, // Top-level callback in handlers/background_handler.dart
        alarmClock: true, 
        wakeup: true,
        rescheduleOnReboot: true,
      );
      DebugLogger.log('DynamicScheduleProvider: Scheduled OVERLAY at $scheduledTime (id=$encodedId)');
    }
  }
  
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      DebugLogger.log('DynamicScheduleProvider: Target $hour:$minute is in the past ($scheduledDate). Scheduling for TOMORROW.');
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    } else {
      DebugLogger.log('DynamicScheduleProvider: Target $hour:$minute is in the future. Scheduling for TODAY ($scheduledDate).');
    }
    return scheduledDate;
  }
  
  Future<NotificationContent> _generateFallbackContent(int salt) async {
       // Simple round-robin logic same as background handler
       final typeSelector = salt % 3;
       if (typeSelector == 0) {
         return await NotificationContentGenerator.getRandomAyah(salt: salt);
       } else if (typeSelector == 1) {
         return NotificationContentGenerator.getRandomHadith(salt: salt);
       } else {
         if (salt % 2 == 0) {
           return NotificationContentGenerator.getRandomDhikr(salt: salt);
         } else {
           return NotificationContentGenerator.getRandomDuaa(salt: salt);
         }
       }
  }
}
