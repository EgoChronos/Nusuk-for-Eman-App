import 'dart:io';
import 'package:flutter/material.dart'; // For WidgetsFlutterBinding
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // No alias, keep default
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay; // Alias to avoid conflict
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';


import '../../data/sources/hive_storage.dart';
import 'notification_content_generator.dart';
import '../../data/models/notification_content.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  HiveStorage? _storage; // Optional storage if needed by background isolates
  bool _hasOverlayPermissionForSession = false;
  bool _isInitialized = false;
  Future<void>? _schedulingTask;

  /// Initialize the service once
  Future<void> init(HiveStorage storage) async {
    if (_isInitialized) return;
    _storage = storage;
    
    debugPrint('NotificationService: Starting init sequence...');
    
    // Initialize timezone database and set the local timezone
    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      debugPrint('NotificationService: Device timezone: $timeZoneName');
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService: Failed to get device timezone, using UTC: $e');
      tz.setLocalLocation(tz.UTC); // Critical fallback
    }

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Notification Channels for Android
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'noor_content',
          'محتوى إيماني',
          description: 'آيات، أحاديث، وأذكار دورية',
          importance: Importance.max,
          showBadge: true,
          enableVibration: true,
          playSound: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'noor_reminders',
          'تنبيهات الأذكار',
          description: 'تنبيهات أذكار الصباح والمساة والسنن',
          importance: Importance.max,
        ),
      );
    }

    _isInitialized = true;
    
    // Start background overlay permission polling (don't wait for it here)
    _pollForOverlayPermission();

    // Initial schedule 
    await reScheduleAll();
    debugPrint('NotificationService: Initialized successfully');
  }

  /// Private polling for overlay permission (Xiaomi/MIUI focus)
  Future<void> _pollForOverlayPermission() async {
    debugPrint('NotificationService: Background polling for overlay permission...');
    for (int i = 0; i < 10; i++) {
      final granted = await isOverlayPermissionGranted();
      if (granted != _hasOverlayPermissionForSession) {
        _hasOverlayPermissionForSession = granted;
        debugPrint('NotificationService: Overlay permission status changed to: $_hasOverlayPermissionForSession');
        reScheduleAll(); // Async call to refresh schedules
        if (granted) break;
      }
      await Future.delayed(const Duration(milliseconds: 2000));
    }
  }

  /// Re-check permissions and update all scheduled slots
  Future<void> reScheduleAll() async {
    if (!_isInitialized) {
      debugPrint('NotificationService: Skipping reScheduleAll as not initialized');
      return;
    }

    // Wait for any existing scheduling task to finish
    if (_schedulingTask != null) {
      debugPrint('NotificationService: Waiting for existing scheduling task...');
      await _schedulingTask;
    }

    _schedulingTask = _performScheduling();
    await _schedulingTask;
    _schedulingTask = null;
  }

  Future<void> _performScheduling() async {
    debugPrint('NotificationService: Running scheduling logic...');
    try {
      final currentOverlayStatus = await isOverlayPermissionGranted();
      if (currentOverlayStatus != _hasOverlayPermissionForSession) {
        _hasOverlayPermissionForSession = currentOverlayStatus;
      }
      await _scheduleAll();
    } catch (e) {
      debugPrint('NotificationService: Error during scheduling: $e');
    }
  }

  /// Request permissions (Android 13+)
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      // 1. Regular notification permission
      var status = await Permission.notification.status;
      debugPrint('NotificationService: Current notification status: $status');
      
      if (status.isDenied || status.isLimited || status.isRestricted) {
        debugPrint('NotificationService: Requesting notification permission...');
        status = await Permission.notification.request();
        debugPrint('NotificationService: New notification status: $status');
      }

      // 2. Exact Alarm permission (Android 13+)
      // Note: SCHEDULE_EXACT_ALARM doesn't always show a prompt, but we check if we can.
      // For many devices, it's granted by default, but for some it needs checking.
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      if (exactAlarmStatus.isDenied) {
        debugPrint('NotificationService: Requesting exact alarm permission...');
        await Permission.scheduleExactAlarm.request();
      }
      
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true; 
  }

  /// TEST: Trigger an immediate standard notification
  Future<void> testNotification() async {
    debugPrint('NotificationService: Triggering TEST notification...');
    final content = NotificationContent(
      id: '999',
      type: NotificationType.reminder,
      titleAr: 'اختبار التنبيهات 🔔',
      bodyAr: 'هذا تنبيه تجريبي للتأكد من وصول الإشعارات بشكل سليم.',
      titleEn: 'Notification Test 🔔',
      bodyEn: 'This is a test notification to ensure reminders are working.',
    );

    await _notifications.show(
      999,
      content.titleAr,
      content.bodyAr,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'noor_reminders',
          'Test',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: _encodePayload(content),
    );
  }

  /// TEST: Trigger an immediate floating overlay (or fallback)
  Future<void> testFloatingOverlay() async {
    debugPrint('NotificationService: Triggering TEST floating overlay in 20 seconds...');
    final hasPermission = await isOverlayPermissionGranted();
    
    if (hasPermission) {
      final now = tz.TZDateTime.now(tz.local);
      final testTime = now.add(const Duration(seconds: 20));
      
      // Use test ID 998 and encoded ID for isolation
      final int id = 998;
      final int encodedId = (id * 10000) + (testTime.hour * 100) + testTime.minute;

      await AndroidAlarmManager.oneShotAt(
        testTime,
        encodedId,
        showOverlayCallback,
        exact: true,
        wakeup: true,
      );
      debugPrint('SUCCESS: Scheduled TEST overlay in 20 seconds at $testTime');
    } else {
      debugPrint('FALLBACK: Overlay permission missing for TEST. Using standard notification.');
      await testNotification();
    }
  }

  /// TEST: Trigger the specific morning reminder (ID 106) in 20 seconds
  Future<void> testMorningReminder() async {
    debugPrint('NotificationService: Triggering TEST morning reminder in 20 seconds...');
    final hasPermission = await isOverlayPermissionGranted();
    
    if (hasPermission) {
      final now = tz.TZDateTime.now(tz.local);
      final testTime = now.add(const Duration(seconds: 20));
      
      // Use ID 106 (Morning Reminder)
      final int id = 106;
      final int encodedId = (id * 10000) + (testTime.hour * 100) + testTime.minute;

      await AndroidAlarmManager.oneShotAt(
        testTime,
        encodedId,
        showOverlayCallback,
        exact: true,
        wakeup: true,
      );
      debugPrint('SUCCESS: Scheduled TEST morning reminder in 20 seconds at $testTime');
    } else {
      debugPrint('FALLBACK: Overlay permission missing for TEST. Using standard notification.');
      await testNotification();
    }
  }

  /// Schedule all notifications based on settings
  Future<void> _scheduleAll() async {
    final settings = _storage!.getNotificationSettings();
    debugPrint('Notification settings: $settings');
    
    if (settings['enabled'] == false) {
      await _notifications.cancelAll();
      // Also cancel all alarms
      // We don't have an easy "cancel all" for alarms without IDs, 
      // but init() will clear them when disabled eventually.
      return;
    }

    // 1. Fixed Reminders (Adhkar)
    if (settings['morning'] == true) {
      await _scheduleDaily(
        id: 101,
        hour: 6,
        minute: 0,
        content: NotificationContentGenerator.getReminder('morning'),
        channelId: 'noor_reminders',
      );
    }
    
    if (settings['evening'] == true) {
      await _scheduleDaily(
        id: 102,
        hour: 17,
        minute: 30,
        content: NotificationContentGenerator.getReminder('evening'),
        channelId: 'noor_reminders',
      );
    }

    if (settings['sleep'] == true) {
      await _scheduleDaily(
        id: 103,
        hour: 22, // 22:00
        minute: 00,
        content: NotificationContentGenerator.getReminder('sleep'),
        channelId: 'noor_reminders',
      );
    }

    // Friday Kahf (Friday 01:30 PM)
    if (settings['kahf'] == true) {
      await _scheduleWeekly(
        id: 104,
        day: DateTime.friday,
        hour: 13, // 01:30 PM
        minute: 30,
        content: NotificationContentGenerator.getReminder('kahf'),
        channelId: 'noor_reminders',
      );
    }

    // Daily Duaa for Eman (9:00 PM) - Night Reminder
    await _scheduleDailyContent(
      id: 105,
      hour: 21,
      minute: 0,
      salt: 105,
      hasOverlayPermission: _hasOverlayPermissionForSession,
    );

    // Daily Morning Reminder for Eman (8:00 AM)
    await _scheduleDailyContent(
      id: 106,
      hour: 8,
      minute: 0,
      salt: 106,
      hasOverlayPermission: _hasOverlayPermissionForSession,
    );

    // 2. Dynamic Content (Floating Overlay or Normal)
    if (settings['floating'] == true) {
      final frequency = settings['frequency'] ?? 'medium';
      debugPrint('Floating content frequency: $frequency');
      
      List<List<int>> slots;
      if (frequency == 'low') {
        slots = [
          [08, 00],  // 8:00 AM
          [20, 00],  // 8:00 PM
        ];
      } else if (frequency == 'high') {
        slots = [
          [07, 00],  // 7:00 AM
          [08, 30],  // 8:30 AM
          [10, 00],  // 10:00 AM
          [11, 30],  // 11:30 AM
          [13, 00],  // 1:00 PM
          [14, 30],  // 2:30 PM
          [16, 00],  // 4:00 PM
          [17, 30],  // 5:30 PM
          [19, 00],  // 7:00 PM
          [20, 30],  // 8:30 PM
          [22, 00],  // 10:00 PM
          [23, 30],  // 11:30 PM
        ];
      } else {
        // Medium - Production Schedule
        slots = [
          [07, 00],  // 7:00 AM
          [10, 00],  // 10:00 AM
          [13, 00],  // 1:00 PM
          [16, 00],  // 4:00 PM
          [19, 00],  // 7:00 PM
          [22, 00],  // 10:00 PM
        ];
      }

      for (int i = 0; i < slots.length; i++) {
        await _scheduleDailyContent(
          id: 201 + i,
          hour: slots[i][0],
          minute: slots[i][1],
          salt: 201 + i,
          hasOverlayPermission: _hasOverlayPermissionForSession,
        );
      }
    }
  }

  /// Cancels all scheduled notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Returns the next scheduled time for a content reminder
  Future<DateTime?> getNextScheduledTime() async {
    final settings = _storage!.getNotificationSettings();
    if (settings['enabled'] == false) return null;
    
    final freq = settings['frequency'] ?? 'medium';
    List<List<int>> slots;
    if (freq == 'low') {
      slots = [[8, 0], [20, 0]];
    } else if (freq == 'high') {
      slots = [
        [7, 0], [8, 30], [10, 0], [11, 30], [13, 0], [14, 30], 
        [16, 0], [17, 30], [19, 0], [20, 30], [22, 0], [23, 30]
      ];
    } else {
      // Medium - Production Schedule
      slots = [
        [7, 0], [10, 0], [13, 0], [16, 0], [19, 0], [22, 0]
      ];
    }

    DateTime? earliest;
    for (final slot in slots) {
      final time = _nextInstanceOfTime(slot[0], slot[1]);
      if (earliest == null || time.isBefore(earliest)) {
        earliest = time;
      }
    }
    return earliest;
  }

  /// Schedule a daily repeated notification
  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required NotificationContent content,
    required String channelId,
  }) async {
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    debugPrint('Scheduling notification id=$id at $scheduledTime (channel: $channelId, title: ${content.titleAr})');
    await _notifications.zonedSchedule(
      id,
      content.titleAr, // Uses Arabic title by default, can be localized later
      content.bodyAr,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'noor_reminders' ? 'Reminders' : 'Daily Content',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _encodePayload(content),
    );
  }

  /// Schedule a weekly repeated notification
  Future<void> _scheduleWeekly({
    required int id,
    required int day,
    required int hour,
    required int minute,
    required NotificationContent content,
    required String channelId,
  }) async {
    await _notifications.zonedSchedule(
      id,
      content.titleAr,
      content.bodyAr,
      _nextInstanceOfDayAndTime(day, hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Reminders',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: _encodePayload(content),
    );
  }

  /// Schedule dynamic content (floating)
  /// Since we want random content each time, we can't just set a static title/body
  /// In a real app we'd use a background fetch or exact alarm to generate content at trigger time.
  /// For this MVP, we pre-generate content for the next instance.
  /// Helper to check permission status
  Future<bool> isOverlayPermissionGranted() async {
    // Check both the plugin's internal check and the general permission handler
    final bool pluginCheck = await overlay.FlutterOverlayWindow.isPermissionGranted();
    final bool handlerCheck = await Permission.systemAlertWindow.isGranted;
    
    // Log very clearly for the user
    debugPrint('PERMISSION CHECK:');
    debugPrint('  - System Alert Window Plugin: $pluginCheck');
    debugPrint('  - Permission Handler (Android): $handlerCheck');
    debugPrint('  - IMPORTANT (Xiaomi): Check "Display pop-up windows while running in the background"');
    
    return pluginCheck || handlerCheck;
  }

  /// Request Overlay Permission
  Future<bool> requestOverlayPermission() async {
    final status = await overlay.FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      final directed = await overlay.FlutterOverlayWindow.requestPermission();
      return directed ?? false;
    }
    return true;
  }
  /// Schedule dynamic content (floating)
  Future<void> _scheduleDailyContent({
    required int id,
    required int hour,
    required int minute,
    required int salt,
    required bool hasOverlayPermission,
  }) async {
    // 1. Cancel any existing standard notification/alarm for this base ID
    await _notifications.cancel(id);
    // Also cancel potential encoded IDs (cleaning up from previous runs)
    await AndroidAlarmManager.cancel(id); 

    // 2. Decide based on overlay permission
    debugPrint('Overlay permission choice for baseId=$id (slot: $hour:$minute): $hasOverlayPermission');
    
    if (hasOverlayPermission) {
      debugPrint('Scheduling true floating overlay for id=$id');
      final scheduledTime = _nextInstanceOfTime(hour, minute);
      
      // Encode time in ID for background rescheduling: baseId * 10000 + HHMM
      final encodedId = (id * 10000) + (hour * 100) + minute;
      
      // Cancel encoded ID just in case
      await AndroidAlarmManager.cancel(encodedId);

      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        encodedId,
        showOverlayCallback,
        exact: true,
        wakeup: true,
        alarmClock: true,
        rescheduleOnReboot: true,
      );
      
      debugPrint('SUCCESS: Scheduled overlay encodedId=$encodedId at $scheduledTime (Actual Date: ${scheduledTime.year}-${scheduledTime.month}-${scheduledTime.day})');
    } else {
      debugPrint('FALLBACK: Overlay permission missing for id=$id. Using standard notification.');
      final content = await _generateDynamicContent(salt);
      final scheduledTime = _nextInstanceOfTime(hour, minute);
      
      await _scheduleDaily(
        id: id,
        hour: hour,
        minute: minute,
        content: content,
        channelId: 'noor_content',
      );
      debugPrint('SUCCESS (Fallback): Scheduled notification id=$id at $scheduledTime (Local Time)');
    }
  }

  // ── Helper Methods ─────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
  
  String _encodePayload(NotificationContent content) {
    // Simple encoding: type|id|payloadKey:value
    // Ideally use JSON
    return '${content.type.name}|${content.id}';
  }

  void _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;

    debugPrint('Notification tapped: $payload');
    
    // Parse payload: type|id
    final parts = payload.split('|');
    if (parts.length < 2) return;
    
    final type = parts[0];
    
    // 1. Increment Stats
    // We can do this immediately
    if (type == 'dhikr' || type == 'reminder') {
      await _storage!.incrementTotalDhikr();
      await _storage!.addPendingSync(dhikr: 1);
    } else if (type == 'ayah') {
      await _storage!.incrementTotalAyahLifeCount(1);
      await _storage!.addPendingSync(ayahs: 1);
    } else if (type == 'duaa') {
      await _storage!.incrementDuaa();
      await _storage!.addPendingSync(dhikr: 1); // Helper: map duaa to dhikr count for global
    } else if (type == 'hadith') {
      // No specific hadith counter, maybe count as reading time or dhikr?
      // Let's count as dhikr for now as it's "remembrance"
      await _storage!.incrementTotalDhikr();
      await _storage!.addPendingSync(dhikr: 1);
    }
  }

  /// TEST: Trigger a normal notification in 20 seconds
  Future<void> testDelayedNotification() async {
    debugPrint('NotificationService: Triggering TEST delayed alert in 20 seconds...');
    
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

    await _notifications.zonedSchedule(
      997,
      content.titleAr,
      content.bodyAr,
      testTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'noor_reminders',
          'Test',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: _encodePayload(content),
    );
    debugPrint('SUCCESS: Scheduled TEST delayed alert in 20 seconds at $testTime');
  }
}

// ── Top-Level Helpers for Background Isolates ────────────────────────────────

@pragma("vm:entry-point")
void showOverlayCallback(int id) async {
  debugPrint('showOverlayCallback triggered with id: $id');
  
  // Decode: baseId * 10000 + HHMM
  final int baseId = id ~/ 10000;
  final int hour = (id % 10000) ~/ 100;
  final int minute = id % 100;

  // 1. Initialize Flutter bindings (for plugins)
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL: Initialize timezones in background isolate
  tz_data.initializeTimeZones();
  try {
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } catch (_) {
    tz.setLocalLocation(tz.UTC);
  }
  
  debugPrint('Bindings and timezones initialized in background isolate (BaseId: $baseId)');

  // Initialize Local Notifications inside isolate for fallback
  final fln = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  await fln.initialize(const InitializationSettings(android: androidInit));
  
  // 2. Generate content (using baseId as salt)
  final content = await _generateDynamicContent(baseId);
  debugPrint('Generated content for overlay: ${content.titleAr}');
  
  // 3. Prepare data map
  final data = {
    'id': content.id,
    'type': content.type.name,
    'titleAr': content.titleAr,
    'titleEn': content.titleEn,
    'bodyAr': content.bodyAr,
    'bodyEn': content.bodyEn,
    'sourceLabel': content.sourceLabel,
    'payload': content.payload,
  };

  // 3b. Fallback Notification (in case the overlay window is blocked or hidden)
  // We show this after a short delay to allow overlay to attempt display first
  Future.delayed(const Duration(milliseconds: 500)).then((_) async {
    await fln.show(
      baseId,
      content.titleAr,
      '${content.bodyAr.substring(0, content.bodyAr.length > 50 ? 50 : content.bodyAr.length)}...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'noor_content',
          'محتوى إيماني',
          importance: Importance.high,
          priority: Priority.high,
          // fullScreenIntent removed as it can suppress overlays on some devices
        ),
      ),
    );
    debugPrint('Fallback notification shown in background isolate');
  });
  
  // 4. Show Overlay
  try {
    debugPrint('Attempting to show overlay window...');
    await overlay.FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: content.titleAr,
      overlayContent: content.bodyAr,
      flag: overlay.OverlayFlag.defaultFlag,
      alignment: overlay.OverlayAlignment.center,
      visibility: overlay.NotificationVisibility.visibilityPublic,
      positionGravity: overlay.PositionGravity.auto,
      height: overlay.WindowSize.matchParent,
      width: overlay.WindowSize.matchParent,
      startPosition: const overlay.OverlayPosition(0, 0),
    );
    debugPrint('showOverlay call completed. Window should be visible now.');
    
    // Send data to listener
    await Future.delayed(const Duration(milliseconds: 1500));
    final shared = await overlay.FlutterOverlayWindow.shareData(data);
    debugPrint('Data shared with overlay UI (Success: $shared)');
    
    // Keep isolate alive for a bit to ensure service stability
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('Background isolate task for id=$id finished.');
  } catch (e) {
    debugPrint('FAILED to show overlay: $e');
  }

  // 5. Self-Reschedule for tomorrow at the same time
  try {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, hour, minute);
    
    await AndroidAlarmManager.oneShotAt(
      tomorrow,
      id, // Reuse the same encoded ID
      showOverlayCallback,
      exact: true,
      wakeup: true,
      alarmClock: true,
      rescheduleOnReboot: true,
    );
    debugPrint('Successfully self-rescheduled id=$id for tomorrow at $tomorrow');
  } catch (e) {
    debugPrint('Failed to self-reschedule: $e');
  }
}

@pragma("vm:entry-point")
Future<NotificationContent> _generateDynamicContent(int baseId) async {
  // Special Case: Fixed Reminder (Duaa for Eman - Night)
  if (baseId == 105) {
    return NotificationContentGenerator.getReminder('duaa_eman');
  }

  // Special Case: Fixed Reminder (Eman Morning)
  if (baseId == 106) {
    return NotificationContentGenerator.getReminder('morning_eman');
  }
  
  // Special Case: Test
  if (baseId == 998) {
    return const NotificationContent(
      id: 'test_998',
      type: NotificationType.reminder,
      titleAr: 'اختبار التنبيهات العائمة 🔔',
      bodyAr: 'هذه نافذة تجريبية للتأكد من عمل التنبيهات العائمة بشكل سليم.',
      titleEn: 'Floating Overlay Test 🔔',
      bodyEn: 'This is a test window to ensure floating reminders are working correctly.',
    );
  }

  // Rotate content types: Ayah -> Hadith -> Duaa -> Dhikr
  final now = DateTime.now();
  final day = now.day;
  final hour = now.hour;
  
  // Incorporate hour to ensure variety if testing different times of the same day
  final typeIndex = (day + baseId + hour) % 4;
  
  switch (typeIndex) {
    case 0:
      return await NotificationContentGenerator.getRandomAyah(salt: baseId);
    case 1:
      return NotificationContentGenerator.getRandomHadith(salt: baseId);
    case 2:
      return NotificationContentGenerator.getRandomDuaa(salt: baseId);
    default:
      return NotificationContentGenerator.getRandomDhikr(salt: baseId);
  }
}
