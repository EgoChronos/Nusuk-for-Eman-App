
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../data/models/notification_content.dart';
import '../../notification_content_generator.dart';
import '../display/notification_display.dart';
import '../managers/channel_manager.dart';
import '../scheduling/schedule_manager.dart';
import '../notification_registry.dart';
import '../../../../data/sources/hive_storage.dart';
import '../../debug_logger.dart';

class FixedScheduleProvider implements NotificationScheduleProvider {
  final NotificationDisplay _display;

  FixedScheduleProvider(this._display);

  @override
  String get id => 'fixed_reminders';

  @override
  Future<void> schedule(ScheduleManager manager, HiveStorage storage) async {
    final settings = storage.getNotificationSettings();
    if (settings['enabled'] == false) return;

    // 1. Morning Adhkar
    if (settings['morning'] == true) {
      await _scheduleDaily(
        id: 101,
        hour: 6,
        minute: 0,
        content: NotificationContentGenerator.getReminder('morning'),
      );
    }

    // 2. Evening Adhkar
    if (settings['evening'] == true) {
      await _scheduleDaily(
        id: 102,
        hour: 17, //17:30
        minute: 30,
        content: NotificationContentGenerator.getReminder('evening'),
      );
    }

    // 3. Sleep Adhkar
    if (settings['sleep'] == true) {
      await _scheduleDaily(
        id: 103,
        hour: 22, //22:00
        minute: 00,
        content: NotificationContentGenerator.getReminder('sleep'),
      );
    }
    
    // 4. Kahf (Friday)
    if (settings['kahf'] == true) {
       await _scheduleWeekly(
        id: 104,
        day: DateTime.friday,
        hour: 13,
        minute: 30,
        content: NotificationContentGenerator.getReminder('kahf'),
      );
    }
    
    // 5. Duaa for Eman (Night) -> Moved to DynamicScheduleProvider to support Overlay
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required NotificationContent content,
  }) async {
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    await _display.schedule(
      id: id,
      content: content,
      scheduledTime: scheduledTime,
      channelId: ChannelManager.channelRemindersId,
      matchDateTimeComponents: DateTimeComponents.time,
    );
     DebugLogger.log('FixedScheduleProvider: Scheduled ${content.titleAr} at $scheduledTime');
  }
  
  Future<void> _scheduleWeekly({
    required int id,
    required int day,
    required int hour,
    required int minute,
    required NotificationContent content,
  }) async {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    await _display.schedule(
      id: id,
      content: content,
      scheduledTime: scheduledDate,
      channelId: ChannelManager.channelRemindersId,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
