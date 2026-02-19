import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChannelManager {
  static const String channelContentId = 'noor_content';
  static const String channelRemindersId = 'noor_reminders';
  static const String channelPrayerId = 'noor_prayer';
  
  static const AndroidNotificationChannel contentChannel = AndroidNotificationChannel(
    channelContentId,
    'محتوى إيماني',
    description: 'آيات، أحاديث، وأذكار دورية',
    importance: Importance.max,
    showBadge: true,
    enableVibration: true,
    playSound: true,
  );

  static const AndroidNotificationChannel remindersChannel = AndroidNotificationChannel(
    channelRemindersId,
    'تنبيهات الأذكار',
    description: 'تنبيهات أذكار الصباح والمساة والسنن',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
    channelPrayerId,
    'الأذان ومواقيت الصلاة',
    description: 'تنبيهات الأذان ومواقيت الصلاة مع دعم الأذان المخصص',
    importance: Importance.max,
    enableLights: true,
    enableVibration: true,
    playSound: true,
  );

  Future<void> createChannels(FlutterLocalNotificationsPlugin plugin) async {
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(contentChannel);
      await androidPlugin.createNotificationChannel(remindersChannel);
      await androidPlugin.createNotificationChannel(prayerChannel);
    }
  }
}
