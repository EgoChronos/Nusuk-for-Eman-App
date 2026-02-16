import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sources/hive_storage.dart';
import '../data/sources/quran_local_source.dart';
import '../data/repositories/quran_repository.dart';
import '../data/repositories/reward_repository.dart';
import '../data/sources/audio_download_service.dart';
import '../data/sources/audio_player_service.dart';
import '../data/sources/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/version_service.dart';

// Storage
final hiveStorageProvider = Provider<HiveStorage>((ref) {
  throw UnimplementedError('HiveStorage must be initialized in main.dart');
});

// Settings State
final themeProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return storage.isDarkMode();
});

final localeProvider = StateProvider<String>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return storage.getLanguage();
});

// Services
// Services

// Mutable state for Supabase
final supabaseServiceStateProvider = StateProvider<SupabaseService?>((ref) => null);

// Public provider that safe-guards access
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final service = ref.watch(supabaseServiceStateProvider);
  if (service == null) throw UnimplementedError('SupabaseService must be initialized in Splash Screen');
  return service;
});

// Mutable state for Audio
final audioPlayerServiceStateProvider = StateProvider<AudioPlayerService?>((ref) => null);

// Public provider that safe-guards access
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = ref.watch(audioPlayerServiceStateProvider);
  if (service == null) throw UnimplementedError('AudioPlayerService must be initialized in Splash Screen');
  return service;
});

final audioDownloadServiceProvider = Provider<AudioDownloadService>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return AudioDownloadService(storage);
});

// Data Sources
final quranLocalSourceProvider = Provider<QuranLocalSource>((ref) {
  return QuranLocalSource();
});

// Repositories
final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  final localSource = ref.watch(quranLocalSourceProvider);
  return QuranRepository(localSource, storage);
});

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return RewardRepository(storage);
});

// Notifications
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Version Check
final versionServiceProvider = Provider<VersionService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return VersionService(supabase);
});
