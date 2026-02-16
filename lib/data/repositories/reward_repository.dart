import '../sources/hive_storage.dart';
import '../models/reward_log.dart';

/// Repository for reward tracking
/// Supabase-ready: aggregate counters can sync to shared cloud counter
class RewardRepository {
  final HiveStorage _storage;

  RewardRepository(this._storage);

  RewardLog getRewardLog() => _storage.getRewardLog();

  Future<void> saveRewardLog(RewardLog log) => _storage.saveRewardLog(log);

  // Duaa
  int getDuaaCount() => _storage.getDuaaCount();
  int getDuaaCountToday() => _storage.getDuaaCountToday();
  Future<void> incrementDuaa() => _storage.incrementDuaa();

  // Dhikr
  int getTasbeehCount() => _storage.getTasbeehCount();
  Future<void> incrementTasbeeh() => _storage.incrementTasbeeh();
  int getDhikrCount(String id) => _storage.getDhikrCount(id);
  Future<void> setDhikrCount(String id, int count) =>
      _storage.setDhikrCount(id, count);

  // Listening
  int getListeningSeconds() => _storage.getListeningSeconds();
  Future<void> addListeningSeconds(int seconds) => _storage.addListeningSeconds(seconds);

  // Qur'an pages
  int getTotalAyahsRead() => _storage.getTotalAyahsRead();

  // Reset
  Future<void> resetAll() => _storage.resetAllProgress();
}
