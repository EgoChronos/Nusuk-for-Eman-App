import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class PermissionStatusModel {
  final bool overlayGranted;
  final bool batteryOptimized; // true if restricted (we want false)
  final bool backgroundPopupsGranted;
  final int grantedCount;

  PermissionStatusModel({
    required this.overlayGranted,
    required this.batteryOptimized,
    required this.backgroundPopupsGranted,
    required this.grantedCount,
  });

  bool get isAllGranted => grantedCount >= 3;
}

class PermissionService {
  static const _channel = MethodChannel('com.noorforiman.noor_for_iman/permissions');

  Future<PermissionStatusModel> checkAllStatus() async {
    final overlay = await FlutterOverlayWindow.isPermissionGranted();
    
    // Check Battery Optimization via permission_handler
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;
    
    // Check Background Popups (Xiaomi specific check via native or general fallback)
    bool backgroundPopups = true;
    if (Platform.isAndroid) {
      try {
        backgroundPopups = await _channel.invokeMethod<bool>('checkBackgroundPopups') ?? true;
      } catch (e) {
        backgroundPopups = true; // Assume true if check fails or not Xiaomi
      }
    }

    int count = 0;
    if (overlay) count++;
    if (battery) count++;
    if (backgroundPopups) count++;

    return PermissionStatusModel(
      overlayGranted: overlay,
      batteryOptimized: !battery,
      backgroundPopupsGranted: backgroundPopups,
      grantedCount: count,
    );
  }

  Future<void> requestOverlay() async {
    await FlutterOverlayWindow.requestPermission();
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<void> openBackgroundPermissions() async {
    // Open "Other permissions" on Xiaomi if possible, or just app settings
    if (Platform.isAndroid) {
       try {
         await _channel.invokeMethod('openOtherPermissions');
       } catch (e) {
         openAppSettings();
       }
    } else {
      openAppSettings();
    }
  }
}

final permissionServiceProvider = Provider((ref) => PermissionService());

final permissionStateProvider = StateNotifierProvider<PermissionStateNotifier, AsyncValue<PermissionStatusModel>>((ref) {
  return PermissionStateNotifier(ref.watch(permissionServiceProvider));
});

class PermissionStateNotifier extends StateNotifier<AsyncValue<PermissionStatusModel>> {
  final PermissionService _service;

  PermissionStateNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const AsyncValue.loading();
    try {
      final status = await _service.checkAllStatus();
      state = AsyncValue.data(status);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
