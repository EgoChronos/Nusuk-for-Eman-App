import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class UpdateDialogs {
  /// Shows a non-dismissible dialog for force updates.
  static Future<void> showForceUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String storeUrl,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'تحديث إجباري',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update, size: 60, color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                'يتوفر إصدار جديد ($latestVersion) يحتوي على تحسينات هامة. يرجى التحديث للمتابعة.',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _launchStore(storeUrl),
                child: const Text('تحديث الآن', style: TextStyle(fontFamily: 'Amiri')),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Shows a dismissible dialog for optional updates.
  static Future<void> showOptionalUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String storeUrl,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تحديث جديد متاح',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'يتوفر إصدار جديد ($latestVersion). هل تود التحديث الآن؟',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss();
            },
            child: const Text('لاحقاً', style: TextStyle(fontFamily: 'Amiri')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              _launchStore(storeUrl);
              Navigator.pop(context);
              onDismiss();
            },
            child: const Text('تحديث', style: TextStyle(fontFamily: 'Amiri')),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchStore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
