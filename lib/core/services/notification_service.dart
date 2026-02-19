import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../data/sources/hive_storage.dart';
import 'notification/managers/channel_manager.dart';
import 'notification/managers/permission_manager.dart';
import 'notification/display/notification_display.dart';

import 'notification/scheduling/schedule_manager.dart';
import 'notification/notification_registry.dart';
import 'notification/providers/fixed_schedule_provider.dart';
import 'notification/providers/dynamic_schedule_provider.dart';
import '../../features/prayer/notifications/prayer_notification_provider.dart';
import 'notification/testing/notification_debug_tools.dart';

// Re-export specific types if other files depend on them (optional)
export 'notification/testing/notification_debug_tools.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Core Managers
  late final PermissionManager _permissionManager;
  late final ChannelManager _channelManager;
  late final NotificationDisplay _display;
  late final ScheduleManager _scheduleManager;
  late final NotificationRegistry _registry;

  // Debug Tools
  late final NotificationDebugTools debugTools;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  HiveStorage? _storage;

  /// Initialize the service once
  Future<void> init(HiveStorage storage) async {
    if (_isInitialized) return;
    _storage = storage;

    debugPrint('NotificationService: Starting init sequence (Refactored)...');

    // 1. Initialize Timezone
    await _initTimezones();

    // 2. Initialize Core Managers
    _permissionManager = PermissionManager();
    _channelManager = ChannelManager();
    _display = NotificationDisplay(_flutterLocalNotificationsPlugin);
    _scheduleManager = ScheduleManager();
    _registry = NotificationRegistry(_scheduleManager, _storage!);

    // 3. Initialize Notifications Plugin
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
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 4. Create Channels
    await _channelManager.createChannels(_flutterLocalNotificationsPlugin);

    // 5. Register Providers
    _registry.register(FixedScheduleProvider(_display));
    _registry.register(DynamicScheduleProvider(
      _display, 
      _permissionManager
    ));
    _registry.register(PrayerNotificationProvider(_display));

    // 6. Initialize Debug Tools
    debugTools = NotificationDebugTools(
      _scheduleManager,
      _display,
      _permissionManager,
    );

    _isInitialized = true;
    
    // 7. Start Permission Polling (Async)
    _startPermissionPolling();

    // 8. Initial Schedule
    await reScheduleAll();
    debugPrint('NotificationService: Initialized successfully');
  }

  Future<void> _initTimezones() async {
    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      debugPrint('NotificationService: Device timezone: $timeZoneName');
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService: Failed to get device timezone, using UTC: $e');
      tz.setLocalLocation(tz.UTC); 
    }
  }

  void _startPermissionPolling() {
      _permissionManager.pollForOverlayPermission(
        onPermissionChanged: (granted) {
            debugPrint('NotificationService: Overlay permission changed to $granted. Rescheduling...');
            reScheduleAll();
        }
      );
  }

  // ---------------------------------------------------------------------------
  // Public API (Maintained for compatibility)
  // ---------------------------------------------------------------------------

  Future<void> reScheduleAll() async {
    if (!_isInitialized) return;
    debugPrint('NotificationService: Rescheduling all...');
    
    // Check Android permissions first
    await _permissionManager.requestAndroidPermissions();
    
    // Run Registry
    await _registry.rescheduleAll();
  }

  Future<bool> requestPermission() async {
    return _permissionManager.requestAndroidPermissions();
  }
  
  Future<bool> requestOverlayPermission() async {
    return _permissionManager.requestOverlayPermission();
  }

  Future<bool> isOverlayPermissionGranted() async {
      return _permissionManager.isOverlayPermissionGranted();
  }

  Future<bool> isBackgroundPopupsAllowed() async {
      return _permissionManager.isBackgroundPopupsAllowed();
  }

  Future<void> openMIUISettings() async {
      await _permissionManager.openMIUISettings();
  }

  Future<void> cancelAll() async {
    await _display.cancelAll();
    // We should also cancel alarms if possible, but Registry handles full reschedule usually.
  }
  
  // ---------------------------------------------------------------------------
  // Test Methods (Delegated to DebugTools)
  // ---------------------------------------------------------------------------
  
  Future<void> testNotification() async => debugTools.testNotification();
  Future<void> testFloatingOverlay() async => debugTools.testFloatingOverlay();
  Future<void> testDelayedNotification() async => debugTools.testDelayedNotification();

  // ---------------------------------------------------------------------------
  // Event Handlers
  // ---------------------------------------------------------------------------

  void _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;
    debugPrint('NotificationService: Tapped with payload: $payload');
    
    // Legacy logic for stats mapping
    // Parse payload: type|id
    final parts = payload.split('|');
    if (parts.length < 2) return;
    
    final type = parts[0];
    
    if (_storage == null) return;

    if (type == 'dhikr' || type == 'reminder') {
      await _storage!.incrementTotalDhikr();
      await _storage!.addPendingSync(dhikr: 1);
    } else if (type == 'ayah') {
      await _storage!.incrementTotalAyahLifeCount(1);
      await _storage!.addPendingSync(ayahs: 1);
    } else if (type == 'duaa') {
      await _storage!.incrementDuaa();
      await _storage!.addPendingSync(dhikr: 1); 
    } else if (type == 'hadith') {
      await _storage!.incrementTotalDhikr();
      await _storage!.addPendingSync(dhikr: 1);
    }
  }
}
