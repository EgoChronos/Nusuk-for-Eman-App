import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// "Donate reward" / "I made duaa" style button
/// Used across dhikr, duaa, and quran screens
class RewardButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const RewardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.favorite_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: AppTextStyles.calligraphy(
            fontSize: 18,
            color: Colors.white,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
