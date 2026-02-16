import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/dedication_footer.dart';
import '../../core/widgets/reward_button.dart';
import '../../data/sources/hive_storage.dart';
import '../../core/providers.dart'; // Ensure providers are imported for supabaseServiceProvider
import '../../data/sources/supabase_service.dart';
import 'package:nusuk_for_iman/l10n/app_localizations.dart';

/// Home screen — the heart of the app
class HomeScreen extends ConsumerWidget {
  final HiveStorage storage;
  final Function(int) onTabChange;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRead = storage.getLastReadPosition();
    final isArabic = storage.getLanguage() == 'ar';

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Scaffold();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.appName,
          style: AppTextStyles.calligraphy(
            fontSize: 28,
            color: AppColors.primary,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // ── Dedication Header ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: 32,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.dedicatedName,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.calligraphy(
                        fontSize: 36,
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        children: [
                          TextSpan(text: isArabic ? 'هذا العمل هدية لروح ' : 'This deed is gifted to '),
                          TextSpan(
                            text: isArabic ? AppStrings.dedicatedName : 'Eman Mohammed Tayee',
                            style: AppTextStyles.calligraphy(
                              fontSize: isArabic ? 20 : 18,
                              color: AppColors.accent,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Quick Actions ──
              if (lastRead != null)
                _ActionCard(
                  icon: Icons.menu_book_rounded,
                  title: l10n.continueReading,
                  subtitle: 'Surah ${lastRead['surah']}, Ayah ${lastRead['ayah']}',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/quran/read',
                      arguments: lastRead,
                    );
                  },
                ),

              _ActionCard(
                icon: Icons.headphones_rounded,
                title: l10n.audioTitle,
                subtitle: l10n.continueFromLeftOff,
                onTap: () {
                  // Navigate to audio tab
                  onTabChange(3);
                },
              ),

              _ActionCard(
                icon: Icons.spa_rounded,
                title: l10n.todaysDhikr,
                subtitle: l10n.tasbeehToday(storage.getTasbeehCount()),
                onTap: () {
                  onTabChange(2);
                },
              ),

              const SizedBox(height: 16),

              // ── Make Duaa Button ──
              RewardButton(
                label: '${l10n.makeDuaa} 🤲',
                icon: Icons.favorite,
                onPressed: () {
                  Navigator.of(context).pushNamed('/duaa');
                },
              ),

              const SizedBox(height: 24),

              // ── Global Impact Summary ──
              _GlobalImpactCard(storage: storage),


              const SizedBox(height: 8),

              const SizedBox(height: 8),
              const DedicationFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSubtle,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSubtle,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSubtle,
          ),
        ),
      ],
    );
  }
}

class _GlobalImpactCard extends ConsumerWidget {
  final HiveStorage storage;
  const _GlobalImpactCard({required this.storage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access Supabase service if available
    final supabaseService = ref.watch(supabaseServiceProvider);
    final isArabic = storage.getLanguage() == 'ar';

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.globalImpact,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(text: isArabic ? 'هذا العمل هدية لروح ' : 'This deed is gifted to '),
                TextSpan(
                  text: isArabic ? AppStrings.dedicatedName : 'Eman Mohammed Tayee',
                  style: AppTextStyles.calligraphy(
                    fontSize: isArabic ? 20 : 18,
                    color: AppColors.accent,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.liveUpdatesDesc,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 16),

          
          StreamBuilder<Map<String, dynamic>>(
            stream: _getStream(supabaseService),
            builder: (context, snapshot) {
              int totalAyahs = 0;
              int totalDhikr = 0;
              int totalSeconds = 0;
              int totalDuaa = 0;
              bool isOffline = false;

              if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                 // Live data from Supabase — cache it for offline use
                 final data = snapshot.data!;
                 totalAyahs = data['ayahs_read'] ?? 0;
                 totalDhikr = data['dhikr_count'] ?? 0;
                 totalSeconds = data['listening_seconds'] ?? 0;
                 totalDuaa = data['duaa_count'] ?? 0;
                 storage.cacheGlobalStats(data);
              } else {
                 // Offline or not yet connected — use cached global stats
                 isOffline = true;
                 final cached = storage.getCachedGlobalStats();
                 if (cached != null) {
                   totalAyahs = cached['ayahs_read'] ?? 0;
                   totalDhikr = cached['dhikr_count'] ?? 0;
                   totalSeconds = cached['listening_seconds'] ?? 0;
                   totalDuaa = cached['duaa_count'] ?? 0;
                 }
                 // If no cache either (first launch ever), values stay 0
              }

              return Column(
                children: [
                  if (isOffline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, size: 12, color: AppColors.textSubtle.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            l10n.lastSavedUpdate,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSubtle.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: l10n.quranTitle,
                        value: '$totalAyahs',
                        icon: Icons.menu_book,
                      ),
                      _StatItem(
                        label: l10n.dhikrTitle,
                        value: '$totalDhikr',
                        icon: Icons.spa,
                      ),
                      _StatItem(
                        label: l10n.duaaTitle,
                        value: '$totalDuaa',
                        icon: Icons.favorite,
                      ),
                      _StatItem(
                        label: l10n.audioTitle,
                        value: '${totalSeconds ~/ 60}m',
                        icon: Icons.headphones,
                      ),
                    ],
                  ),

                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<Map<String, dynamic>> _getStream(Object? service) {
    try {
      if (service is SupabaseService) {
        return service.getGlobalStats();
      }
      return const Stream.empty();
    } catch (e) {
      return const Stream.empty();
    }
  }
}
