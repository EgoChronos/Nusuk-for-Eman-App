import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/sources/hive_storage.dart';
import '../../core/services/notification_service.dart'; // Import to reschedule
import 'package:nusuk_for_iman/l10n/app_localizations.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  final HiveStorage storage;

  const NotificationSettingsScreen({super.key, required this.storage});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> with WidgetsBindingObserver {
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = widget.storage.getNotificationSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('NotificationSettings: App resumed, re-syncing permissions...');
      _syncPermissions();
    }
  }

  Future<void> _syncPermissions() async {
    final service = NotificationService();
    // In settings, we assume it's already initialized by Splash.
    // However, reScheduleAll has its own initialization guard.
    await service.reScheduleAll();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    await widget.storage.setNotificationSetting(key, value);
    setState(() {
      _settings[key] = value;
    });
    await _syncPermissions();
  }

  Future<void> _updateFrequency(String frequency) async {
    await widget.storage.setNotificationFrequency(frequency);
    setState(() {
      _settings['frequency'] = frequency;
    });
    await _syncPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = _settings['enabled'] ?? true;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Master Switch
          SwitchListTile(
            title: Text(l10n.enableNotifications, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(l10n.enableNotificationsDesc),
            value: isEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => _updateSetting('enabled', val),
          ),
          const Divider(),
          
          if (isEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                l10n.remindersSection,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            _buildSwitch(l10n.morningAdhkar, 'morning', '06:00 AM'),
            _buildSwitch(l10n.eveningAdhkar, 'evening', '05:30 PM'),
            _buildSwitch(l10n.sleepAdhkar, 'sleep', '10:00 PM'),
            _buildSwitch(l10n.surahKahf, 'kahf', l10n.surahKahf), // Or formatted time
            
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                l10n.inspirationsSection,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            CheckboxListTile(
              title: Text(l10n.floatingContent),
              subtitle: Text(l10n.floatingContentDesc),
              value: _settings['floating'] ?? true,
              activeColor: AppColors.primary,
              onChanged: (val) => _updateSetting('floating', val ?? true),
            ),
            
            // Frequency Selector
            if (_settings['floating'] == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.frequency, style: const TextStyle(fontSize: 13, color: AppColors.textSubtle)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'low', 
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(l10n.freqLow),
                            ),
                          ),
                          ButtonSegment(
                            value: 'medium', 
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(l10n.freqMedium),
                            ),
                          ),
                          ButtonSegment(
                            value: 'high', 
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(l10n.freqHigh),
                            ),
                          ),
                        ],
                        selected: { _settings['frequency'] ?? 'medium' },
                        onSelectionChanged: (Set<String> newSelection) {
                           _updateFrequency(newSelection.first);
                        },
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          selectedBackgroundColor: AppColors.primary,
                          selectedForegroundColor: Colors.white,
                          foregroundColor: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Overlay Permission (if not granted)
            FutureBuilder<bool>(
              future: NotificationService().isOverlayPermissionGranted(),
              builder: (context, snapshot) {
                // Removed the connectionState.waiting check as the Column will handle rendering
                
                final bool isGranted = snapshot.data ?? false;
                debugPrint('Overlay Permission Status in UI: $isGranted');

                return Column(
                  children: [
                    if (!isGranted && _settings['floating'] == true)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.layers_outlined, color: Colors.amber),
                            title: const Text('Grant Overlay Permission'),
                            subtitle: const Text('Required for floating window to appear over other apps.'),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final service = NotificationService();
                                final granted = await service.requestOverlayPermission();
                                if (granted) {
                                  setState(() {}); // Refresh UI
                                  await service.reScheduleAll();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Grant'),
                            ),
                          ),
                        ),
                      ),
                    
                    
                    // Android Optimization Tip
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              '⚠️ IMPORTANT (Android Optimization):',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'To ensure floating windows and reminders work reliably:',
                              style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '1. Enable "Display over other apps" or "Pop-up windows while in background" in App Settings.',
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '2. Set Battery Saver to "No Restrictions" or "Unrestricted" to prevent the system from killing background alerts.',
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /* 
                    // Test / Troubleshoot Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختبار التنبيهات (Troubleshoot)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => NotificationService().testMorningReminder(),
                            icon: const Icon(Icons.wb_sunny_outlined),
                            label: const Text('Test Morning Reminder (ID 106)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade100,
                              foregroundColor: Colors.orange.shade900,
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => NotificationService().testNotification(),
                                  icon: const Icon(Icons.notifications_active_outlined),
                                  label: const Text('Test Alert'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                    foregroundColor: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => NotificationService().testDelayedNotification(),
                                  icon: const Icon(Icons.timer_outlined),
                                  label: const Text('Delayed (20s)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade50,
                                    foregroundColor: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => NotificationService().testFloatingOverlay(),
                                  icon: const Icon(Icons.layers_outlined),
                                  label: const Text('Test Floating'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                    foregroundColor: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    */
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, String key, String time) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textSubtle)),
      value: _settings[key] ?? true,
      activeThumbColor: AppColors.primary,
      onChanged: (val) => _updateSetting(key, val),
    );
  }
}
