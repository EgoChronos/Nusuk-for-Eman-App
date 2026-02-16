import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart' as sp;
import 'package:nusuk_for_iman/core/theme/app_colors.dart';
import 'package:nusuk_for_iman/data/models/notification_content.dart';
import 'package:foreground_launcher/foreground_launcher.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  NotificationContent? _content;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    // In a real app, we'd pass data via args or shared pres.
    // However, flutter_overlay_window supports passing data via 'shareData'.
    // For MVP complex objects, we might need to rely on shared prefs 
    // or just listen to the data passed in showOverlay(..., data: ...).
    
    // For now, let's listen to the data stream
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
         // Parse map to NotificationContent
         // Reconstructing manually since we can't easily pass the object
         final typeName = event['type'] as String? ?? 'reminder';
         final type = NotificationType.values.firstWhere(
           (e) => e.name == typeName, orElse: () => NotificationType.reminder
         );
         
         setState(() {
           _content = NotificationContent(
             id: event['id'] ?? 'unknown',
             type: type,
             titleAr: event['titleAr'] ?? 'ذكر',
             titleEn: event['titleEn'] ?? 'Dhikr',
             bodyAr: event['bodyAr'] ?? '',
             bodyEn: event['bodyEn'] ?? '',
             sourceLabel: event['sourceLabel'],
             payload: Map<String, dynamic>.from(event['payload'] ?? {}),
           );
           _isLoading = false;
         });
      }
    });
  }

  Future<void> _markAsRead() async {
    if (_content == null) return;
    
    // Use SharedPreferences for isolate-safe signaling
    final prefs = await sp.SharedPreferences.getInstance();
    
    final type = _content!.type;
    if (type != NotificationType.hadith) {
      await prefs.setString('pending_mark_read', type.name);
    }
    
    await FlutterOverlayWindow.closeOverlay();
  }

  Future<void> _openDuaaAction() async {
    if (_content == null) return;
    
    final prefs = await sp.SharedPreferences.getInstance();
    
    // 1. Signal navigation
    await prefs.setString('pending_navigation', '/duaa');
    
    // 2. Signal counter increment (for the action taken)
    await prefs.setString('pending_mark_read', NotificationType.duaa.name);
    
    // 3. Close Overlay
    await FlutterOverlayWindow.closeOverlay();
    
    // 4. Launch App (Reliable via Local Plugin)
    await ForegroundLauncher.bringToForeground();
  }

  @override
  Widget build(BuildContext context) {
    // If content not loaded yet, show empty (transparent)
    if (_isLoading || _content == null) {
      return const SizedBox();
    }
    
    final isHadith = _content!.type == NotificationType.hadith;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface, // Should be an opaque color
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _content!.titleAr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSubtle),
                      onPressed: () => FlutterOverlayWindow.closeOverlay(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                
                // Body
                Text(
                  _content!.bodyAr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_content!.sourceLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _content!.sourceLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
                
                // Actions
                const SizedBox(height: 20),
                if (_content!.type == NotificationType.duaa)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openDuaaAction,
                        icon: const Icon(Icons.favorite),
                        label: const Text('ادعُ لها الآن (Duaa Now)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                if (!isHadith) 
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _markAsRead,
                      icon: const Icon(Icons.check),
                      label: const Text('تمة القراءة (Mark as Read)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
