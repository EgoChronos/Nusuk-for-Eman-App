import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class PermissionManager {
  static const _channel = MethodChannel('com.noorforiman.noor_for_iman/permissions');
  
  bool _hasOverlayPermissionForSession = false;

  bool get hasOverlayPermissionForSession => _hasOverlayPermissionForSession;

  /// Request standard notification and exact alarm permissions
  Future<bool> requestAndroidPermissions() async {
    if (!Platform.isAndroid) return true;

    // 1. Notification Permission
    var status = await Permission.notification.status;
    if (status.isDenied || status.isLimited || status.isRestricted) {
      status = await Permission.notification.request();
    }

    // 2. Exact Alarm (Android 13+)
    // minimal checking as some devices don't show prompt
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (exactAlarmStatus.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    return status.isGranted;
  }
  
  /// Check if overlay permission is currently granted
  Future<bool> isOverlayPermissionGranted() async {
    // Check both the plugin's internal check and the general permission handler
    final bool pluginCheck = await FlutterOverlayWindow.isPermissionGranted();
    final bool handlerCheck = await Permission.systemAlertWindow.isGranted;
    
    final granted = pluginCheck || handlerCheck;
    if (granted != _hasOverlayPermissionForSession) {
      _hasOverlayPermissionForSession = granted;
    }
    
    return granted;
  }

  /// Request Overlay Permission from user
  Future<bool> requestOverlayPermission() async {
    final status = await FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      final directed = await FlutterOverlayWindow.requestPermission();
      return directed ?? false;
    }
    return true;
  }

  /// Poll for overlay permission (Xiaomi/MIUI specific fix)
  /// Returns stream of status changes or just updates internal state
  Future<void> pollForOverlayPermission({
    required Function(bool) onPermissionChanged,
    int attempts = 10,
  }) async {
    debugPrint('PermissionManager: Polling for overlay permission...');
    for (int i = 0; i < attempts; i++) {
      final granted = await isOverlayPermissionGranted();
      if (granted != _hasOverlayPermissionForSession) {
        _hasOverlayPermissionForSession = granted;
        onPermissionChanged(granted);
        if (granted) break;
      }
      await Future.delayed(const Duration(milliseconds: 2000));
    }
  }

  /// Check if "Display pop-up windows while running in the background" is granted (MIUI specific)
  Future<bool> isBackgroundPopupsAllowed() async {
    try {
      final bool? allowed = await _channel.invokeMethod<bool>('checkBackgroundPopups');
      debugPrint('PermissionManager: MIUI Background Popups Allowed = $allowed');
      return allowed ?? true; // Default to true if not MIUI or check fails
    } catch (e) {
      debugPrint('PermissionManager: Error checking background popups: $e');
      return true;
    }
  }

  /// Open MIUI-specific settings for background popups
  Future<void> openMIUISettings() async {
    try {
      await _channel.invokeMethod('openOtherPermissions');
    } catch (e) {
      debugPrint('PermissionManager: Error opening MIUI settings: $e');
    }
  }
}
