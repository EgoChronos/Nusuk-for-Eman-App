import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nusuk_for_iman/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/prayer_providers.dart';

import 'package:just_audio/just_audio.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  late AudioPlayer _audioPlayer;
  String? _playingSoundName;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // Listen to player state to clear playing name when finished or stopped
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed || 
          !state.playing) {
        if (mounted && _playingSoundName != null) {
          setState(() {
            _playingSoundName = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPreview(String sound) async {
    if (sound == 'default') return;

    // Toggle stop if same sound is already playing
    if (_playingSoundName == sound && _audioPlayer.playing) {
      await _audioPlayer.stop();
      return;
    }

    try {
      setState(() {
        _playingSoundName = sound;
      });
      await _audioPlayer.setAsset('assets/audio/athan/$sound.mp3');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing Athan preview: $e');
      if (mounted) {
        setState(() {
          _playingSoundName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تنبيه: لم يتم العثور على ملف الصوت assets/audio/athan/$sound.mp3'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final locationAsync = ref.watch(prayerLocationProvider);
    final nextPrayerAsync = ref.watch(nextPrayerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, locationAsync, l10n),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCalculationSettings(context, l10n),
                  const SizedBox(height: 24),
                  _buildNotificationSettings(context, l10n),
                  const SizedBox(height: 32),
                  _buildSectionHeader(l10n?.prayerSchedule ?? 'جدول الصلوات'),
                  const SizedBox(height: 12),
                  Text(
                    DateFormat.yMMMMd().format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSubtle,
                      fontFamily: 'Amiri',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          prayerTimesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, st) => SliverToBoxAdapter(
              child: _buildErrorState(context, ref, err.toString(), l10n),
            ),
            data: (prayerTimes) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _PrayerTile(
                    name: l10n?.prayerFajr ?? 'Fajr',
                    time: prayerTimes.fajr,
                    isNext: nextPrayerAsync.value == Prayer.fajr,
                    icon: Icons.wb_twilight,
                  ),
                  _PrayerTile(
                    name: l10n?.prayerSunrise ?? 'Sunrise',
                    time: prayerTimes.sunrise,
                    isNext: nextPrayerAsync.value == Prayer.sunrise,
                    icon: Icons.wb_sunny_outlined,
                  ),
                  _PrayerTile(
                    name: l10n?.prayerDhuhr ?? 'Dhuhr',
                    time: prayerTimes.dhuhr,
                    isNext: nextPrayerAsync.value == Prayer.dhuhr,
                    icon: Icons.wb_sunny,
                  ),
                  _PrayerTile(
                    name: l10n?.prayerAsr ?? 'Asr',
                    time: prayerTimes.asr,
                    isNext: nextPrayerAsync.value == Prayer.asr,
                    icon: Icons.wb_cloudy_outlined,
                  ),
                  _PrayerTile(
                    name: l10n?.prayerMaghrib ?? 'Maghrib',
                    time: prayerTimes.maghrib,
                    isNext: nextPrayerAsync.value == Prayer.maghrib,
                    icon: Icons.nightlight_round,
                  ),
                  _PrayerTile(
                    name: l10n?.prayerIsha ?? 'Isha',
                    time: prayerTimes.isha,
                    isNext: nextPrayerAsync.value == Prayer.isha,
                    icon: Icons.bedtime,
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AsyncValue<Position> locationAsync, AppLocalizations? l10n) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          l10n?.prayerTimesSettings ?? 'إعدادات المواقيت',
          style: const TextStyle(
            color: Colors.white, 
            fontFamily: 'Amiri', 
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [Shadow(color: Colors.black26, blurRadius: 10)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative Pattern (Low Opacity)
            Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/black-linen.png', // More reliable fallback/subtle texture
                repeat: ImageRepeat.repeat,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            // Location Pill
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      locationAsync.when(
                        data: (pos) => Text(
                          '${pos.latitude.toStringAsFixed(2)}°, ${pos.longitude.toStringAsFixed(2)}°',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        loading: () => const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        error: (err, st) => Text(l10n?.locationUnknown ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCalculationSettings(BuildContext context, AppLocalizations? l10n) {
    final currentMethod = ref.watch(calculationMethodProvider);
    final currentMadhab = ref.watch(madhabProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n?.calculationMethodsHeader ?? 'إعدادات الحساب'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.settings_suggest_outlined,
                label: l10n?.calculationMethods ?? 'Calculation Method',
                value: _getMethodName(currentMethod, l10n),
                onTap: () => _showSelectionDialog<CalculationMethod>(
                  context: context,
                  title: l10n?.selectMethod ?? 'Select Method',
                  items: [
                    CalculationMethod.muslim_world_league,
                    CalculationMethod.egyptian,
                    CalculationMethod.umm_al_qura,
                    CalculationMethod.karachi,
                  ],
                  currentValue: currentMethod,
                  itemLabel: (m) => _getMethodName(m, l10n),
                  onSelected: (m) {
                    ref.read(calculationMethodProvider.notifier).setMethod(m);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: AppColors.primary.withValues(alpha: 0.05)),
              ),
              _SettingRow(
                icon: Icons.gavel_outlined,
                label: l10n?.selectMadhab ?? 'Madhab',
                value: _getMadhabName(currentMadhab, l10n),
                onTap: () => _showSelectionDialog<Madhab>(
                  context: context,
                  title: l10n?.selectMadhab ?? 'Select Madhab',
                  items: Madhab.values,
                  currentValue: currentMadhab,
                  itemLabel: (m) => _getMadhabName(m, l10n),
                  onSelected: (m) {
                    ref.read(madhabProvider.notifier).setMadhab(m);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings(BuildContext context, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n?.notificationsHeader ?? 'إعدادات التنبيهات'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.volume_up_outlined,
                label: l10n?.athanSound ?? 'صوت الأذان',
                value: _getAthanSoundName(ref.watch(athanSoundProvider)),
                trailing: ref.watch(athanSoundProvider) != 'default' 
                  ? IconButton(
                      icon: Icon(
                        _playingSoundName == ref.read(athanSoundProvider)
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_outline_rounded,
                        color: AppColors.accent,
                      ),
                      onPressed: () => _playPreview(ref.read(athanSoundProvider)),
                    )
                  : null,
                onTap: () => _showSelectionDialog<String>(
                  context: context,
                  title: l10n?.selectAthan ?? 'اختر صوت الأذان',
                  items: ['default', 'athan_makkah', 'athan_madinah', 'athan_aqsa', 'athan_egypt'],
                  currentValue: ref.read(athanSoundProvider),
                  itemLabel: _getAthanSoundName,
                  onSelected: (s) {
                    ref.read(athanSoundProvider.notifier).setSound(s);
                    _playPreview(s);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: AppColors.primary.withValues(alpha: 0.05)),
              ),
              _SettingRow(
                icon: Icons.access_time_rounded,
                label: l10n?.prePrayerAlert ?? 'تنبيه قبل الصلاة',
                value: _getPreReminderName(ref.watch(prePrayerReminderProvider), l10n),
                onTap: () => _showSelectionDialog<int>(
                  context: context,
                  title: l10n?.selectReminder ?? 'اختر مدة التنبيه',
                  items: [0, 5, 10, 15, 30],
                  currentValue: ref.read(prePrayerReminderProvider),
                  itemLabel: (m) => _getPreReminderName(m, l10n),
                  onSelected: (m) {
                    ref.read(prePrayerReminderProvider.notifier).setMinutes(m);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: AppColors.primary.withValues(alpha: 0.05)),
              ),
              _SettingRow(
                icon: Icons.wb_sunny_outlined,
                label: l10n?.sunriseAlert ?? 'تنبيه الشروق',
                value: ref.watch(sunriseAlertProvider) ? (l10n?.enabled ?? 'مفعل') : (l10n?.disabled ?? 'معطل'),
                onTap: () {
                  ref.read(sunriseAlertProvider.notifier).setEnabled(!ref.read(sunriseAlertProvider));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSelectionDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required T currentValue,
    required String Function(T) itemLabel,
    required Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item == currentValue;
                  final isAthanSelection = T == String && items.any((e) => e.toString().contains('athan_'));

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    title: Text(
                      itemLabel(item),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    leading: isSelected 
                      ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22) 
                      : const Icon(Icons.circle_outlined, color: AppColors.divider, size: 22),
                    trailing: isAthanSelection && item.toString() != 'default'
                      ? IconButton(
                          icon: Icon(
                            _playingSoundName == item.toString()
                                ? Icons.stop_circle
                                : Icons.play_circle_fill,
                            color: AppColors.accent,
                          ),
                          onPressed: () => _playPreview(item.toString()),
                        )
                      : null,
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.location_off, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(error == 'locationError' ? (l10n?.locationError ?? error) : error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(prayerLocationProvider.notifier).refreshLocation(),
            child: Text(l10n?.reset ?? 'Retry'),
          ),
        ],
      ),
    );
  }

  String _getMethodName(CalculationMethod method, AppLocalizations? l10n) {
    switch (method) {
      case CalculationMethod.muslim_world_league: return l10n?.methodMWL ?? 'MWL';
      case CalculationMethod.egyptian: return l10n?.methodEgyptian ?? 'Egyptian';
      case CalculationMethod.umm_al_qura: return l10n?.methodUmmAlQura ?? 'Umm al-Qura';
      case CalculationMethod.karachi: return 'Karachi';
      default: return method.name;
    }
  }

  String _getMadhabName(Madhab madhab, AppLocalizations? l10n) {
    switch (madhab) {
      case Madhab.shafi: return l10n?.madhabShafi ?? 'Shafi';
      case Madhab.hanafi: return l10n?.madhabHanafi ?? 'Hanafi';
    }
  }

  String _getAthanSoundName(String sound) {
    switch (sound) {
      case 'default': return 'افتراضي';
      case 'athan_makkah': return 'مكة المكرمة';
      case 'athan_madinah': return 'المدينة المنورة';
      case 'athan_aqsa': return 'المسجد الأقصى';
      case 'athan_egypt': return 'مصر';
      default: return sound;
    }
  }

  String _getPreReminderName(int minutes, AppLocalizations? l10n) {
    if (minutes == 0) return l10n?.off ?? 'معطل';
    return '$minutes ${l10n?.minutes ?? 'دقائق'}';
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSubtle, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSubtle, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  final String name;
  final DateTime time;
  final bool isNext;
  final IconData icon;

  const _PrayerTile({
    required this.name,
    required this.time,
    required this.isNext,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNext ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isNext ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.05),
          width: isNext ? 1.5 : 1,
        ),
        boxShadow: isNext ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ] : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isNext ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isNext ? AppColors.primary : AppColors.textSubtle, size: 24),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
            color: isNext ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (name != 'الشروق' || true) // Placeholder for enabled check
              Icon(
                Icons.notifications_active_outlined, 
                size: 16, 
                color: isNext ? AppColors.primary : AppColors.textSubtle.withValues(alpha: 0.5)
              ),
            const SizedBox(width: 8),
            Text(
              DateFormat.jm().format(time),
              style: TextStyle(
                fontSize: 18,
                fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                color: isNext ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
