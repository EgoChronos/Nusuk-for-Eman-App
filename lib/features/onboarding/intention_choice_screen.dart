import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

import '../../core/intention/intention_provider.dart';

/// First-launch intention choice screen
/// User selects: sadaqah for her (default) or general remembrance
class IntentionChoiceScreen extends ConsumerWidget {
  const IntentionChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(intentionProvider);
    final isFirstLaunch = !ref.watch(intentionProvider.notifier).hasConfirmedIntention;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isFirstLaunch 
        ? null 
        : AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isFirstLaunch) ...[
                Icon(
                  Icons.nightlight_round,
                  size: 48,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'بسم الله الرحمن الرحيم',
                textDirection: TextDirection.rtl,
                style: AppTextStyles.calligraphy(
                  fontSize: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose your intention',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // Option 1: Sadaqah for her (default)
              _IntentionOption(
                title: 'صدقة جارية لروح إيمان محمد طايع',
                subtitle: 'Make this app sadaqah for her',
                isSelected: selected == IntentionType.forHer,
                onTap: () {
                  ref.read(intentionProvider.notifier).setIntention(
                    IntentionType.forHer,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Option 2: General remembrance
              _IntentionOption(
                title: 'ذكر عام',
                subtitle: 'Use for general remembrance',
                isSelected: selected == IntentionType.general,
                onTap: () {
                  ref.read(intentionProvider.notifier).setIntention(
                    IntentionType.general,
                  );
                },
              ),

              const SizedBox(height: 48),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Save the confirmation and continue
                    await ref.read(intentionProvider.notifier).confirmIntention();
                    
                    if (!context.mounted) return;
                    if (isFirstLaunch) {
                      Navigator.of(context).pushReplacementNamed('/main');
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isFirstLaunch ? 'Continue · متابعة' : 'Save · حفظ',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntentionOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntentionOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textDirection: TextDirection.rtl,
                    style: isSelected 
                      ? AppTextStyles.calligraphy(fontSize: 20, color: AppColors.primary).copyWith(fontWeight: FontWeight.bold)
                      : AppTextStyles.arabicBody(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.textSubtle,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
