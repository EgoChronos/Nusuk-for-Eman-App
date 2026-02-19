import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../data/sources/hive_storage.dart';
import 'notification_settings_screen.dart';
import 'package:nusuk_for_iman/l10n/app_localizations.dart';
import '../../core/intention/intention_provider.dart';
import '../onboarding/intention_choice_screen.dart';

/// Settings screen — font, theme, language, intention, privacy
class SettingsScreen extends ConsumerStatefulWidget {
  final HiveStorage storage;
  // Callback no longer needed as we use Riverpod
  final VoidCallback? onThemeChanged;

  const SettingsScreen({super.key, required this.storage, this.onThemeChanged});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late double _fontSize;
  
  // These will be read from providers directly in build or initialized here
  // But strictly speaking, for local UI state of slider/switch, we can keep them or use the provider value.
  // Using provider values directly ensures sync.

  @override
  void initState() {
    super.initState();
    _fontSize = widget.storage.getFontSize();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final language = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: const TextStyle(fontFamily: 'Amiri', fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Lifetime Stats
          _SectionHeader(title: l10n.myStats, subtitle: 'My Lifetime Stats'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: l10n.ayahsRead,
                        value: '${widget.storage.getTotalAyahLifeCount()}',
                        icon: Icons.menu_book,
                      ),
                      _StatItem(
                        label: l10n.dhikrTasbeeh,
                        value: '${widget.storage.getTotalDhikrAllTime()}',
                        icon: Icons.fingerprint,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                       _StatItem(
                        label: l10n.duaasMade,
                        value: '${widget.storage.getDuaaCount()}',
                        icon: Icons.volunteer_activism,
                      ),
                      _StatItem(
                        label: l10n.listeningTime,
                        value: _formatDuration(widget.storage.getListeningSeconds()),
                        icon: Icons.headset,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Font size
          _SectionHeader(title: l10n.fontSizeTitle, subtitle: 'Font Size'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text('بسم الله الرحمن الرحيم', textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'Amiri', fontSize: _fontSize, color: AppColors.textPrimary)),
                Slider(
                  value: _fontSize, min: 18, max: 40, divisions: 22,
                  activeColor: AppColors.primary,
                  onChanged: (v) async {
                    setState(() => _fontSize = v);
                    await widget.storage.setFontSize(v);
                  },
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
 
          // Notifications
          _SectionHeader(title: l10n.manageNotifications, subtitle: 'Notifications'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              title: Text(l10n.manageNotifications, style: const TextStyle(fontFamily: 'Amiri', fontSize: 16)),
              subtitle: Text(l10n.manageNotificationsDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSubtle),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationSettingsScreen(storage: widget.storage),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Prayer Times
          _SectionHeader(title: l10n.prayerTimesSettings, subtitle: 'Salah'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.primary),
              title: Text(l10n.prayerTimesSettings, style: const TextStyle(fontFamily: 'Amiri', fontSize: 16)),
              subtitle: Text(l10n.calculationMethods),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSubtle),
              onTap: () => Navigator.of(context).pushNamed('/prayer_times'),
            ),
          ),
          const SizedBox(height: 12),

          // App Dedication
          _SectionHeader(title: language == 'ar' ? 'تخصيص التطبيق' : 'App Dedication', subtitle: 'Dedication'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.volunteer_activism_outlined, color: AppColors.primary),
              title: Text(
                language == 'ar' ? 'تغيير نية العمل' : 'Change App Dedication',
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
              ),
              subtitle: Text(
                // Watch intentionProvider to trigger rebuild when it changes
                () {
                  ref.watch(intentionProvider);
                  return ref.read(intentionProvider.notifier).getDedicationText(arabic: language == 'ar');
                }(),
                style: const TextStyle(fontSize: 13),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSubtle),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IntentionChoiceScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Theme
          _SectionHeader(title: l10n.themeTitle, subtitle: 'Theme'),
          Card(
            child: SwitchListTile(
              title: Text(l10n.darkMode, style: const TextStyle(fontFamily: 'Amiri', fontSize: 16)),
              subtitle: Text(l10n.darkModeDesc),
              value: isDark,
              activeThumbColor: AppColors.primary,
              onChanged: (v) async {
                // Update provider immediately for UI
                ref.read(themeProvider.notifier).state = v;
                // Save to storage
                await widget.storage.setDarkMode(v);
              },
            ),
          ),
          const SizedBox(height: 12),
 
          // Language
          _SectionHeader(title: l10n.languageTitle, subtitle: 'Language'),
          Card(
            child: Column(children: [
              // ignore: deprecated_member_use
              RadioListTile<String>(
                title: const Text('العربية', style: TextStyle(fontFamily: 'Amiri')),
                // ignore: deprecated_member_use
                value: 'ar', groupValue: language, activeColor: AppColors.primary,
                // ignore: deprecated_member_use
                onChanged: (v) async {
                  if (v != null) {
                    ref.read(localeProvider.notifier).state = v;
                    await widget.storage.setLanguage(v);
                  }
                },
              ),
              // ignore: deprecated_member_use
              RadioListTile<String>(
                title: const Text('English'),
                // ignore: deprecated_member_use
                value: 'en', groupValue: language, activeColor: AppColors.primary,
                // ignore: deprecated_member_use
                onChanged: (v) async {
                  if (v != null) {
                    ref.read(localeProvider.notifier).state = v;
                    await widget.storage.setLanguage(v);
                  }
                },
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Reset progress
          _SectionHeader(title: l10n.resetProgress, subtitle: 'Reset'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.refresh, color: Colors.red),
              title: Text(l10n.resetProgress, style: const TextStyle(fontFamily: 'Amiri', fontSize: 16)),
              subtitle: Text(l10n.resetProgressDesc),
              onTap: () => _showResetDialog(l10n),
            ),
          ),
          const SizedBox(height: 12),

          // About
          _SectionHeader(title: l10n.aboutApp, subtitle: 'About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(
                  l10n.appName,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.calligraphy(
                    fontSize: 32,
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),

                RichText(
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: language == 'ar' ? 'هذا العمل هدية لروح ' : 'This deed is gifted to '),
                      TextSpan(
                        text: language == 'ar' ? AppStrings.dedicatedName : 'Eman Mohammed Tayee',
                        style: AppTextStyles.calligraphy(
                          fontSize: language == 'ar' ? 22 : 20,
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Version 1.0.0', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSubtle)),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Privacy
          _SectionHeader(title: l10n.privacy, subtitle: 'Privacy'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(AppStrings.privacyStatementEn, // Keep English privacy policy for now or localize if critical
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  void _showResetDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetConfirmTitle),
        content: Text(l10n.resetConfirmContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              await widget.storage.resetAllProgress();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                setState(() {}); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.resetProgress)));
              }
            },
            child: Text(l10n.reset, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary.withValues(alpha: 0.7)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSubtle),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    // Force LTR layout to ensure English subtitle is always on the left and Arabic title on the right
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          Text(title, textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ]),
      ),
    );
  }
}
