import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../../../data/models/notification_content.dart';

class OverlayDisplay {
  /// Show the overlay window
  Future<void> show(NotificationContent content) async {
    try {
      debugPrint('OverlayDisplay: Attempting to show overlay window...');
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: content.titleAr,
        overlayContent: content.bodyAr,
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        startPosition: const OverlayPosition(0, 0),
      );
    } catch (e) {
      debugPrint('OverlayDisplay: FAILED to show overlay: $e');
      rethrow;
    }
  }

  /// Share data with the active overlay
  Future<bool> shareData(NotificationContent content) async {
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
    
    final result = await FlutterOverlayWindow.shareData(data);
    debugPrint('OverlayDisplay: Data shared with overlay UI (Result: $result)');
    return result ?? false;
  }
  
  Future<void> close() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
