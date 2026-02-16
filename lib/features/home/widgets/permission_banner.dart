import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../settings/permission_setup_screen.dart';
import 'package:nusuk_for_iman/l10n/app_localizations.dart';

class PermissionBanner extends ConsumerStatefulWidget {
  const PermissionBanner({super.key});

  @override
  ConsumerState<PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends ConsumerState<PermissionBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(permissionStateProvider);

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (status) {
        if (status.isAllGranted || _dismissed) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PermissionSetupScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Directionality(
                        textDirection: Localizations.localeOf(context).languageCode == 'ar' 
                            ? TextDirection.rtl : TextDirection.ltr,
                        child: Text(
                          AppLocalizations.of(context)!.permissionBannerAlert(status.grantedCount),
                          style: AppTextStyles.body().copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.orange),
                      onPressed: () => setState(() => _dismissed = true),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
