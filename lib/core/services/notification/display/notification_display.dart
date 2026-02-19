import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../data/models/notification_content.dart';
import '../managers/channel_manager.dart';

class NotificationDisplay {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationDisplay(this._plugin);

  /// Show an immediate notification
  Future<void> show({
    required int id,
    required NotificationContent content,
    required String channelId,
    String? sound,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == ChannelManager.channelRemindersId ? 'Reminders' : 
      channelId == ChannelManager.channelPrayerId ? 'Prayer' : 'Daily Content',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      sound: sound != null ? RawResourceAndroidNotificationSound(sound) : null,
      playSound: true,
    );

    try {
      await _plugin.show(
        id,
        content.titleAr,
        content.bodyAr,
        NotificationDetails(android: androidDetails),
        payload: _encodePayload(content),
      );
    } catch (e) {
      if (sound != null) {
        // Fallback to default sound
        final fallbackDetails = AndroidNotificationDetails(
          channelId,
          channelId == ChannelManager.channelRemindersId ? 'Reminders' : 
          channelId == ChannelManager.channelPrayerId ? 'Prayer' : 'Daily Content',
          importance: Importance.max,
          priority: Priority.high,
        );
        await _plugin.show(
          id,
          content.titleAr,
          content.bodyAr,
          NotificationDetails(android: fallbackDetails),
          payload: _encodePayload(content),
        );
      } else {
        rethrow;
      }
    }
  }

  /// Schedule a notification at a specific time
  Future<void> schedule({
    required int id,
    required NotificationContent content,
    required tz.TZDateTime scheduledTime,
    required String channelId,
    required DateTimeComponents? matchDateTimeComponents,
    String? sound,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == ChannelManager.channelRemindersId ? 'Reminders' : 
      channelId == ChannelManager.channelPrayerId ? 'Prayer' : 'Daily Content',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      sound: sound != null ? RawResourceAndroidNotificationSound(sound) : null,
      playSound: true,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        content.titleAr,
        content.bodyAr,
        scheduledTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: _encodePayload(content),
      );
    } catch (e) {
      if (sound != null) {
        final fallbackDetails = AndroidNotificationDetails(
          channelId,
          channelId == ChannelManager.channelRemindersId ? 'Reminders' : 
          channelId == ChannelManager.channelPrayerId ? 'Prayer' : 'Daily Content',
          importance: Importance.max,
          priority: Priority.high,
        );
        await _plugin.zonedSchedule(
          id,
          content.titleAr,
          content.bodyAr,
          scheduledTime,
          NotificationDetails(android: fallbackDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: _encodePayload(content),
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingRequest() async {
    return await _plugin.pendingNotificationRequests();
  }

  String _encodePayload(NotificationContent content) {
    return '${content.type.name}|${content.id}';
  }
}
