import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../data/sources/hive_storage.dart';
import '../../../../core/services/notification/notification_registry.dart';
import '../../../../core/services/notification/scheduling/schedule_manager.dart';
import '../../../../core/services/notification/display/notification_display.dart';
import '../../../../core/services/notification/managers/channel_manager.dart';
import '../../../../core/services/notification/handlers/background_handler.dart';
import '../../../../data/models/notification_content.dart';
import '../services/prayer_service.dart';
import '../../../core/services/location_service.dart';

class PrayerNotificationProvider implements NotificationScheduleProvider {
  final LocationService _locationService = LocationService();
  final PrayerService _prayerService = PrayerService();
  final NotificationDisplay _display;

  PrayerNotificationProvider(this._display);

  @override
  String get id => 'prayer_times';

  @override
  Future<void> schedule(ScheduleManager manager, HiveStorage storage) async {
    debugPrint('PrayerNotificationProvider: Scheduling prayer alarms...');
    
    // 1. Get Location
    final position = await _locationService.getCurrentPosition();
    if (position == null) {
      debugPrint('PrayerNotificationProvider: No location, skipping schedule.');
      return;
    }

    // 2. Clear old schedules in the 3000 range to be clean
    // (Though zonedSchedule with same ID overwrites, it's good practice for non-repeating ones)

    // 3. Calculate Times for Today & Tomorrow
    final now = DateTime.now();
    await _scheduleForDate(now, position, manager, storage);
    await _scheduleForDate(now.add(const Duration(days: 1)), position, manager, storage);
  }

  Future<void> _scheduleForDate(DateTime date, Position position, ScheduleManager manager, HiveStorage storage) async {
    final times = _prayerService.getPrayerTimes(
      position: position,
      date: date,
    );

    if (times == null) return;

    final athanSound = storage.getAthanSound();
    final preReminderMins = storage.getPrePrayerReminderMinutes();
    final sunriseEnabled = storage.isSunriseAlertEnabled();

    // ID Scheme: 3000 + (DayOfYear * 10) + Index
    // Since we only schedule today/tomorrow, we can use a simpler 3000 (Today) / 3500 (Tomorrow) base
    final isTomorrow = date.day != DateTime.now().day;
    final baseId = isTomorrow ? 3500 : 3000;

    // Fajr
    _schedulePrayer(manager, times.fajr, 'الفجر', baseId + 0, athanSound, preReminderMins);
    
    // Sunrise (No pre-reminder usually, but we check if enabled)
    if (sunriseEnabled) {
      _schedulePrayer(manager, times.sunrise, 'الشروق', baseId + 1, 'default', 0);
    }

    // Dhuhr
    _schedulePrayer(manager, times.dhuhr, 'الظهر', baseId + 2, athanSound, preReminderMins);
    
    // Asr
    _schedulePrayer(manager, times.asr, 'العصر', baseId + 3, athanSound, preReminderMins);
    
    // Maghrib
    _schedulePrayer(manager, times.maghrib, 'المغرب', baseId + 4, athanSound, preReminderMins);
    
    // Isha
    _schedulePrayer(manager, times.isha, 'العشاء', baseId + 5, athanSound, preReminderMins);
  }

  void _schedulePrayer(
    ScheduleManager manager, 
    DateTime time, 
    String name, 
    int id, 
    String sound, 
    int preReminderMins
  ) {
    final now = DateTime.now();
    
    // 1. Schedule Main Notification (The "Floor")
    if (time.isAfter(now)) {
       final tzTime = tz.TZDateTime.from(time, tz.local);
       _display.schedule(
         id: id,
         content: NotificationContent(
           id: 'prayer_$id',
           type: NotificationType.reminder,
           titleAr: 'حان الآن موقت صلاة $name',
           titleEn: 'It is now time for $name',
           bodyAr: 'حي على الصلاة.. حي على الفلاح',
           bodyEn: 'Hasten to prayer, hasten to success',
         ),
         scheduledTime: tzTime,
         channelId: ChannelManager.getPrayerChannelId(sound),
         matchDateTimeComponents: null, // One-shot
         sound: sound == 'default' ? null : sound,
       );

       // 2. Schedule Precise Alarm (The "Ceiling" / Logic)
       manager.scheduleOneShot(
         time: time,
         id: id + 10000, // Offset for AlarmManager
         callback: prayerAlarmCallback,
         alarmClock: true,
         wakeup: true,
         rescheduleOnReboot: true,
       );
       debugPrint('Scheduled Prayer: $name at $time (ID: $id)');
    }

    // 3. Schedule Pre-Prayer Reminder
    if (preReminderMins > 0) {
      final preTime = time.subtract(Duration(minutes: preReminderMins));
      if (preTime.isAfter(now)) {
        final preTzTime = tz.TZDateTime.from(preTime, tz.local);
        final preId = id + 100; // Offset for pre-reminder
        
        _display.schedule(
          id: preId,
          content: NotificationContent(
            id: 'pre_prayer_$preId',
            type: NotificationType.reminder,
            titleAr: 'تنبيه: صلاة $name',
            titleEn: 'Reminder: $name Prayer',
            bodyAr: 'بقي $preReminderMins دقائق على صلاة $name',
            bodyEn: '$preReminderMins minutes left until $name prayer',
          ),
          scheduledTime: preTzTime,
          channelId: ChannelManager.channelPrayerId,
          matchDateTimeComponents: null,
        );
        debugPrint('Scheduled Pre-Reminder for $name at $preTime (ID: $preId)');
      }
    }
  }
}
