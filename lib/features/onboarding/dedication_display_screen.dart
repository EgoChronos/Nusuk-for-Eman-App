import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/intention/intention_provider.dart';
import '../../app.dart';
import '../../core/providers.dart';

class DedicationDisplayScreen extends ConsumerStatefulWidget {
  const DedicationDisplayScreen({super.key});

  @override
  ConsumerState<DedicationDisplayScreen> createState() => _DedicationDisplayScreenState();
}

class _DedicationDisplayScreenState extends ConsumerState<DedicationDisplayScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    final storage = ref.read(hiveStorageProvider);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MainScreen(storage: storage),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intentionNotifier = ref.watch(intentionProvider.notifier);
    final language = ref.watch(localeProvider);
    final text = intentionNotifier.getDedicationText(arabic: language == 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.nightlight_round,
                  size: 48,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 24),
                Text(
                  'بسم الله الرحمن الرحيم',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.calligraphy(
                    fontSize: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    text,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.calligraphy(
                      fontSize: 24,
                      color: AppColors.primary,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
