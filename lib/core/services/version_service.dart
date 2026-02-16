import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/sources/supabase_service.dart';

enum UpdateType { none, optional, force }

class VersionCheckResult {
  final UpdateType type;
  final String? latestVersion;
  final String? storeUrl;

  VersionCheckResult({
    this.type = UpdateType.none,
    this.latestVersion,
    this.storeUrl,
  });
}

class VersionService {
  final SupabaseService _supabaseService;

  VersionService(this._supabaseService);

  /// Checks if an update is required.
  /// Implements Graceful Degradation: If anything fails, it returns UpdateType.none.
  Future<VersionCheckResult> checkForUpdates() async {
    try {
      debugPrint('🚀 Starting version check...');
      
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      debugPrint('📱 Current App Version: $currentVersion');

      // 2. Fetch version config from Supabase with a timeout
      final config = await _supabaseService.getAppConfig('version_config')
          .timeout(const Duration(seconds: 5));

      if (config == null) {
        debugPrint('⚠️ No version config found or request failed. Failing open.');
        return VersionCheckResult(type: UpdateType.none);
      }

      final String minVersion = config['min_version'] ?? '0.0.0';
      final String latestVersion = config['latest_version'] ?? '0.0.0';
      final String storeUrl = config['store_url'] ?? '';

      debugPrint('🌐 Supabase Config: min=$minVersion, latest=$latestVersion');

      // 3. Compare versions
      if (_isVersionLower(currentVersion, minVersion)) {
        debugPrint('⛔ Force update required!');
        return VersionCheckResult(
          type: UpdateType.force,
          latestVersion: latestVersion,
          storeUrl: storeUrl,
        );
      } else if (_isVersionLower(currentVersion, latestVersion)) {
        debugPrint('💡 Optional update available.');
        return VersionCheckResult(
          type: UpdateType.optional,
          latestVersion: latestVersion,
          storeUrl: storeUrl,
        );
      }

      debugPrint('✅ App is up to date.');
      return VersionCheckResult(type: UpdateType.none);
    } catch (e) {
      debugPrint('❌ Version check failed: $e. Graceful degradation: failing open.');
      return VersionCheckResult(type: UpdateType.none);
    }
  }

  /// Returns true if [current] is lower than [target] (Semantic Versioning)
  bool _isVersionLower(String current, String target) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final targetParts = target.split('.').map(int.parse).toList();

      final maxLength = currentParts.length > targetParts.length 
          ? currentParts.length 
          : targetParts.length;

      for (int i = 0; i < maxLength; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final targetPart = i < targetParts.length ? targetParts[i] : 0;

        if (currentPart < targetPart) return true;
        if (currentPart > targetPart) return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error parsing versions: $e');
      return false;
    }
  }
}
