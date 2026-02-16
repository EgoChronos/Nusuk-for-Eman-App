import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:nusuk_for_iman/l10n/app_localizations.dart';

class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  ConsumerState<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh immediately on entry
    Future.microtask(() => ref.read(permissionStateProvider.notifier).refresh(silent: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Small delay helps Android settings propagate
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
           ref.read(permissionStateProvider.notifier).refresh(silent: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(permissionStateProvider);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.permissionSetupTitle, style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (status) {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          return Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.permissionSetupDesc,
                    style: AppTextStyles.body().copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 25),
                  
                  _PermissionCard(
                    title: l10n.overlayPermissionTitle,
                    description: l10n.overlayPermissionDesc,
                    icon: Icons.layers_outlined,
                    isGranted: status.overlayGranted,
                    onTap: () => ref.read(permissionServiceProvider).requestOverlay(),
                  ),
                  
                  _PermissionCard(
                    title: l10n.batteryPermissionTitle,
                    description: l10n.batteryPermissionDesc,
                    icon: Icons.battery_saver_outlined,
                    isGranted: !status.batteryOptimized,
                    onTap: () => ref.read(permissionServiceProvider).requestIgnoreBatteryOptimizations(),
                  ),
                  
                  _PermissionCard(
                    title: l10n.appearancePermissionTitle,
                    description: l10n.appearancePermissionDesc,
                    icon: Icons.settings_suggest_outlined,
                    isGranted: status.backgroundPopupsGranted,
                    onTap: () => ref.read(permissionServiceProvider).openBackgroundPermissions(),
                  ),

                  if (status.isAllGranted)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.accent, size: 60),
                            const SizedBox(height: 10),
                            Text(
                              l10n.allPermissionsGranted,
                              style: AppTextStyles.heading().copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onTap;

  const _PermissionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isGranted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isGranted ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isGranted ? AppColors.accent : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isGranted ? AppColors.accent.withValues(alpha: 0.2) : AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isGranted ? AppColors.accent : AppColors.primary, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading().copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(description, style: AppTextStyles.body().copyWith(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isGranted)
                const Icon(Icons.check_circle, color: AppColors.accent)
              else
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
