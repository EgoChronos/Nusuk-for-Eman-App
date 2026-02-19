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
    final l10n = AppLocalizations.of(context);

    return nextPrayerAsync.when(
      loading: () => _buildSkeleton(context),
      error: (err, st) => _buildErrorTile(context, l10n),
      data: (nextPrayer) {
        final prayerTimesTodayAsync = ref.watch(prayerTimesProvider);
        final prayerTimesTomorrowAsync = ref.watch(tomorrowPrayerTimesProvider);

        return prayerTimesTodayAsync.when(
          loading: () => _buildSkeleton(context),
          error: (err, st) => _buildErrorTile(context, l10n),
          data: (timesToday) {
            return prayerTimesTomorrowAsync.when(
              loading: () => _buildSkeleton(context),
              error: (err, st) => _buildErrorTile(context, l10n),
              data: (timesTomorrow) {
                DateTime? nextTime = timesToday.timeForPrayer(nextPrayer);
                bool isTomorrow = false;

                // Logic: If the 'next' prayer found by adhan today is already passed,
                // or if adhan returned 'none' (which nextPrayerProvider maps to Fajr),
                // we use tomorrow's Fajr.
                if (nextTime == null || nextTime.isBefore(DateTime.now())) {
                  nextTime = timesTomorrow.timeForPrayer(Prayer.fajr);
                  isTomorrow = true;
                }

                if (nextTime == null) return _buildErrorTile(context, l10n);

                String prayerName = nextPrayer.name;
                if (l10n != null) {
                  switch (nextPrayer) {
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
                    height: 72, // Standardized fixed height
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(36), // Fully rounded for 72 height
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                prayerName,
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
      },
    );
  }

  Widget _buildErrorTile(BuildContext context, AppLocalizations? l10n) {
    return GestureDetector(
      onTap: () => ref.read(prayerLocationProvider.notifier).refreshLocation(),
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n?.locationError ?? 'Location needed for prayer times',
                style: const TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 72, // Matches the height of the real pill
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(36),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 140,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
