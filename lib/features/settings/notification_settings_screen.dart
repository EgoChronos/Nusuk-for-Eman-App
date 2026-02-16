import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/sources/hive_storage.dart';
import '../../core/services/notification_service.dart'; // Import to reschedule
import 'permission_setup_screen.dart';
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
              
                    // New Unified Permission Management Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.settings_suggest_outlined, color: AppColors.primary),
                          title: Text(l10n.runSettings, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(l10n.runSettingsDesc),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PermissionSetupScreen()),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
