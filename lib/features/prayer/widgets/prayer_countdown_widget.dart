import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nusuk_for_iman/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers.dart';
import '../providers/prayer_providers.dart';

class PrayerCountdownWidget extends ConsumerStatefulWidget {
  const PrayerCountdownWidget({super.key});

  @override
  ConsumerState<PrayerCountdownWidget> createState() => _PrayerCountdownWidgetState();
}

class _PrayerCountdownWidgetState extends ConsumerState<PrayerCountdownWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayerAsync = ref.watch(nextPrayerProvider);
    final isArabic = ref.watch(hiveStorageProvider).getLanguage() == 'ar';

    return nextPrayerAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
      data: (nextPrayer) {
        final l10n = AppLocalizations.of(context);
        final prayerTimesToday = ref.watch(prayerTimesProvider);
        final prayerTimesTomorrow = ref.watch(tomorrowPrayerTimesProvider);

        return prayerTimesToday.when(
          loading: () => const SizedBox.shrink(),
          error: (err, st) => const SizedBox.shrink(),
          data: (timesToday) {
            DateTime? nextTime = timesToday.timeForPrayer(nextPrayer);
            bool isTomorrow = false;

            // If adhan says next is Fajr but today's Fajr is in the past, get tomorrow's
            if (nextTime == null || nextTime.isBefore(DateTime.now())) {
               nextTime = prayerTimesTomorrow.value?.timeForPrayer(Prayer.fajr);
               isTomorrow = true;
            }

            if (nextTime == null) return const SizedBox.shrink();

            String prayerName = nextPrayer.name;
            if (l10n != null) {
               switch(nextPrayer) {
                 case Prayer.fajr: prayerName = l10n.prayerFajr; break;
                 case Prayer.sunrise: prayerName = l10n.prayerSunrise; break;
                 case Prayer.dhuhr: prayerName = l10n.prayerDhuhr; break;
                 case Prayer.asr: prayerName = l10n.prayerAsr; break;
                 case Prayer.maghrib: prayerName = l10n.prayerMaghrib; break;
                 case Prayer.isha: prayerName = l10n.prayerIsha; break;
                 default: break;
               }
            }

            final now = DateTime.now();
            final diff = nextTime.difference(now);
            
            String formatDuration(Duration d) {
              if (d.isNegative) return '00:00:00';
              String twoDigits(int n) => n.toString().padLeft(2, "0");
              String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
              String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
              return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
            }

            final timeString = formatDuration(diff);

            return GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/prayer_times'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon with soft gold background
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Prayer Name & Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTomorrow 
                               ? (isArabic ? 'صلاة الفجر غداً' : 'Tomorrow\'s Fajr')
                               : prayerName,
                            style: AppTextStyles.heading(fontSize: 16).copyWith(
                              color: AppColors.primary,
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isTomorrow 
                               ? (isArabic ? 'موعد الصلاة القادمة' : 'Upcoming prayer time')
                               : (isArabic ? 'الوقت المتبقي' : 'Remaining time'),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary.withValues(alpha: 0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Countdown Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        timeString,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
