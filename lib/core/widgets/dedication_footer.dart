import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../intention/intention_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Subtle dedication footer shown at bottom of screens
/// Displays the dedication message based on current intention
class DedicationFooter extends ConsumerWidget {
  const DedicationFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for reactivity; value used via notifier below
    ref.watch(intentionProvider);
    final notifier = ref.read(intentionProvider.notifier);
    final text = notifier.getDedicationText();

    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.arabicBody(fontSize: 14).copyWith(
          color: AppColors.textSubtle,
        ),
      ),
    );
  }
}
